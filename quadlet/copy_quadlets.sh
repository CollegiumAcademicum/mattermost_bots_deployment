#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p ~/.config/containers/systemd
cp "$SCRIPT_DIR"/*.container ~/.config/containers/systemd/
cp "$SCRIPT_DIR"/*.network ~/.config/containers/systemd/