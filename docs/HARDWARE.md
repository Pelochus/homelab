# Hardware

Hostname `serverbollo`.

## Specs

- **Intel N100 (Alder Lake)**: QuickSync iGPU, `/dev/dri/renderD128` (group `render`)
- **16 GB RAM**
- **512 GB SSD** (SATA, ~500 MB/s), holds the OS; `/dev/sdb`
- **Gigabit Ethernet**

## Storage

- **WD external HDD 3.6 TB** (`/dev/sda1`, ext4) mounted on `/media/hdd`, ~1.3 TB used
- fstab options `defaults,nofail,x-systemd.device-timeout=10s 0 2`: a disconnected HDD still
  boots and never drops into maintenance mode
- The share served over Samba is `/media/hdd/BolloNAS`

## Networking

Private addressing on **10.0.0.0/16**:

- `10.0.0.0/24` router and DHCP
- `10.0.1.0/24` this server; every container sits on the `homelab` Docker network from
  `10.0.1.10` up, gateway `10.0.1.1`
- `10.0.2.0/24` reserved for the Raspberry Pi running the 3D-printer cam

## Future upgrades

- More disk space, RAID, or a ZFS/BTRFS filesystem (only worth it on real server hardware)
- A second node: the AMD BC250 box would be its own group in `ansible/hosts` with its own
  playbook, running a different subset of the stacks

## TODO

- Cable management and a case

## Related

- [Docs index](README.md)
- [Software and ports](SOFTWARE.md)
- [Docker stacks and network](DOCKER.md)
