# 1st time setup

Order of work on a fresh node:

1. Set up **DuckDNS**: subdomain, the cron script that re-validates it, a certificate.
   The VPN is the only public entry point.
2. Install **Ubuntu Server** (or Debian). Only Debian/Ubuntu-based systems are supported,
   because of `apt`.
3. Enable SSH, install `git`, clone this repo.
4. Add the fstab entry for the external HDD with `nofail`, so a disconnected disk still boots.
5. Set the timezone (`timedatectl set-timezone Europe/Madrid`) and the node facts:
   `ansible/hosts`, `ansible/group_vars/all.yml`, `ansible/group_vars/<node>.yml`.
6. Run `setup.sh` (first-run bootstrap), then `secrets.sh` to write each stack's
   gitignored `.secrets.env`. `lint.sh` mirrors CI's lint job.
7. Run the playbooks in order:
   - `sudo ansible-playbook os-config.yml` (packages, unattended upgrades, watchdog, timer)
   - `sudo ansible-playbook software-deploy.yml` (docker, ksmbd, network, stacks)
   - `cd docker/<stack> && docker compose up --detach` for each stack
8. AdGuard Home: use web UI port 88 while configuring DNS, then comment that port out.
9. Wireguard: the browser client connects through `ws://` to `http://10.0.1.10/`.
10. The ksmbd share path must exist (`/media/hdd/BolloNAS`) before the share is enabled.
11. Beszel: pair the agent from the hub UI; `KEY` and `TOKEN` go into
   `docker/monitoring/.secrets.env`.

## Secrets

- Secrets: gitignored `docker/<stack>/.secrets.env`, read through `env_file`.
- Node facts: tracked `docker/<stack>/.env`.
- A credential that must survive a from-scratch redeploy is tracked as a one-way hash.
- `./secrets.sh` writes the generated ones; `setup.sh` runs it when the file is missing.
- `docker/others/.env`: `CODE_SERVER_HASHED_PASSWORD` — argon2 only, bcrypt rejected;
  `echo -n 'password' | argon2 "$(openssl rand -hex 8)" -e -i`; every `$` doubled
  (compose interpolates `$` in `.env` values).
- `docker/monitoring/.secrets.env`: `SECRET_ENCRYPTION_KEY` — `openssl rand -hex 32`,
  64 hex characters; `TOKEN` and `KEY` — from the Beszel hub: Settings → tokens, and the
  system's SSH public key.

## Guides

- [Full homeserver guide](https://github.com/zilexa/Homeserver)
- [WikiArr, for \*Arr installs](https://wiki.servarr.com/)
- [Jellyfin install on Linux](https://jellyfin.org/docs/general/installation/linux/)
- [qBittorrent daemon + WebUI](https://github.com/qbittorrent/qBittorrent/wiki/Running-qBittorrent-without-X-server-(WebUI-only,-systemd-service-set-up,-Ubuntu-15.04-or-newer))
- [DuckDNS cron re-validation](https://www.duckdns.org/install.jsp?tab=linux-cron)
- [SSL across the local network](https://www.youtube.com/watch?v=qlcVx-k-02E)

## Related

- [Docs index](README.md)
- [OS setup facts](OS.md)
- [Software and ports](SOFTWARE.md)
