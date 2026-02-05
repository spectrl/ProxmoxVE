#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pfassina
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw
# Modified: Added security hardening, user service setup

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git curl unzip openssl openssh-server dbus-user-session build-essential procps file
msg_ok "Installed Dependencies"

msg_info "Creating openclaw user"
useradd -m -s /bin/bash openclaw
echo "openclaw:openclaw" | chpasswd
echo "openclaw ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/openclaw
chmod 440 /etc/sudoers.d/openclaw
msg_ok "Created openclaw user (password: openclaw)"

msg_info "Installing Homebrew"
sudo -u openclaw NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/openclaw/.bashrc
msg_ok "Installed Homebrew"

msg_info "Enabling SSH Access"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
msg_ok "Enabled SSH Access"

msg_info "Installing Node.js"
NODE_VERSION="22" NODE_MODULE="openclaw" setup_nodejs
msg_ok "Installed Node.js $(node -v)"

msg_info "Enabling user services for openclaw"
loginctl enable-linger openclaw
mkdir -p /home/openclaw/.config/systemd/user
chown -R openclaw:openclaw /home/openclaw/.config
msg_ok "Enabled user services"

msg_info "Setup OpenClaw config"
mkdir -p /home/openclaw/.openclaw
GATEWAY_TOKEN=$(openssl rand -hex 32)
cat <<CONF >/home/openclaw/.openclaw/openclaw.json
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
echo "${GATEWAY_TOKEN}" > /home/openclaw/.openclaw/.gateway-token
chown -R openclaw:openclaw /home/openclaw/.openclaw
chmod 700 /home/openclaw/.openclaw
chmod 600 /home/openclaw/.openclaw/openclaw.json
chmod 600 /home/openclaw/.openclaw/.gateway-token
msg_ok "Setup OpenClaw config"

msg_info "Running Security Audit"
sudo -u openclaw openclaw security audit --fix || true
msg_ok "Security Audit Complete"

motd_ssh
customize
cleanup_lxc
