# Ansible

Ansible automates the OS layer and the service deploy. One node today (`[master]`), a
cluster later: a second node is a new group in `ansible/hosts` with its own playbook, not
a playbook that branches.

## Playbooks (`ansible/*.yml`)

- `os-config.yml` → role `config`: `.bashrc` block, system packages, unattended upgrades,
  timezone, hardware watchdog, refresh timer
- `software-deploy.yml` → role `deploy`: docker user/group, compose state ownership, ksmbd
  share, `homelab` network, stacks present
- `docker-refresh.yml` → inline tasks: pull every stack, prune old images
- `backup.yml` → role `backups`: **stub**, the script layer does the work

```bash
cd ~/homelab/ansible && sudo ansible-playbook os-config.yml
```

## Roles (`ansible/roles/`)

- `config`, `deploy`, `backups` (stub)
- Role-level vars carry the role prefix (`config_*`, `deploy_*`, `backups_*`);
  `group_vars/all.yml` vars do not.

## Facts live in group_vars, not in roles

- `ansible/group_vars/all.yml` — shared: `homelab_root`, `compose_stacks`,
  `deploy_docker_subnet`, package lists, backup paths
- `ansible/group_vars/master.yml` — per node: `user`, `uid`, `gid`,
  `deploy_samba_share`, `deploy_docker_group`, `config_timezone`
- `ansible/hosts` — `[master]` = `serverbollo`; `[containers]` commented out
- `ansible/ansible.cfg` — `inventory = hosts`, `pipelining = True`
- `ansible/requirements.yml` — `community.docker` collection, so
  `ansible-playbook -r ansible/requirements.yml` resolves the FQCNs

## Cadence

- config: once per node
- deploy: once per node
- refresh: monthly, by `homelab-refresh.timer`
- backup: monthly, by the script layer

## Gotchas

- The node has no `ansible`, `ansible-lint` or `yamllint`; install them outside the repo.
- No `NOPASSWD` in sudoers → run playbooks with `sudo`.
- `docker_compose_v2` with `pull: always` always reports a change; that is the timer's
  intent, not a bug.
- systemd units name absolute executables (`/usr/bin/ansible-playbook`).
- `ansible-lint` reads `.ansible-lint*` from the current directory → run
  `ansible-lint ansible` from the repo root; inside `ansible/` it silently uses the
  default ruleset.
- A bare-string `when` is rejected ("Conditionals must have a boolean result") → write
  `x != ''`.
- Derived `<taskname>_<key>` result variables are undefined; never guard on `_changed`.

## Related

- [Docs index](README.md)
- [OS layer owned by the config role](OS.md)
- [Docker stacks and refresh](DOCKER.md)
