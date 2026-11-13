# OS

Ubuntu Server 26.04 LTS (kernel 7.0). Debian/Ubuntu-based systems only: the repo installs
packages through `apt`.

## Set once after installing the OS

- Install on the internal SSD, enable SSH
- Non-root main user, in `docker` and `sudoers`
- fstab entry for the external HDD (`nofail`, see [Hardware](HARDWARE.md))
- Timezone `Europe/Madrid`, set by the config role
- Only the VPN port is open (51820/UDP); everything else is reached through the VPN

## Owned by the config role

`ansible/roles/config` writes these, so they are not edited by hand:

- **`.bashrc` block**: personal aliases, applied with `blockinfile`
- **System packages**: `config_syspkgs` in `ansible/roles/config/defaults/main.yml` — tools
  plus coreutils replacements (`eza`, `bat`, `ripgrep`, `fd`, `zoxide`, `duf`, `ncdu`, `fzf`)
- **Unattended upgrades**: `/etc/apt/apt.conf.d/20unattended` (mail, no reboot requests)
- **Timezone**: `config_timezone`
- **Hardware watchdog**: `/etc/watchdog.conf` + `/etc/default/watchdog`, device
  `/dev/watchdog0`, timeout 30, interval 10
- **Refresh timer**: `homelab-refresh.service` + `.timer`, cadence `*-*-01 04:00`, output
  logged to `logs/`

## Maintenance

- apt upgrades: `unattended-upgrades`, the OS layer
- Docker image refresh: `homelab-refresh.timer`
- Service state snapshots: the `backup.yml` script layer

## Alternatives

- **DietPi**: lighter, suited to Pis
- **CasaOS**: app store for typical homelab containers
- **Proxmox below Ubuntu**: candidate base OS

## TODO

- Filesystem: ZFS/BTRFS on real server hardware
- MergerFS + SnapRAID for a multi-disk build

## Related

- [Docs index](README.md)
- [Hardware and disks](HARDWARE.md)
- [Ansible config role](ANSIBLE.md)
