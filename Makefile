AS       := arm-linux-gnueabihf-as
LD       := arm-linux-gnueabihf-ld
DOCKER_IMG := debian:bookworm-slim
BUILD    := build

# Usage: make run FILE=examples/hello.s
FILE ?= examples/hello.s
NAME := $(notdir $(basename $(FILE)))

.PHONY: run build clean

build:
	@mkdir -p $(BUILD)
	$(AS) -o $(BUILD)/$(NAME).o $(FILE)
	$(LD) -o $(BUILD)/$(NAME) $(BUILD)/$(NAME).o

run: build
	docker run --rm --platform linux/arm/v7 -v "$(CURDIR)/$(BUILD)":/work -w /work $(DOCKER_IMG) ./$(NAME)

clean:
	rm -rf $(BUILD)
