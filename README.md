# Postbot Deployment

Deploys **postbot** (Mattermost broadcast bot) and **webui** (Django admin) as rootless Podman containers managed by systemd via Quadlet.

## Prerequisites

- Podman installed on the server
- The container images published to Docker Hub (`./publish.sh` from the main repo)

## Deploy

### 1. Clone to the correct location

The quadlet files expect the repo to live at `~/postbot/`:

```bash
git clone <repo-url> ~/postbot
cd ~/postbot
```

### 2. Configure

```bash
cp .env.example .env
nano .env   # fill in all [ChangeME] values
```

### 3. Run init

```bash
chmod +x init.sh quadlet/copy_quadlets.sh
./init.sh
```

This copies the quadlet files, starts both services, and enables linger so they survive logout.

### 4. Verify

```bash
systemctl --user status postbot
systemctl --user status webui
journalctl --user -u postbot -f
```

---

## Update

Pull the latest images and restart:

```bash
./update.sh
```

---

## Directory structure

```
~/postbot/
├── .env                      # secrets — never commit this
├── data/
│   ├── postbot/              → mounted into postbot at /app/data
│   │   ├── channels.toml     # auto-created by postbot on first start
│   │   ├── broadcast_log.db
│   │   ├── tasks/            # custom task plugins (.py files)
│   │   └── logs/
│   ├── webui/                → mounted into webui at /app/data
│   └── certs/                → mounted into webui at /app/certs (read-only)
│       └── ca.pem            # LDAP CA certificate — required
└── quadlet/                  # systemd Quadlet unit files
```

---

## Common commands

```bash
systemctl --user restart postbot     # restart postbot
systemctl --user restart webui       # restart webui
systemctl --user stop webui          # stop a service
podman logs postbot                  # raw container logs
```

---

## Troubleshooting

**Quadlet units not appearing after `daemon-reload`**
```bash
/usr/lib/systemd/system-generators/podman-system-generator --user --dryrun 2>&1
```

**webui can't reach postbot**
```bash
podman network inspect internal | grep -A5 containers
```

**Port 8080 not reachable**
```bash
sudo firewall-cmd --add-port=8080/tcp --permanent && sudo firewall-cmd --reload
# or on Debian/Ubuntu:
sudo ufw allow 8080/tcp
```

**`podman pull` fails with auth error**
```bash
podman login docker.io
```