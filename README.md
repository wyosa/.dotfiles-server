```
         __      __  _____ __ 
    ____/ /___  / /_/ __(_) /__  _____      ________  ______   _____  _____
   / __  / __ \/ __/ /_/ / / _ \/ ___/_____/ ___/ _ \/ ___/ | / / _ \/ ___/
 _/ /_/ / /_/ / /_/ __/ / /  __(__  )_____(__  )  __/ /   | |/ /  __/ /
(_)__,_/\____/\__/_/ /_/_/\___/____/     /____/\___/_/    |___/\___/_/
```

Dotfiles & setup scripts for Ubuntu Server / Debian.

## Quick start

```bash
git clone https://github.com/tokyo/dotfiles-server.git ~/dotfiles-server
cd ~/dotfiles-server
bash scripts/install.sh
```

Or one-shot full install:

```bash
bash scripts/install.sh --all
```

## What's inside

### Scripts

| Script | What it does |
|---|---|
| `scripts/install.sh` | Interactive menu — link dotfiles, run any setup |
| `scripts/packages.sh` | Base packages: htop, curl, git, vim, tmux, jq, ncdu, etc. |
| `scripts/system.sh` | Timezone, hostname, swap |
| `scripts/services/docker.sh` | Docker Engine + Compose (Ubuntu & Debian) |
| `scripts/services/sshd.sh` | SSH hardening: password auth, no root, MaxAuthTries 3 |
| `scripts/services/firewall.sh` | UFW: deny incoming, rate-limited SSH |
| `scripts/services/fail2ban.sh` | Fail2ban: 3 attempts → 24h ban on SSH |
| `scripts/services/unattended-upgrades.sh` | Auto security updates (no auto-reboot) |
| `scripts/lib/common.sh` | Shared helpers: colors, check counters, OS detection |

## Security defaults

- SSH: password auth (public key auth disabled)
- SSH: root login disabled, MaxAuthTries 3
- UFW: deny all incoming, allow SSH with rate-limit
- Fail2ban: 3 failed attempts → 24h ban
- Unattended upgrades: security patches auto-installed

> ⚠️ Password-only auth means brute-force protection (UFW rate-limit
> + Fail2ban) is doing real work — keep both active and use a strong password.
