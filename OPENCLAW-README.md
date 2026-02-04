# OpenClaw Scripts for Proxmox

Custom OpenClaw installation with Bun runtime and security hardening.

## Run on Proxmox

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/spectrl/ProxmoxVE/main/ct/openclaw.sh)"
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

The `misc/*.func` files have been modified to point to this fork (`spectrl/ProxmoxVE`).

**When creating a PR to community-scripts/ProxmoxVE:**

1. Create a fresh branch from upstream/main
2. Cherry-pick ONLY the OpenClaw commits (not the misc/*.func changes)
3. Or manually copy just these files:
   - `ct/openclaw.sh` (change source URL back to `community-scripts/ProxmoxVE`)
   - `install/openclaw-install.sh`
   - `frontend/public/json/openclaw.json`

```bash
# Example: create PR branch from upstream
git fetch upstream
git checkout -b openclaw-pr upstream/main
git checkout main -- ct/openclaw.sh install/openclaw-install.sh frontend/public/json/openclaw.json

# Fix the source URL in ct/openclaw.sh back to community-scripts
sed -i 's|spectrl/ProxmoxVE|community-scripts/ProxmoxVE|g' ct/openclaw.sh

git add -A
git commit -m "Add OpenClaw with Bun runtime and security hardening"
gh pr create --repo community-scripts/ProxmoxVE
```
