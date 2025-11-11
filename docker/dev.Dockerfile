FROM ubuntu:24.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential curl git unzip ca-certificates pkg-config libssl-dev zlib1g-dev \
  ruby-full \
  python3 python3-pip python3-venv \
  nodejs npm \
  ripgrep fd-find && rm -rf /var/lib/apt/lists/*

ARG UID=1000 GID=1000
RUN groupadd -g ${GID} dev && useradd -m -u ${UID} -g ${GID} dev
USER dev
WORKDIR /workspace

# Python tooling
ENV PIPX_BIN_DIR=/home/dev/.local/bin PATH=/home/dev/.local/bin:$PATH
RUN python3 -m pip install --user pipx && pipx ensurepath && \
    pipx install ruff-lsp && pipx install black && npm install -g pyright

# Ruby tooling
RUN gem install --user-install ruby-lsp standardrb
