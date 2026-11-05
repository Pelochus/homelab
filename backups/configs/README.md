## Configs
Backups of server apps configurations, at least those who can/need it. 
Everything encrypted (for security reasons) in the zip

This includes:
- Pi-Hole
- AdGuard Home (docker/networking/adguard/config and adguard/work)
- Wireguard Easy (docker/networking/wireguard)
- nginx reverse proxy (docker/networking/nginx/data and nginx/letsencrypt:
  upstreams, domains and ACME certificates, all set in the UI, so they are
  untracked in git on purpose and this zip is the only copy worth keeping)
- Homarr (docker/monitoring/homarr/appdata)
- *Arr (docker/media/prowlarr/config, radarr/config and data, sonarr/config and data)
- OctoPi (outside this server)
- Asus Router (also outside this server)

**Remember to always update everything at once, just in case**
