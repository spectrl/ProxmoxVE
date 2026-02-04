#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pfassina
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw
# Modified: Adapted to use Bun instead of Node.js, added security hardening

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git curl unzip openssl
msg_ok "Installed Dependencies"

msg_info "Installing Bun"
$STD curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
ln -sf "$BUN_INSTALL/bin/bun" /usr/local/bin/bun
ln -sf "$BUN_INSTALL/bin/bunx" /usr/local/bin/bunx
msg_ok "Installed Bun $(bun --version)"

msg_info "Installing OpenClaw"
$STD bun install -g openclaw
msg_ok "Installed OpenClaw"

msg_info "Setup OpenClaw"
mkdir -p /root/.openclaw
GATEWAY_TOKEN=$(openssl rand -hex 32)
cat <<CONF >/root/.openclaw/openclaw.json
{
  "gateway": {
    "bind": "loopback",
    "port": 18789,
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  },
  "discovery": {
    "mdns": { "mode": "off" }
  },
  "channels": {
    "whatsapp": {
      "dmPolicy": "pairing",
      "groups": { "*": { "requireMention": true } }
    },
    "telegram": {
      "dmPolicy": "pairing",
      "groups": { "*": { "requireMention": true } }
    },
    "discord": {
      "dm": { "policy": "pairing" },
      "guilds": { "*": { "requireMention": true } }
    },
    "slack": {
      "dm": { "policy": "pairing" },
      "channels": { "*": { "requireMention": true } }
    }
  }
}
CONF
chmod 700 /root/.openclaw
chmod 600 /root/.openclaw/openclaw.json
msg_ok "Setup OpenClaw"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/bun run openclaw gateway --port 18789
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=BUN_INSTALL=/root/.bun
Environment=PATH=/usr/local/bin:/root/.bun/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q openclaw
msg_ok "Created Service"

msg_info "Running Security Audit"
$STD openclaw security audit --fix || true
msg_ok "Security Audit Complete"

echo "${GATEWAY_TOKEN}" > /root/.openclaw/.gateway-token
chmod 600 /root/.openclaw/.gateway-token

motd_ssh
customize
cleanup_lxc
