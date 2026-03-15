#!/usr/bin/env bash
set -euo pipefail

make amalg PREFIX=/opt/luajit2 TARGET_STRIP=
make install PREFIX=/opt/luajit2 TARGET_STRIP=echo
