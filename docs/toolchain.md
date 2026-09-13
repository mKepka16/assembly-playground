# Toolchain notes

Background for the setup in the [README](../README.md): why it's built this
way, how to build things by hand without `make`, and how to debug ARM code
running under emulation.

## The environment

There's no way to build or run a Linux/ARM32 binary directly on macOS, and
Apple Silicon chips have no hardware AArch32 support at all — even ARM-on-ARM
needs emulation. So everything happens inside one Docker container, built
from the [`Dockerfile`](../Dockerfile):

- **Building**: the image has the `arm-linux-gnueabihf-*` cross-toolchain
  (`as`, `ld`, `gcc`) — these run natively on the container's own
  architecture and just *target* ARM32, no emulation needed to build.
- **Running**: the image also has `qemu-user-static`, which provides
  `qemu-arm-static` — a user-mode emulator that runs a single ARM32 ELF
  binary directly (translating its instructions on the fly).
- **Debugging**: plain `gdb` can't work here — see [Debugging](#debugging)
  below for why, and how `qemu-arm-static`'s own debug support gets around it.

Start a container with the repo mounted:

```sh
docker build -t asm-dev .
docker run -it --rm -v "$PWD":/work -w /work asm-dev bash
```

Everything below runs *inside* that shell. `exit` (or Ctrl-D) leaves the
container; `--rm` means it's thrown away on exit, so re-run the `docker run`
line whenever you want a fresh shell — your files are safe, they live in the
repo directory on the host and are just bind-mounted in.

## Building and running by hand

The [`Makefile`](../Makefile) covers everything under `projects/`, but the
exercises are single files, usually built directly.

For a raw-syscall example (`.globl _start`, no libc):

```sh
mkdir -p build
arm-linux-gnueabihf-as -o build/example.o exercises/chapter2/example.s
arm-linux-gnueabihf-ld -o build/example build/example.o
qemu-arm-static ./build/example
```

For an example that calls into libc (e.g. `bl printf`, `.globl main`):

```sh
arm-linux-gnueabihf-gcc -static -o build/2.13 exercises/chapter2/2.13.s
qemu-arm-static ./build/2.13
```

Static linking (`-static`) matters for libc-based examples: it bundles libc
into the binary itself, so there's no separate armhf sysroot to resolve at
runtime — `qemu-arm-static` can just run the file directly.

Raw-syscall programs talk to the kernel directly via `svc #0`, with the
syscall number in `r7` and arguments in `r0`–`r6` (standard ARM EABI syscall
convention).

Note that `exercises/chapter2/2.9.s` and `2.10.s` are data-layout exercises
(`.data` only, no `.text`/`_start`), so they assemble but aren't runnable
programs.

## Debugging

Plain `gdb` can't work here: `gdb` normally controls a process via `ptrace`,
but the process is actually running *inside* `qemu-arm-static`'s user-mode
emulation, and QEMU's linux-user mode doesn't implement `ptrace` on the
emulated process — you'd hit `ptrace: Function not implemented`.

The fix: `qemu-arm-static` has its own built-in gdbstub. Instead of running
`gdb` and having it `ptrace` the process, you start the binary paused under
`qemu-arm-static -g <port>`, which controls the emulated CPU directly (no
ptrace involved) and speaks the gdb remote protocol over that port. A normal
`gdb-multiarch` then connects to it like a remote target.

For `projects/`, `make debug <args>` and `make gdb` (in a second shell) do
exactly this. By hand, build with debug info (`-g`) first:

```sh
arm-linux-gnueabihf-as -g -o build/example.o exercises/chapter2/example.s
arm-linux-gnueabihf-ld -o build/example build/example.o
```

Start it paused, listening for a debugger, in the background of the same
shell (so its stdout stays visible right here once it runs):

```sh
qemu-arm-static -g 1234 build/example &
```

Connect gdb to it:

```sh
gdb-multiarch -q \
  -ex 'file build/example' \
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

See also this [GDB cheat sheet](https://github.com/reveng007/GDB-Cheat-Sheet).

### Getting past glibc startup

For a **libc-based program** (anything with `main` rather than `_start`),
`target remote` lands you at the raw ELF entry point, which runs through
glibc's own startup code before reaching your `main`. That startup code has
no debug info, so plain `next`/`step` there just runs to program exit instead
of reaching your code. Skip past it with a breakpoint instead — which is what
the `gdb` target in the Makefile does:

```sh
gdb-multiarch -q \
  -ex 'file build/mk-hexdump/target' \
  -ex 'set architecture arm' \
  -ex 'break main' \
  -ex 'target remote localhost:1234' \
  -ex 'continue' \
  -ex 'layout regs' \
  -ex 'ni'
```

This stops you right at the first line of `main` — from there `next`/`step`
work normally, and `bl printf`'s output prints directly in this same terminal
once you step past it.
