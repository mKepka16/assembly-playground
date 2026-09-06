FROM debian:bookworm-slim

# Debian's "slim" docker images exclude man pages/docs via this dpkg config
# to save space; remove it *before* installing anything else below, so the
# packages we do install actually unpack their man pages.
RUN rm -f /etc/dpkg/dpkg.cfg.d/docker

RUN apt-get update && apt-get install -y --no-install-recommends \
      man-db \
      manpages \
      less \
      binutils-arm-linux-gnueabihf \
      gcc-arm-linux-gnueabihf \
      libc6-dev-armhf-cross \
      qemu-user-static \
      gdb-multiarch \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
