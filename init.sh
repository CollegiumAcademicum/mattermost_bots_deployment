#!/usr/bin/env bash
set -e

# Pull latest images
podman compose pull

# Start services
podman compose up -d

# Verify
podman compose ps