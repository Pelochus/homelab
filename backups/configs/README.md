ç## Configs

Service-managed state, encrypted in `configs-*.zip`.

Saved paths:
- AdGuard Home (`docker/networking/adguard/config`, `adguard/work`)
- WireGuard Easy (`docker/networking/wireguard`)
- Nginx reverse proxy (`docker/networking/nginx/data`, `nginx/letsencrypt`):
  upstreams, domains and ACME certificates are set in the UI, untracked in git,
  so this zip is the only copy
- Homarr (`docker/monitoring/homarr/appdata`)
- *Arr (`docker/media/prowlarr/config`, `radarr/config` and `data`,
  `sonarr/config` and `data`)
- Pi-Hole (state from before AdGuard Home replaced it)
- OctoPi and the Asus router (state lives outside this server)

Not saving other services as they should be configured on the fly 
(e.g.: Jellyfin on device basis depending on codecs)

Every zip should contain every service that is backed-up, no half-backed-up commits should go here
