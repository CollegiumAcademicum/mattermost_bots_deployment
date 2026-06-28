#!/usr/bin/env bash
set -e

podman compose pull
podman compose up -d