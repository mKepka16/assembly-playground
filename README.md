# ARM Assembly Playground

Learning 32-bit ARM (ARMv7, `arm-linux-gnueabihf`) by writing it — from a
macOS host, via a cross-toolchain and QEMU user-mode emulation in Docker.

The centrepiece is **[`mk-hexdump`](projects/mk-hexdump/)**: a
`hexdump -C` clone written in ARM assembly, using raw Linux syscalls for
I/O and `printf` for formatting.

```console
$ make run samples/lorem.txt
00000000  4c 6f 72 65 6d 20 69 70  73 75 6d 20 64 6f 6c 6f  |Lorem ipsum dolo|
00000010  72 20 73 69 74 20 61 6d  65 74 2c 20 63 6f 6e 73  |r sit amet, cons|
00000020  65 63 74 65 74 75 72 20  61 64 69 70 69 73 63 69  |ectetur adipisci|
...
00000140  65 6d 20 63 6f 6e 67 75  65 2e                    |em congue.|
0000014a
```

Same layout and same bytes as `hexdump -C samples/lorem.txt`; see
[known differences](projects/mk-hexdump/README.md#differences-from-hexdump--c).

## Quickstart

Requires [Docker Desktop](https://www.docker.com/products/docker-desktop/).

```sh
docker build -t asm-dev .                          # once
docker run -it --rm -v "$PWD":/work -w /work asm-dev bash
```

Then, inside the container:

```sh
make run samples/lorem.txt     # build + run mk-hexdump
make debug samples/lorem.txt   # run paused under the QEMU gdbstub
make gdb                       # attach gdb-multiarch to it (second shell)
make clean
```

`make` builds whichever directory under `projects/` you point it at:
`make PROJECT=<name> run`.

## What's here

| Path | |
|---|---|
| [`projects/mk-hexdump/`](projects/mk-hexdump/) | The `hexdump -C` clone — main program, helper subroutines, shared constants. [Its README](projects/mk-hexdump/README.md) covers the design. |
| [`exercises/`](exercises/) | End-of-chapter exercises from the book below (chapters 2–5): assembly solutions plus written answers to the theory questions. |
| [`docs/toolchain.md`](docs/toolchain.md) | Why the Docker/QEMU setup looks like this, building by hand without `make`, and how to debug emulated ARM code with gdb. |
| [`scripts/asmfmt.py`](scripts/asmfmt.py) | Small formatter that column-aligns assembly source; wired into VS Code as a format-on-save hook. |
| [`Dockerfile`](Dockerfile) | The cross-toolchain + QEMU + gdb environment. |

## How it runs at all

A Linux/ARM32 binary can't execute on macOS, and Apple Silicon has no
hardware AArch32 support — so even ARM-on-ARM needs emulation. Inside the
container:

- **Build** — `arm-linux-gnueabihf-gcc`/`as`/`ld` run natively and merely
  *target* ARM32. No emulation involved.
- **Run** — `qemu-arm-static` executes a single ARM32 ELF, translating
  instructions on the fly.
- **Debug** — QEMU's built-in gdbstub, because `ptrace` doesn't work through
  user-mode emulation. Details in [`docs/toolchain.md`](docs/toolchain.md).

## Reference material

- Larry D. Pyeatt & William Ughetta, *Modern Assembly Language Programming
  with the ARM Processor*, 2nd ed. — the book the `exercises/` follow.
- [ARM Architecture Reference Manual, ARMv7-A/R (DDI 0406C)](https://developer.arm.com/documentation/ddi0406/latest/)
