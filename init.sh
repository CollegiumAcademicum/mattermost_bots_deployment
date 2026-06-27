#!/usr/bin/env bash
set -e

# Copy quadlet files to the systemd user directory
./quadlet/copy_quadlets.sh

# Reload systemd and verify units were generated
systemctl --user daemon-reload
systemctl --user list-unit-files | grep -E 'postbot|webui|internal'

# Start services
systemctl --user start postbot
systemctl --user start webui

# Enable lingering so services survive logout
loginctl enable-linger

# Verify
systemctl --user status postbot
systemctl --user status webui