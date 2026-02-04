#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/spectrl/ProxmoxVE/openclaw/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: pfassina
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw
# Modified: Adapted to use Bun instead of Node.js, added security hardening

APP="OpenClaw"
var_tags="${var_tags:-ai-assistant;chatops}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/openclaw.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Stopping Service"
  systemctl stop openclaw
  msg_ok "Stopped Service"

  msg_info "Updating Bun"
  bun upgrade
  msg_ok "Updated Bun"

  msg_info "Updating OpenClaw"
  bun install -g openclaw
  msg_ok "Updated OpenClaw"

  msg_info "Running Security Audit"
  openclaw security audit --fix || true
  msg_ok "Security Audit Complete"

  msg_info "Starting Service"
  systemctl start openclaw
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Run 'openclaw onboard' inside the container to complete setup${CL}"
echo -e ""
echo -e "${INFO}${YW} Gateway binds to loopback only (official security best practice)${CL}"
echo -e "${INFO}${YW} To access the Control UI via SSH tunnel:${CL}"
echo -e "${TAB}${YW}1. ${BGN}ssh -L 18789:localhost:18789 root@${IP}${CL}"
echo -e "${TAB}${YW}2. Get token: ${BGN}cat /root/.openclaw/.gateway-token${CL}"
echo -e "${TAB}${YW}3. Open: ${BGN}http://localhost:18789?token=YOUR_TOKEN${CL}"
echo -e ""
echo -e "${INFO}${YW} Alternative: Install Tailscale for easier remote access${CL}"
echo -e "${INFO}${YW} WhatsApp/Telegram work without UI access${CL}"
