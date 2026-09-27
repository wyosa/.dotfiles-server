```
         __      __  _____ __ 
    ____/ /___  / /_/ __(_) /__  _____      ________  ______   _____  _____
   / __  / __ \/ __/ /_/ / / _ \/ ___/_____/ ___/ _ \/ ___/ | / / _ \/ ___/
 _/ /_/ / /_/ / /_/ __/ / /  __(__  )_____(__  )  __/ /   | |/ /  __/ /
(_)__,_/\____/\__/_/ /_/_/\___/____/     /____/\___/_/    |___/\___/_/
```

Dotfiles & setup scripts for Ubuntu Server / Debian.

### Quick start

```bash
git clone https://github.com/tokyo/dotfiles-server.git ~/dotfiles-server
cd ~/dotfiles-server
bash scripts/install.sh
```

### Scripts

| Script | What it does |
|---|---|
| `scripts/install.sh` | Interactive menu — link dotfiles, run any setup |
| `scripts/packages.sh` | Base packages, jq and Go Task (official APT repository) |
| `scripts/system.sh` | Timezone, hostname, swap |
| `scripts/services/docker.sh` | Docker Engine + Compose (Ubuntu & Debian) |
| `scripts/services/sshd.sh` | Enable SSH keys; preserve password/root policy; validate and back up changes |
| `scripts/services/firewall.sh` | UFW: deny incoming, rate-limit configured and current SSH ports |
| `scripts/services/fail2ban.sh` | Fail2ban: 3 attempts → 24h ban on SSH |
| `scripts/services/unattended-upgrades.sh` | Auto security updates (no auto-reboot) |
| `scripts/lib/common.sh` | Shared helpers: colors, check counters, OS detection |

### Security defaults

- SSH: public key auth enabled; existing password and root login policy preserved
- SSH: MaxAuthTries 3, X11 forwarding disabled; managed include loaded first
- SSH: test key login in a second session before disabling password or root login
- UFW: deny incoming, allow all configured SSH ports and the current session port
- Fail2ban: 3 failed attempts → 24h ban
- Unattended upgrades: security patches auto-installed
