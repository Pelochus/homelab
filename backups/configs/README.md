# Configs

Service-managed state, encrypted in `configs-<DDMonthYYYY>.zip`
(`configs-20September2025.zip`).

## Saved

- AdGuard Home: `docker/networking/adguard/config`, `adguard/work`
- WireGuard Easy: `docker/networking/wireguard` (`wg0.json`)
- Nginx reverse proxy: `docker/networking/nginx/data`, `nginx/letsencrypt` — upstreams,
  domains and ACME certificates are set in the UI and untracked in git, so this zip is the
  only copy
- Homarr: `docker/monitoring/homarr/appdata` (`key.txt`, `migrate-homarr.zip`)
- *Arr: `docker/media/prowlarr/config`, `radarr/config` and `data`,
  `sonarr/config` and `data` (each service writes its own `*_backup_*.zip`)
- Pi-Hole: teleporter state, from before AdGuard Home replaced it
- OctoPrint and the Asus router (`Settings_RT-BE92U.CFG`): state lives outside this server

## Not saved

- Services configured on the fly, e.g. Jellyfin per device, by codec.
- Media libraries and per-device browser settings: see
  [Backups](../../docs/BACKUPS.md).

## Rule

- Every zip contains every backed-up service; a partial snapshot does not go in.
