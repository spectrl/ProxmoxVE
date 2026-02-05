#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/spectrl/ProxmoxVE/openclaw/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: pfassina
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw
# Modified: Added security hardening

APP="OpenClaw"
var_tags="${var_tags:-ai-assistant;chatops}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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
  if ! command -v openclaw &>/dev/null; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating OpenClaw"
  npm update -g openclaw
  msg_ok "Updated OpenClaw"

  msg_info "Running Security Audit"
  sudo -u openclaw openclaw security audit --fix || true
  msg_ok "Security Audit Complete"

  msg_ok "Updated successfully! Restart gateway with: sudo -u openclaw openclaw gateway restart"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e ""
echo -e "${INFO}${YW} SSH Credentials:${CL}"
echo -e "${TAB}${YW}User: ${BGN}openclaw${CL}"
echo -e "${TAB}${YW}Password: ${BGN}openclaw${CL} (change after first login)"
echo -e ""
echo -e "${INFO}${YW} Complete setup:${CL}"
echo -e "${TAB}${YW}1. ${BGN}ssh openclaw@${IP}${CL}"
echo -e "${TAB}${YW}2. ${BGN}openclaw onboard --install-daemon${CL}"
echo -e ""
echo -e "${INFO}${YW} Gateway binds to loopback only (official security best practice)${CL}"
echo -e "${INFO}${YW} To access the Control UI via SSH tunnel:${CL}"
echo -e "${TAB}${YW}1. ${BGN}ssh -L 18789:localhost:18789 openclaw@${IP}${CL}"
echo -e "${TAB}${YW}2. Get token: ${BGN}cat ~/.openclaw/.gateway-token${CL}"
echo -e "${TAB}${YW}3. Open: ${BGN}http://localhost:18789?token=YOUR_TOKEN${CL}"
echo -e ""
echo -e "${INFO}${YW} Change password: ${BGN}passwd${CL} after first login${CL}"
echo -e "${INFO}${YW} Optional: Install Tailscale for easier remote access (no SSH tunnel needed)${CL}"
