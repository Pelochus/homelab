# Docker

One compose stack per service group under `docker/<stack>/`, so a node runs a subset. Stack
names live in `ansible/group_vars/all.yml:compose_stacks`.

## Stacks

- `media`: qbittorrent-nox, prowlarr, radarr, sonarr, jellyfin
- `monitoring`: homarr, beszel (hub), beszel-agent
- `networking`: nginx-proxy (NPM), adguard, wg-easy
- `others`: code-server, pyload-ng
- `web`: nginx (mounts `docker/web/web/site`, not the checkout root)

## Files per stack

- `docker-compose.yml` — tracked
- `.env` — node facts (ports, uids, paths), tracked
- `.secrets.env` — secrets, gitignored, read through `env_file`
- state dirs (`<stack>/<service>/`) — untracked

## Network

- All stacks use the external `homelab` network (`10.0.1.0/24`, gateway `10.0.1.1`); each
  service gets an `ipv4_address` from `10.0.1.10` up.
- A container with `network_mode: host` or `pid: host` sits outside it and cannot resolve
  a `10.0.1.x` peer: it reaches siblings through a shared volume or the public URL
  (`beszel-agent`, `BESZEL_URL`, `beszel.sock`).

## Health

- Every container has a `healthcheck:` block, so `docker ps` shows `(healthy)` and Beszel's
  health column is real instead of `None`.
- `healthcheck.test` must start with `CMD`, `CMD-SHELL`, or `NONE` — `EXEC` is rejected
  even though the Docker docs show it. A warm-up goes in `start_period`.
- Any `${VAR}` used inside a `healthcheck:` must exist in that stack's `.env`; an unset
  one interpolates to an empty duration and fails to parse.

## Images

- Every image carries an explicit `:latest` — never a pin, never a bare tag.
- Upstream drift is accepted the way `apt upgrade` is, and the monthly refresh repairs a
  bad release.

## Refresh

- `ansible/docker-refresh.yml` pulls all stacks (`pull: always`, so it always reports a
  change) and prunes old images.
- Run by `homelab-refresh.timer` on the first of each month at 04:00.

## Commands

```bash
cd docker/<stack> && docker compose up --detach
docker compose down
docker compose restart
```

## TODO

- Uptime Kuma as a status page

## Related

- [Docs index](README.md)
- [Software and ports](SOFTWARE.md)
- [Ansible refresh cadence](ANSIBLE.md)
