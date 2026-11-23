# pelochus/homelab V3

Personal home server: configuration, automation, and the reasoning behind both, so the
whole server can be rebuilt from scratch.

- One node today (`serverbollo`), a cluster later.
- Ansible automates the OS layer and the service deploy.
- One Docker compose stack per service group, reached through a VPN.
- State snapshots live in the repo, secrets do not.

![ServerMainWeb](https://github.com/Pelochus/homelab/blob/main/img/server-main-web.png)

- Homarr dashboard: every service on the left, the 3D-printer webcam on the right.

## Architecture

```mermaid
flowchart LR
    subgraph INTERNET["Public internet"]
        client["Browser / VPN client"]
        ddns["DuckDNS subdomains<br/>WG_HOST=pelochus.duckdns.org"]
    end

    subgraph ROUTER["Router + AP · 10.0.0.0/24"]
        router["Port forwarding: 80/443, 51820/UDP, 51821/TCP"]
    end

    subgraph RESERVED["Reserved · 10.0.2.0/24"]
        picam["3D-printer cam on a Raspberry Pi"]
    end

    subgraph N100["serverbollo · Intel N100 · primary 24/7 · homelab network 10.0.1.0/24"]
        direction TB
        subgraph NETWORKING["networking stack"]
            npm["nginx-proxy (NPM) · 10.0.1.10 · :81 entry, :91 admin"]
            adg["adguard · 10.0.1.11 · DNS + DoH, :88 setup only"]
            wge["wg-easy · 10.0.1.12 · 51820/UDP + 51821/TCP"]
        end
        subgraph MEDIA["media stack"]
            jelly["jellyfin · :8091"]
            arr["radarr :7878 · sonarr :8989 · prowlarr :9696"]
            qbit["qbittorrent-nox · :8080 + 6881/UDP"]
        end
        subgraph MONITORING["monitoring stack"]
            homarr["homarr · 10.0.1.20 · dashboard"]
            hub["beszel hub · 10.0.1.21"]
            agent["beszel-agent · network_mode: host"]
        end
        subgraph OTHERS["others stack"]
            code["code-server · :8443"]
            pyload["pyload-ng · :8000"]
        end
        subgraph WEB["web stack"]
            webn["nginx · 10.0.1.100 · serves docker/web/web/site"]
        end

        wge ==>|"ws:// to 10.0.1.10"| npm
        npm -->|"certificates + DoH"| adg
        npm -->|"reverse proxy"| MEDIA
        npm -->|"reverse proxy"| MONITORING
        npm -->|"reverse proxy"| OTHERS
        npm -->|"reverse proxy"| WEB
        hub -.->|"beszel.sock / BESZEL_URL"| agent
    end

    subgraph BC250["AMD BC250 · AI/inference node · not in ansible/hosts yet"]
        ai["Runs a subset of ansible/group_vars/all.yml:compose_stacks"]:::planned
    end

    client ==>|"only public entry: VPN"| wge
    ddns -->|"80/443"| router
    router -->|"51820/UDP + 51821/TCP"| wge
    router -->|"DHCP"| picam
    N100 -.->|"same 10.0.0.0/16 plan · own group in ansible/hosts"| BC250

    classDef planned stroke-dasharray 3 3,stroke:#888
```

- Private addressing on `10.0.0.0/16`: router and DHCP `10.0.0.0/24`, this server `10.0.1.0/24`, the printer-cam Pi `10.0.2.0/24`.
- wg-easy is the only public entry point; Nginx Proxy Manager and AdGuard Home answer on the `homelab` Docker network, gateway `10.0.1.1`.
- A container with `network_mode: host` sits outside that network and reaches siblings through a shared volume or the public URL.
- The BC250 node is a plan, not a deploy: it gets its own group in `ansible/hosts` and its own playbook.

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
