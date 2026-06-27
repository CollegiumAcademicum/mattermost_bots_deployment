podman pull philippbtz/mattermost-postbot:latest
systemctl --user restart postbot

podman pull philippbtz/mattermost-webui:latest
systemctl --user restart webui