FROM ubuntu:24.04

ARG UID=1000 
ARG GID=1000

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential curl git unzip ca-certificates pkg-config \
  libssl-dev zlib1g-dev \
  ruby-full \
  ripgrep fd-find openssh-client \
  libgit2-dev \
  && rm -rf /var/lib/ap/lists/*

WORKDIR /workspace

RUN mkdir -p /home/dev

# Bundler config: install gems into a persisted volume
ENV BUNDLE_PATH=/home/dev/.bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN gem install bundler
