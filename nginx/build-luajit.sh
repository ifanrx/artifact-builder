#!/usr/bin/env bash
set -euo pipefail

make amalg PREFIX=/opt/luajit2 TARGET_STRIP=true
make install PREFIX=/opt/luajit2 TARGET_STRIP=echo
