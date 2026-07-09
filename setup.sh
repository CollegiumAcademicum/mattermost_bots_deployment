#!/usr/bin/env bash
# Bootstrap script — run once on a fresh server to set up the full deployment.
# Can be executed before the repo exists:
#   curl -fsSL https://raw.githubusercontent.com/CollegiumAcademicum/mattermost_bots_deployment/main/setup.sh | bash
set -euo pipefail

REPO_URL="https://github.com/CollegiumAcademicum/mattermost_bots_deployment.git"
SRV_DIR="/srv/containers/www/home/postbot"
INSTALL_DIR="$SRV_DIR"
LINK_DIR="$HOME/postbot"
SERVICE_NAME="postbot"
SYSTEMD_DIR="$HOME/.config/systemd/user"

# ── helpers ────────────────────────────────────────────────────────────────
info()  { echo "[setup] $*"; }
warn()  { echo "[setup] WARNING: $*" >&2; }
die()   { echo "[setup] ERROR: $*" >&2; exit 1; }

# ── 1. prerequisites ────────────────────────────────────────────────────────
info "Checking prerequisites..."
command -v podman         >/dev/null 2>&1 || die "podman is not installed."
command -v podman-compose >/dev/null 2>&1 \
  || command -v podman compose >/dev/null 2>&1 \
  || die "podman-compose is not installed. Install it (e.g. pip install podman-compose or dnf install podman-compose)."
command -v git            >/dev/null 2>&1 || die "git is not installed."
command -v systemctl      >/dev/null 2>&1 || warn "systemctl not found — skipping service setup."

# ── 2. clone or update repo ─────────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
    info "Repo already exists at $INSTALL_DIR — pulling latest..."
    git -C "$INSTALL_DIR" pull
else
    info "Cloning repo to $INSTALL_DIR..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Create $HOME/postbot symlink following the /srv convention used by other services
if [ -L "$LINK_DIR" ]; then
    info "Symlink $LINK_DIR already exists — skipping."
elif [ -d "$LINK_DIR" ]; then
    warn "$LINK_DIR is a real directory (legacy install). Move its contents to $INSTALL_DIR if needed, then remove it and re-run this script."
else
    ln -s "$INSTALL_DIR" "$LINK_DIR"
    info "Created symlink: $LINK_DIR -> $INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# ── 3. .env ──────────────────────────────────────────────────────────────────
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        info "Created .env from .env.example — fill in all CHANGE_ME values before starting."
    else
        warn ".env.example not found. You must create .env manually before running start.sh."
    fi
else
    info ".env already exists — skipping."
fi

# ── 4. data directories ───────────────────────────────────────────────────────
info "Ensuring data directories exist..."
mkdir -p data/postbot/logs data/postbot/tasks data/webui data/certs

# ── 5. systemd user service ──────────────────────────────────────────────────
if command -v systemctl >/dev/null 2>&1; then
    info "Installing systemd user service..."
    mkdir -p "$SYSTEMD_DIR"
    cp "$INSTALL_DIR/$SERVICE_NAME.service" "$SYSTEMD_DIR/$SERVICE_NAME.service"

    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME.service"
    info "Service enabled (will start at login / after linger is set)."

    # Enable linger so the user service survives logout and starts at boot
    if command -v loginctl >/dev/null 2>&1; then
        loginctl enable-linger "$USER"
        info "Linger enabled for $USER — service will start at boot without login."
    else
        warn "loginctl not found. Run 'loginctl enable-linger $USER' manually to enable boot start."
    fi
else
    warn "Skipped systemd setup — run manually if needed."
fi

# ── done ─────────────────────────────────────────────────────────────────────
echo ""
echo "Setup complete. Next steps:"
echo ""
echo "  1. Edit .env and fill in all CHANGE_ME values:"
echo "       nano $INSTALL_DIR/.env"
echo ""
if [ -d data/certs ] && [ -z "$(ls -A data/certs 2>/dev/null)" ]; then
echo "  2. (Optional) Place your LDAP CA certificate:"
echo "       cp /path/to/ca.pem $INSTALL_DIR/data/certs/ca.pem"
echo ""
echo "  3. Pull images and start:"
else
echo "  2. Pull images and start:"
fi
echo "       cd $INSTALL_DIR && ./start.sh"
echo ""
echo "  After that, the service auto-starts at every boot."
