#!/usr/bin/env bash
set -e

# Pull latest images and restart (stops existing containers first)
podman compose pull
podman compose down
podman compose up -d

# Verify
podman compose ps