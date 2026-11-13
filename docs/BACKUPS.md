# Backups

- Saved: service-managed configuration state only.
- Out of scope: media and per-device settings.

## What is saved

Per stack, under `docker/`:

- `media`: `qbittorrent-nox/config`, `radarr/config`, `sonarr/config`, `prowlarr/config`
- `monitoring`: `homarr/appdata`, `beszel/data`
- `networking`: `nginx-proxy/data` (plus its db export), `adguard/data`, `wg-easy/data`
- `others`: `code-server/config`
- `web`: `nginx/data`

## What is not saved

- Media libraries: owned by the disks, not by this repo.
- Per-device browser settings: bookmarks, extensions, sync, cache.
- `code-server/vsconfigs`: editor state, not server state.
- `pyload-ng/flash`: the service cannot restore it unattended, so the stack is skipped.

## Rule

- A service's state is saved only if the service can restore it unattended.
- Otherwise the stack is skipped, and the reason is stated at the place that skips it.

## Where it lives

- Encrypted `configs-*.zip` in [`backups/configs/`](../backups/configs/README.md).
- `ansible/roles/backups` is a stub; the script layer does the work.

## Related

- [Docs index](README.md)
- [Saved state on the node](../backups/configs/README.md)
