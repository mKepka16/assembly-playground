FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
      man-db \
      manpages \
      manpages-dev \
      less \
      binutils-arm-linux-gnueabihf \
      gcc-arm-linux-gnueabihf \
      libc6-dev-armhf-cross \
      qemu-user-static \
      gdb-multiarch \
      tmux \
      tree \
      moreutils \
      make \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
