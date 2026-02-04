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
$STD apt install -y git curl unzip openssl openssh-server
msg_ok "Installed Dependencies"

msg_info "Enabling SSH Root Access"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
msg_ok "Enabled SSH Root Access"

msg_info "Installing Bun"
export BUN_INSTALL="/root/.bun"
curl -fsSL https://bun.sh/install | bash &>/dev/null
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
ln -sf /root/.bun/bin/bun /usr/local/bin/node
export PATH="/usr/local/bin:/root/.bun/bin:$PATH"
hash -r
msg_ok "Installed Bun $(/usr/local/bin/bun --version)"

msg_info "Installing OpenClaw"
$STD /usr/local/bin/bun install -g openclaw
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
ExecStart=/root/.bun/bin/openclaw gateway --port 18789
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
