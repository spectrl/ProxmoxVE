# OpenClaw Scripts for Proxmox

Custom OpenClaw installation with Bun runtime and security hardening.

**Branch:** `openclaw` (main tracks upstream)

## Run on Proxmox

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/spectrl/ProxmoxVE/openclaw/ct/openclaw.sh)"
```

## Files

- `ct/openclaw.sh` - Container creation script
- `install/openclaw-install.sh` - Installation script (Bun + hardened config)
- `frontend/public/json/openclaw.json` - App metadata

## Security Hardening

- Gateway binds to loopback only
- Token authentication (64-char random)
- DM pairing enabled (all channels)
- Group messages require @mention
- mDNS discovery disabled
- File permissions 700/600
- Security audit runs on install/update

## Access

```bash
# SSH tunnel
ssh -L 18789:localhost:18789 root@<container-ip>

# Get token
cat /root/.openclaw/.gateway-token

# Open UI
http://localhost:18789?token=YOUR_TOKEN
```

---

## ⚠️ BEFORE SUBMITTING PR TO UPSTREAM

This branch has `misc/*.func` files modified to point to this fork (`spectrl/ProxmoxVE`).
The `main` branch tracks upstream and is clean.

**When creating a PR to community-scripts/ProxmoxVE:**

1. Checkout main (already tracks upstream)
2. Copy OpenClaw files from this branch
3. Fix the source URL back to `community-scripts/ProxmoxVE`

```bash
# Create PR branch from clean main
git checkout main
git pull upstream main
git checkout -b openclaw-pr

# Copy OpenClaw files from openclaw branch
git checkout openclaw -- ct/openclaw.sh install/openclaw-install.sh frontend/public/json/openclaw.json

# Fix the source URL in ct/openclaw.sh back to community-scripts
sed -i '' 's|spectrl/ProxmoxVE|community-scripts/ProxmoxVE|g' ct/openclaw.sh

# Commit and create PR
git add -A
git commit -m "Add OpenClaw with Bun runtime and security hardening"
gh pr create --repo community-scripts/ProxmoxVE
```
