#!/usr/bin/env bash
set -e

[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

podman compose pull
podman compose down
podman compose up -d
podman compose ps