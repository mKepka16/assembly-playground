PROJECT ?= mk-hexdump
SRCDIR  := projects/$(PROJECT)
BUILDIR := build/$(PROJECT)
TARGET  := $(BUILDIR)/target

CC      := arm-linux-gnueabihf-gcc
CFLAGS  := -g -static -MMD -MP
RUNNER  := qemu-arm-static

SRCS    := $(wildcard $(SRCDIR)/*.S)
OBJS    := $(patsubst $(SRCDIR)/%.S,$(BUILDIR)/%.o,$(SRCS))
DEPS    := $(OBJS:.o=.d)

ifneq (,$(filter $(firstword $(MAKECMDGOALS)),run debug))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  .PHONY: $(RUN_ARGS)
  $(eval $(RUN_ARGS):;@:)
endif


.PHONY: compile run clean debug

compile: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

$(BUILDIR)/%.o: $(SRCDIR)/%.S
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c -o $@ $<

run: compile
	@$(RUNNER) $(TARGET) $(RUN_ARGS)

debug: compile
	@$(RUNNER) -g 1234 $(TARGET) $(RUN_ARGS)

gdb:
	gdb-multiarch -q \
	-ex 'file $(TARGET)' \
	-ex 'set architecture arm' \
	-ex 'break main' \
	-ex 'target remote localhost:1234' \
	-ex 'continue' \
	-ex 'layout regs' \
	-ex 'ni'

clean:
	rm -rf build

-include $(DEPS)
