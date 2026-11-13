# pelochus/homelab V3

Personal home server: configuration, automation, and the reasoning behind both, so the
whole server can be rebuilt from scratch.

- One node today (`serverbollo`), a cluster later.
- Ansible automates the OS layer and the service deploy.
- One Docker compose stack per service group, reached through a VPN.
- State snapshots live in the repo, secrets do not.

![ServerMainWeb](https://github.com/Pelochus/homelab/blob/main/img/server-main-web.png)

- Homarr dashboard: every service on the left, the 3D-printer webcam on the right.

![Architecture](https://github.com/Pelochus/homelab/blob/main/img/pelochus-homelab.drawio.png)

- Network layout: router, this server, the printer-cam Pi, and the container addresses.

## Docs

- [Docs index](docs/README.md) — hardware, OS, software, backups, Ansible, Docker,
  first-time setup
- [Repo conventions](AGENTS.md) — design rules, layout, verification, commit style

## Short-term TODO

- Add the AI node (AMD BC250) to the docs and to `ansible/hosts`.
- Split Ansible per device type: install on the BC250 node what it needs, not what the
  N100 needs.

## TODO

- Rethink backups automation (Rsync + Bash, or Ansible).
- CI/CD and GitOps: auto-deploy the webserver on git push.
- Use cloud-init for clusters.
- Use k3s.
- Reduce Ansible where it only refreshes Docker services.
- Proxmox as base OS, with Ubuntu Server/Debian on top.
- Add more services: Uptime Kuma.
