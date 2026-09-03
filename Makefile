AS       := arm-linux-gnueabihf-as
LD       := arm-linux-gnueabihf-ld
DOCKER_IMG := debian:bookworm-slim
DOCKER_IMG_TOOLS := assembly-playground-tools
DOCKER_IMG_DEBUG := assembly-playground-debug
DEBUG_CONTAINER := asm-debug
GDB_PORT := 1234
BUILD    := build

# Usage: make run FILE=book_excercises/chapter2/2.13.s
FILE ?= book_excercises/chapter2/2.13.s
NAME := $(notdir $(basename $(FILE)))

.PHONY: run run-libc debug debug-libc build tools-image debug-image clean \
        debug-container-up debug-container-down build-debug build-debug-libc tail-output

build:
	@mkdir -p $(BUILD)
	$(AS) -o $(BUILD)/$(NAME).o $(FILE)
	$(LD) -o $(BUILD)/$(NAME) $(BUILD)/$(NAME).o

run: build
	docker run --rm --platform linux/arm/v7 -v "$(CURDIR)/$(BUILD)":/work -w /work $(DOCKER_IMG) ./$(NAME)

# Image with gcc/libc6-dev, for examples that need real libc (e.g. printf).
tools-image:
	@docker image inspect $(DOCKER_IMG_TOOLS) >/dev/null 2>&1 || \
		docker build --platform linux/arm/v7 -t $(DOCKER_IMG_TOOLS) -f Dockerfile.tools .

# For examples that call into libc (e.g. printf) instead of raw syscalls.
# Assembles, links, and runs natively inside an emulated ARMv7 container
# using gcc, since the macOS cross-binutils (as/ld) can't resolve libc
# symbols or produce a proper dynamically-linked entry point.
run-libc: tools-image
	@mkdir -p $(BUILD)
	docker run --rm --platform linux/arm/v7 -v "$(CURDIR)":/work -w /work $(DOCKER_IMG_TOOLS) \
		sh -c "gcc -o $(BUILD)/$(NAME) $(FILE) && ./$(BUILD)/$(NAME)"

# --- Debugging -------------------------------------------------------------
# gdb can't ptrace a process inside these containers: they run under QEMU
# user-mode emulation (Docker Desktop's linux/arm/v7 containers on macOS,
# including Apple Silicon, which has no hardware AArch32 support), and QEMU
# linux-user doesn't implement ptrace across that boundary. Instead we run
# the built binary directly under `qemu-arm-static -g <port>`, which has its
# own built-in gdbstub (it controls the emulated CPU directly, no ptrace
# needed), and connect to it with `gdb-multiarch` running natively (no
# emulation) on the host architecture. This needs its own image built for
# the *native* platform (no --platform), unlike every image above.
#
# Debug builds are always statically linked so qemu-arm-static never needs
# to resolve armhf shared libraries (this debug image has none installed).

debug-image:
	@docker image inspect $(DOCKER_IMG_DEBUG) >/dev/null 2>&1 || \
		docker build -t $(DOCKER_IMG_DEBUG) -f Dockerfile.debug .

# Step through a raw-syscall example instruction by instruction in gdb's
# TUI (registers/memory/disassembly), built with debug info via as -g.
debug: debug-image
	@mkdir -p $(BUILD)
	$(AS) -g -o $(BUILD)/$(NAME).o $(FILE)
	$(LD) -o $(BUILD)/$(NAME) $(BUILD)/$(NAME).o
	docker run --rm -it -v "$(CURDIR)":/work -w /work $(DOCKER_IMG_DEBUG) sh -c "\
		qemu-arm-static -g $(GDB_PORT) $(BUILD)/$(NAME) & \
		sleep 1; \
		gdb-multiarch -q -tui \
			-ex 'file $(BUILD)/$(NAME)' \
			-ex 'set architecture arm' \
			-ex 'target remote localhost:$(GDB_PORT)'"

