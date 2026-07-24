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

### Dotfiles

| File | What it does |
|---|---|
| `.bashrc` | Prompt with git branch, history settings, shell options |
| `.bash_aliases` | Aliases + functions: `ll`, `update`, `install`, `dc`, `ports`, etc. |
| `.gitconfig` | Git aliases (`st`, `lg`, `co`), rebase pull, autoSetupRemote |
| `.tmux.conf` | Prefix `C-a`, vim-style panes, mouse, 256color |

### Scripts

| Script | What it does |
|---|---|
| `scripts/install.sh` | Interactive menu — link dotfiles, run any setup |
| `scripts/packages.sh` | Base packages: htop, curl, git, vim, tmux, jq, ncdu, etc. |
| `scripts/system.sh` | Timezone, hostname, swap |
| `scripts/services/docker.sh` | Docker Engine + Compose (Ubuntu & Debian) |
| `scripts/services/sshd.sh` | SSH hardening: key-only auth, no root, MaxAuthTries 3 |
| `scripts/services/firewall.sh` | UFW: deny incoming, allow SSH |
| `scripts/services/fail2ban.sh` | Fail2ban: 3 attempts → 24h ban on SSH |
| `scripts/services/unattended-upgrades.sh` | Auto security updates (no auto-reboot) |
