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

SSH changes are backed up under `/etc/ssh/dotfiles-backup.*` and rolled back
if validation or reload fails. Other drop-ins are not rewritten.
Fail2ban uses the same SSH ports and owns only `jail.d/99-dotfiles-server.local`.
Failed verification checks return a non-zero exit status and stop installation.

Docker-published ports bypass ordinary UFW INPUT rules. Compose bindings define
their exposure: bind private web UIs to `127.0.0.1`; publish only intended ports.
In homelab these are Caddy HTTP/HTTPS, Gitea SSH and TorrServer TCP/UDP.
Use the router firewall or Docker forwarding rules when source restrictions are needed.