# Same, but for libc-based examples: statically compiled with gcc -g inside
# the armhf tools container (needed to resolve libc + produce a proper
# entry point), then debugged the same way as above. Break on `main` first
# (e.g. type `break main` then `continue`) to skip past glibc's startup
# code, which has no debug info and confuses plain step/next there.
debug-libc: tools-image debug-image
	@mkdir -p $(BUILD)
	docker run --rm --platform linux/arm/v7 -v "$(CURDIR)":/work -w /work $(DOCKER_IMG_TOOLS) \
		gcc -g -static -o $(BUILD)/$(NAME) $(FILE)
	docker run --rm -it -v "$(CURDIR)":/work -w /work $(DOCKER_IMG_DEBUG) sh -c "\
		qemu-arm-static -g $(GDB_PORT) $(BUILD)/$(NAME) & \
		sleep 1; \
		gdb-multiarch -q -tui \
			-ex 'file $(BUILD)/$(NAME)' \
			-ex 'set architecture arm' \
			-ex 'target remote localhost:$(GDB_PORT)'"

# --- VS Code debugging support ----------------------------------------------
# VS Code's C/C++ extension pipes gdb commands into a *running* container
# via `docker exec` (pipeTransport in launch.json), so unlike `debug`/
# `debug-libc` above this needs a long-lived container instead of a
# one-shot `docker run --rm`. build-debug(-libc) below are the preLaunchTask:
# they (re)build the binary and (re)start qemu-arm-static serving it, so
# that by the time VS Code's gdb-multiarch connects to localhost:$(GDB_PORT)
# it's debugging the latest edits.

debug-container-up: debug-image
	@docker ps -q -f name=^/$(DEBUG_CONTAINER)$$ | grep -q . || \
		docker run -d --rm --name $(DEBUG_CONTAINER) \
			-v "$(CURDIR)":/work -w /work $(DOCKER_IMG_DEBUG) sleep infinity

debug-container-down:
	docker rm -f $(DEBUG_CONTAINER) >/dev/null 2>&1 || true

build-debug: debug-container-up
	@mkdir -p $(BUILD)
	$(AS) -g -o $(BUILD)/$(NAME).o $(FILE)
	$(LD) -o $(BUILD)/$(NAME) $(BUILD)/$(NAME).o
	docker exec -e QEMU_PATTERN="qemu-arm-static -g" $(DEBUG_CONTAINER) sh -c '\
		pkill -9 -f "$$QEMU_PATTERN" 2>/dev/null; \
		for i in 1 2 3 4 5 6 7 8 9 10; do pgrep -f "$$QEMU_PATTERN" >/dev/null || break; sleep 0.2; done'
	docker exec -d $(DEBUG_CONTAINER) sh -c "qemu-arm-static -g $(GDB_PORT) $(BUILD)/$(NAME) > $(BUILD)/$(NAME).out 2>&1"
	@sleep 1

build-debug-libc: tools-image debug-container-up
	@mkdir -p $(BUILD)
	docker run --rm --platform linux/arm/v7 -v "$(CURDIR)":/work -w /work $(DOCKER_IMG_TOOLS) \
		gcc -g -static -o $(BUILD)/$(NAME) $(FILE)
	docker exec -e QEMU_PATTERN="qemu-arm-static -g" $(DEBUG_CONTAINER) sh -c '\
		pkill -9 -f "$$QEMU_PATTERN" 2>/dev/null; \
		for i in 1 2 3 4 5 6 7 8 9 10; do pgrep -f "$$QEMU_PATTERN" >/dev/null || break; sleep 0.2; done'
	docker exec -d $(DEBUG_CONTAINER) sh -c "qemu-arm-static -g $(GDB_PORT) $(BUILD)/$(NAME) > $(BUILD)/$(NAME).out 2>&1"
	@sleep 1

# The debuggee's stdout/stderr goes nowhere by default in the VS Code flow
# (qemu-arm-static is started detached via `docker exec -d` above, so it has
# no attached terminal), so build-debug(-libc) redirect it to a per-example
# log file instead. This tails it live; run it in its own terminal alongside
# a VS Code debug session (or bind it to a VS Code task) to see program
# output (e.g. `printf`/syscall `write` output) as the program runs.
tail-output:
	@mkdir -p $(BUILD)
	@touch $(BUILD)/$(NAME).out
	docker exec -i $(DEBUG_CONTAINER) tail -n +1 -f $(BUILD)/$(NAME).out

clean:
	rm -rf $(BUILD)
