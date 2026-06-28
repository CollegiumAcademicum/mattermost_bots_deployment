# Postbot Deployment

Deploys **postbot** (Mattermost broadcast bot) and **webui** (Django admin) as rootless Podman containers managed by podman compose.

## Prerequisites

- Podman and podman-compose installed on the server
- The container images published to Docker Hub (`./publish.sh` from the main repo)

## Deploy

### 1. Clone the repo

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
./init.sh
```

This pulls the latest images, starts both services, and shows their status.

### 4. Verify

```bash
podman compose ps
podman compose logs -f postbot
podman compose logs -f webui
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
├── docker-compose.yaml
├── data/
│   ├── postbot/              → mounted into postbot at /app/data
│   │   ├── channels.toml     # channel group configuration
│   │   ├── broadcast_log.db
│   │   ├── tasks/            # custom task plugins (.py files)
│   │   └── logs/
│   ├── webui/                → mounted into webui at /app/data
│   └── certs/                → mounted into webui at /app/certs (read-only)
│       └── ca.pem            # LDAP CA certificate — required if using LDAP over TLS
```

---

## Common commands

```bash
podman compose restart postbot   # restart postbot
podman compose restart webui     # restart webui
podman compose stop webui        # stop a service
podman compose logs postbot      # container logs
podman compose down              # stop everything
```

---

## Troubleshooting

**webui can't reach postbot**

Check both containers are on the internal network:
```bash
podman network inspect postbot_internal
```

**Port 8080 not reachable**
```bash
# Fedora/RHEL
sudo firewall-cmd --add-port=8080/tcp --permanent && sudo firewall-cmd --reload
# Debian/Ubuntu
sudo ufw allow 8080/tcp
```

**`podman compose pull` fails with auth error**
```bash
podman login docker.io
```