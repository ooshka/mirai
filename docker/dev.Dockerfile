FROM ruby:3.4.7-bookworm

ARG UID=1000 
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential curl git unzip ca-certificates pkg-config \
  libssl-dev zlib1g-dev \
  ripgrep fd-find openssh-client \
  libgit2-dev \
  && rm -rf /var/lib/ap/lists/*

RUN groupadd -g ${GID} dev \
  && useradd -m -u ${UID} -g ${GID} -s /bin/bash dev

WORKDIR /workspace

# Bundler config: install gems into a persisted volume
ENV BUNDLE_PATH=/home/dev/.bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    HOME=/home/dev

# Ensure the bundle directory exists and is writable
RUN mkdir -p /home/dev/.bundle && chown -R dev:dev /home/dev

RUN gem update --system && gem install bundler

USER dev
