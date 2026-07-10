#!/usr/bin/env bash
[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"
podman compose down