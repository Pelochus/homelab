# Software

Every service runs as a Docker stack, one compose file per service group, reached through
the VPN. The compose files are the source of truth for ports and options.

## DNS and reverse proxy

- **AdGuard Home**: DNS, HTTPS certificates, DoH for the proxy. Web UI on port 88 while
  configuring DNS, then that port is commented out.
- **Nginx Proxy Manager**: reverse proxy and public entry point.
- **DuckDNS**: the domains; a cron job re-validates the subdomain.
- **certbot**: public certificates.

## VPN

- **wg-easy**: the only public entry point. Ports 51820/UDP and 51821/TCP; the browser
  client connects through `ws://` to `http://10.0.1.10/`.

## NAS

- **ksmbd** (kernel Samba, in-kernel + DKMS module) serves `/media/hdd/BolloNAS`,
  configured by the `deploy` role from `ksmbd.conf.j2`.
- **SFTP** through the VPN.

## Media

- **Jellyfin**: transcodes on the CPU; the N100 codecs make this fine
- **Radarr / Sonarr / Prowlarr**
- **qBittorrent-nox**
- **pyload-ng**

## Development

- **code-server**: VS Code in the browser, password committed as an argon2 hash.

## Dashboard and monitoring

- **Homarr** dashboard
- **Beszel** hub + agent: host stats and per-container health

## Personal webpage

- Own repo as a submodule at `docker/web/web`; the served tree is `site/`, mounted instead
  of the checkout root.
- nginx reverse-proxies the Wiki and GitHub Pages.

## Ports

| Service | Port |
| --- | --- |
| Nginx Proxy Manager | 81 (public entry) |
| Nginx Proxy Manager admin | 91 |
| AdGuard Home | 88 (setup only) |
| Jellyfin | 8091 |
| Radarr | 7878 |
| Sonarr | 8989 |
| Prowlarr | 9696 |
| qBittorrent | 8080 (torrents) + 6881/UDP |
| pyload-ng | 8000 |
| code-server | 8443 |
| Beszel hub | 8090 |
| wg-easy | 51820/UDP, 51821/TCP |

Many service ports are commented out in the stacks and reached through the VPN instead.

## Not in use

- **Netdata**: Beszel covers host stats and container health
- **Jellyseerr**
- **Minecraft**
- **Pi-Hole**: AdGuard Home covers DNS
- **NoIP**: DuckDNS is used instead
- **pyload (old)**: pyload-ng runs instead

## Related

- [Docs index](README.md)
- [Docker stacks](DOCKER.md)
- [First-time setup order](1ST-TIME-SETUP.md)
