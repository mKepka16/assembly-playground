# Assembly Playground

A playground for writing and running 32-bit ARM (ARMv7, `arm-linux-gnueabihf`)
assembly on macOS.

## How it works

There's no way to run a Linux/ARM32 binary directly on macOS, and Homebrew's
`qemu` build only ships full-system emulators (`qemu-system-arm`), not the
`qemu-arm` user-mode binary you'd want for running a single ELF file. So this
setup splits the work in two:

1. **Assemble & link natively on macOS** using a cross-binutils toolchain
   (`arm-linux-gnueabihf-as` / `-ld`) — fast, no emulation needed for this
   step.
2. **Run the resulting binary under emulation** via Docker Desktop, which
   transparently uses QEMU (through `binfmt_misc` in its Linux VM) to execute
   `linux/arm/v7` containers on your Mac.

## Prerequisites

- [Homebrew](https://brew.sh)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (must be
  running)

Install the cross-assembler/linker:

```sh
brew install arm-linux-gnueabihf-binutils
```

No other setup is required — the first `make run` will pull the small Debian
image used to execute the binary (cached after that).

## Usage

Write ARM32 assembly anywhere in the repo (see `book_excercises/`), using raw
Linux syscalls (no libc), then:

```sh
make run FILE=book_excercises/chapter2/some_example.s
```

This assembles and links the file with `arm-linux-gnueabihf-as`/`-ld`,
producing a static binary in `build/`, then runs it inside an emulated
ARMv7 container.

Other targets:

```sh
make build FILE=book_excercises/chapter2/some_example.s   # assemble + link only, no run
make clean                                                  # remove build/ artifacts
```

### Examples that use libc (e.g. `printf`)

Some exercises call into libc instead of raw syscalls (e.g. `bl printf`,
`.globl main` instead of `.globl _start`). The macOS cross-binutils
(`as`/`ld`) can't resolve libc symbols or build a proper dynamically-linked
entry point, so these need a different target:

```sh
make run-libc FILE=book_excercises/chapter2/2.13.s
```

This assembles, links, and runs the file entirely inside the emulated
ARMv7 container using its native `gcc` (built once into a local
`assembly-playground-tools` image, cached after that — see
`Dockerfile.tools`).

## Writing your own examples

Since there's no libc linked in by default, programs talk to the kernel
directly via `svc #0` with the syscall number in `r7` and arguments in
`r0`-`r6` (standard ARM EABI syscall convention — same numbers as Linux
ARM32).

## Debugging (step-by-step, registers, memory)

You can step through a program instruction-by-instruction and watch
registers/memory, either from the terminal or from VS Code.

This can't work by just running `gdb` inside the same containers `run`/
`run-libc` use: those are `linux/arm/v7` containers running under QEMU
user-mode emulation (needed on any Mac, including Apple Silicon — Apple's
own chips have no hardware AArch32 support at all), and QEMU's user-mode
emulation doesn't implement `ptrace` across that boundary, which is what
gdb normally needs to control a process (you'll see `ptrace: Function not
implemented`). Instead, debugging runs the binary directly under
`qemu-arm-static -g <port>`, which has its own built-in gdbstub — it
controls the emulated CPU state directly, no ptrace involved — and connects
to it with `gdb-multiarch` running *natively* (no emulation) via a second
image, `assembly-playground-debug` (see `Dockerfile.debug`), built for your
Mac's own architecture. Debug builds are always statically linked so that
native image (which has no armhf libraries installed) never has to resolve
shared libraries.

### Terminal (gdb TUI)

```sh
make debug      FILE=book_excercises/chapter2/some_example.s  # raw syscall example
make debug-libc FILE=book_excercises/chapter2/2.13.s           # libc example (e.g. printf)
```

Both build with debug info (`-g`, statically linked) and drop you into
`gdb-multiarch -tui`, already connected to the running binary and stopped
at `_start`. Useful commands once in gdb:

- For a libc-based example, run `break main` then `continue` first — the
  entry point stops inside glibc's own startup code, which has no debug
  info, so plain `next`/`step` there just runs to program exit instead of
  reaching your code.
- `si` / `ni` — step one instruction (into / over calls)
- `layout regs` — split view with registers alongside disassembly
- `x/8xw $sp` — examine memory (8 hex words at the stack pointer)
- `info registers` — dump all registers

### VS Code

Requires the
[C/C++ extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)
(`ms-vscode.cpptools`). VS Code's debugger drives `gdb-multiarch` by piping
commands into a long-lived container (`docker exec`) that also runs
`qemu-arm-static` as the actual debug target, since VS Code needs a running
container to attach to rather than the one-shot ones `run`/`debug` use.

1. Open the `.s` file you want to debug.
2. Run and Debug panel → pick **Debug ARM asm (syscall)** or
   **Debug ARM asm (libc)** (whichever matches the file) → press F5.

This automatically starts the debug container if it isn't already running,
rebuilds the current file with `-g` (statically linked), restarts
`qemu-arm-static` inside the container serving the new binary, then
connects. For libc examples a breakpoint on `main` is set automatically
(same reason as above — it lands you past glibc's startup code). You get
normal VS Code breakpoints, step controls, the Variables/Watch panels, a
Registers view, and Debug Memory — set breakpoints by clicking the gutter
next to a line.

When you're done:

```sh
make debug-container-down
```

## Manual invocation

If you want to skip `make`:

```sh
arm-linux-gnueabihf-as -o hello.o book_excercises/chapter2/some_example.s
arm-linux-gnueabihf-ld -o hello hello.o
docker run --rm --platform linux/arm/v7 -v "$PWD":/work -w /work debian:bookworm-slim ./hello
```
