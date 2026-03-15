#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_command sudo

export DEBIAN_FRONTEND=noninteractive

log "Installing build dependencies"
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  ca-certificates \
  cmake \
  curl \
  git \
  libbrotli-dev \
  libpcre3-dev \
  libssl-dev \
  perl \
  pkg-config \
  xz-utils \
  zlib1g-dev
