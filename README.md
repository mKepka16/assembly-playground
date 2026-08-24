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

Write ARM32 assembly in `examples/` (or anywhere), using raw Linux syscalls
(no libc — see `examples/hello.s`), then:

```sh
make run FILE=examples/hello.s
```

This assembles and links the file with `arm-linux-gnueabihf-as`/`-ld`,
producing a static binary in `build/`, then runs it inside an emulated
ARMv7 container.

Other targets:

```sh
make build FILE=examples/hello.s   # assemble + link only, no run
make clean                          # remove build/ artifacts
```

## Writing your own examples

Since there's no libc linked in, programs talk to the kernel directly via
`svc #0` with the syscall number in `r7` and arguments in `r0`-`r6` (standard
ARM EABI syscall convention — same numbers as Linux ARM32). `examples/hello.s`
shows the pattern using `write` (4) and `exit` (1).

## Manual invocation

If you want to skip `make`:

```sh
arm-linux-gnueabihf-as -o hello.o examples/hello.s
arm-linux-gnueabihf-ld -o hello hello.o
docker run --rm --platform linux/arm/v7 -v "$PWD":/work -w /work debian:bookworm-slim ./hello
```
