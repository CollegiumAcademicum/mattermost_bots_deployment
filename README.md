# Postbot Deployment

Deploys **postbot** (Mattermost broadcast bot) and **webui** (Django admin) as rootless Podman containers managed by podman compose.

## Prerequisites

- Podman and podman-compose installed on the server
- The container images published to Docker Hub (`./publish.sh` from the main repo)

## Fresh server setup

Run the bootstrap script — it clones the repo, sets up the systemd service, and prepares all directories:

```bash
curl -fsSL https://raw.githubusercontent.com/CollegiumAcademicum/mattermost_bots_deployment/main/setup.sh | bash
```

Then fill in the required values in `~/postbot/.env`:

```bash
nano ~/postbot/.env   # fill in all CHANGE_ME values
```

Optionally place your LDAP CA certificate:

```bash
cp /path/to/ca.pem ~/postbot/data/certs/ca.pem
```

Finally, pull images and start:

```bash
cd ~/postbot && ./start.sh
```

After this the stack starts automatically at every boot.

---

## Manual setup (alternative)

### 1. Clone the repo

```bash
git clone https://github.com/CollegiumAcademicum/mattermost_bots_deployment.git ~/postbot
cd ~/postbot
```

### 2. Configure

```bash
cp .env.example .env
nano .env   # fill in all CHANGE_ME values
```

### 3. Install the systemd service

```bash
mkdir -p ~/.config/systemd/user
cp postbot.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable postbot.service
loginctl enable-linger $USER   # start at boot without login
```

### 4. Start

```bash
./start.sh
```

---

## Update

Pull the latest images and restart:

```bash
./start.sh
```

---

## Directory structure

```
~/postbot/
├── .env                      # secrets — never commit this
├── docker-compose.yaml
├── postbot.service           # systemd unit (installed by setup.sh)
├── setup.sh                  # bootstrap script for fresh servers
├── start.sh                  # pull latest images and restart
├── stop.sh                   # stop all containers
└── data/
    ├── postbot/              → mounted into postbot at /app/data
    │   ├── channels.toml     # channel group configuration
    │   ├── broadcast_log.db
    │   ├── tasks/            # custom task plugins (.py files)
    │   └── logs/
    ├── webui/                → mounted into webui at /app/data
    └── certs/                → mounted into webui at /app/certs (read-only)
        └── ca.pem            # LDAP CA certificate — required if using LDAP over TLS
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

**Service not starting at boot**

Make sure linger is enabled — without it the user service only starts on login:
```bash
loginctl enable-linger $USER
loginctl show-user $USER | grep Linger   # should show Linger=yes
```
