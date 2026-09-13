# mk-hexdump

A clone of `hexdump -C`, written in ARMv7 assembly.

```console
$ make run samples/lorem.txt
00000000  4c 6f 72 65 6d 20 69 70  73 75 6d 20 64 6f 6c 6f  |Lorem ipsum dolo|
00000010  72 20 73 69 74 20 61 6d  65 74 2c 20 63 6f 6e 73  |r sit amet, cons|
...
00000140  65 6d 20 63 6f 6e 67 75  65 2e                    |em congue.|
0000014a
```

Each line is an 8-digit byte offset, 16 bytes in hex split into two groups of
eight, then the same bytes as printable ASCII between pipes, with anything
outside the printable range shown as `.`. A short final line is padded so the
ASCII column stays aligned, and the total file size is printed on its own
line at the end.

## Design

File I/O goes straight to the kernel through `svc #0` — `open` (syscall 5)
and `read` (syscall 3), with the syscall number in `r7`. Formatting is left
to libc's `printf`, so the program links against glibc and starts at `main`
rather than `_start`.

There is no line buffer: each 16-byte chunk is read into 16 bytes carved out
of the stack (`sub sp, sp, #16`) and printed field by field as it's read, so
memory use is constant regardless of file size.

| File | |
|---|---|
| [`main.S`](main.S) | Argument handling, `open`, and the read loop. |
| [`helpers.S`](helpers.S) | Output subroutines: address prefix, hex columns, ASCII column, error reporting. |
| [`defs.inc`](defs.inc) | Syscall numbers and flags, guarded like a C header so it can be `#include`d by both. |

Sources are `.S` (capital S) so they run through the C preprocessor on the
way to the assembler, which is what makes the shared `#include` work.

### Conventions

Subroutines follow the ARM procedure call standard: arguments and return
values in `r0`–`r3`, `r4`–`r11` preserved across calls by pushing them with
`stmfd sp!, {...}` on entry and popping straight into `pc` on exit. Each
subroutine is documented at its definition with its inputs and return value.

In the read loop, `r4` holds the file descriptor, `r5` the byte count from
the current `read`, and `r6` the running offset — all callee-saved, so they
survive the `printf` calls in between.

## Differences from `hexdump -C`

- Repeated identical lines are not collapsed into `*`.
- The closing offset line is printed through the same `"%08zx  "` template as
  the body lines, so it carries two trailing spaces that `hexdump -C` doesn't.
- Byte `0x7f` (DEL) is printed literally in the ASCII column instead of as `.`.
- A filename argument is required; there's no reading from stdin.
- No options (`-n`, `-s`, `-v`, …).
- Each output line corresponds to one `read` call, so a short read that isn't
  at end of file would produce a short line. Harmless for regular files,
  wrong for pipes.

## Building

From the repo root, inside the container (see the
[main README](../../README.md)):

```sh
make run samples/lorem.txt     # build and run
make debug samples/lorem.txt   # run paused for gdb; then `make gdb` elsewhere
```
