# Assembly Playground

A playground for writing and running 32-bit ARM (ARMv7, `arm-linux-gnueabihf`)
assembly on macOS.

## How it works

There's no way to build or run a Linux/ARM32 binary directly on macOS, and
Apple Silicon chips have no hardware AArch32 support at all — even ARM-on-ARM
needs emulation. So everything happens inside one Docker container, built
from the `Dockerfile` in this repo:

- **Building**: the image has the `arm-linux-gnueabihf-*` cross-toolchain
  (`as`, `ld`, `gcc`) — these run natively on the container's own
  architecture and just _target_ ARM32, no emulation needed to build.
- **Running**: the image also has `qemu-user-static`, which provides
  `qemu-arm-static` — a user-mode emulator that runs a single ARM32 ELF
  binary directly (translating its instructions on the fly).
- **Debugging**: plain `gdb` can't work here — see the Debugging section
  below for why, and how `qemu-arm-static`'s own debug support gets around
  it.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (must be
  running)

## Setup

Build the image once (cached after that):

```sh
docker build -t asm-dev .
```

Start a container with this repo mounted, and get a shell in it:

```sh
docker run -it --rm -v "$PWD":/work -w /work asm-dev bash
```

Everything below runs _inside_ that shell, unless noted otherwise. `exit`
(or Ctrl-D) leaves the container; `--rm` means it's thrown away on exit, so
re-run the `docker run` line whenever you want a fresh shell (your files are
safe — they live in this repo directory on your Mac, just bind-mounted in).

## Building and running

For a raw-syscall example (`.globl _start`, no libc):

```sh
mkdir -p build
arm-linux-gnueabihf-as -o build/your_example.o book_excercises/chapter2/your_example.s
arm-linux-gnueabihf-ld -o build/your_example build/your_example.o
qemu-arm-static ./build/your_example
```

(Note: `2.9.s`/`2.10.s` in this repo are data-layout exercises — `.data`
only, no `.text`/`_start` — so they're not runnable programs. `2.13.s` below
is the one complete, runnable example currently here.)

For an example that calls into libc (e.g. `bl printf`, `.globl main`):

```sh
mkdir -p build
arm-linux-gnueabihf-gcc -static -o build/2.13 book_excercises/chapter2/2.13.s
qemu-arm-static ./build/2.13
```

Static linking (`-static`) matters for libc-based examples: it bundles libc
into the binary itself, so there's no separate armhf sysroot to resolve at
runtime — `qemu-arm-static` can just run the file directly.

## Writing your own examples

Raw-syscall programs talk to the kernel directly via `svc #0`, with the
syscall number in `r7` and arguments in `r0`-`r6` (standard ARM EABI syscall
convention — same numbers as Linux ARM32).

## Debugging (step-by-step, registers, memory)

[GDB Cheat Sheet](https://github.com/reveng007/GDB-Cheat-Sheet)

Plain `gdb` can't work here: `gdb` normally controls a process via `ptrace`,
but the process is actually running _inside_ `qemu-arm-static`'s user-mode
emulation, and QEMU's linux-user mode doesn't implement `ptrace` on the
emulated process — you'd hit `ptrace: Function not implemented`.

The fix: `qemu-arm-static` has its own built-in gdbstub. Instead of running
`gdb` and having it `ptrace` the process, you start the binary paused under
`qemu-arm-static -g <port>`, which controls the emulated CPU directly (no
ptrace involved) and speaks the gdb remote protocol over that port. Then a
normal `gdb-multiarch` connects to it like a remote target.

Build with debug info first (`-g`), same as above:

```sh
arm-linux-gnueabihf-as -g -o build/your_example.o book_excercises/chapter2/your_example.s
arm-linux-gnueabihf-ld -o build/your_example build/your_example.o
# or for a libc example: arm-linux-gnueabihf-gcc -g -static -o build/2.13 book_excercises/chapter2/2.13.s
```

Start it paused, listening for a debugger, in the background of the same
shell (so its stdout stays visible right here once it runs):

```sh
qemu-arm-static -g 1234 build/your_example &
```

Connect gdb to it:

```sh
gdb-multiarch -q \
  -ex 'file build/your_example' \
  -ex 'set architecture arm' \
  -ex 'target remote localhost:1234'
```

You're now stopped at `_start`, in a normal gdb session. Useful commands:

- `si` / `ni` — step one instruction (into / over calls)
- `next` / `step` — step one source line (needs the `-g` debug info)
- `info registers` — dump all registers (or `info registers r0` for one)
- `x/16xb $r0` — examine memory: 16 hex bytes at the address in `r0`
- `x/s $r0` — examine memory as a null-terminated string
- `layout regs` then `si`/`ni` — TUI split view, registers + disassembly,
  live as you step
- `continue` — run to completion (or to the next breakpoint)

For a **libc-based example** (e.g. `2.13.s`), connecting with `target
remote` lands you at the raw ELF entry point (`_start`), which runs through
glibc's own startup code before reaching your `main`. That startup code has
no debug info, so plain `next`/`step` there just runs to program exit
instead of reaching your code. Skip past it with a breakpoint instead:

```sh
gdb-multiarch -q \
  -ex 'file $(TARGET)' \
  -ex 'set architecture arm' \
  -ex 'break main' \
  -ex 'target remote localhost:1234' \
  -ex 'continue' \
  -ex 'layout regs' \
  -ex 'ni'
```

This stops you right at the first line of `main` — from there `next`/`step`
work normally, and `bl printf`'s output prints directly in this same
terminal once you step past (or continue past) it.
