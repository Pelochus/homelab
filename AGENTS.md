# AGENTS.md — rules for this repository

Scope: the whole repo — `ansible/` (deploy automation), `docker/` (one compose stack
per service group), `docker/web/web` (submodule of the personal page), `backups/`,
`img/`, `logs/`, the root scripts, and the root config files.

Read [the repo README](README.md) for the public description and the TODO roadmap, and
[the docs index](docs/README.md) for the long-form pages (hardware, OS, software,
backups, Ansible, Docker, first-time setup).

## 1. Design

- **Simple and minimal beats capable.** Prefer what is cheap to set up, cheap to run
  and light on RAM over what does more: `beszel` over `netdata`, `wg-easy` over a
  hand-rolled OVPN/iptables setup. When a lighter tool covers the need, switch to it
  and delete the heavier one.
- **One way to do a thing per layer.** No shell script *and* an ansible task for one
  job. A layer kept only as a fallback says so in its README.
- **Security over convenience**, as defaults:
  - Secrets never live in tracked files: node facts go in the tracked
    `docker/<stack>/.env`, secrets in the gitignored `docker/<stack>/.secrets.env`.
  - A credential that must survive a from-scratch redeploy is committed as a one-way
    hash (`CODE_SERVER_HASHED_PASSWORD` is argon2), never as ciphertext keyed by
    something in the repo.
  - Unattended system upgrades are the OS layer, not an ansible task.
  - Every container gets `init: true` unless it shares the host PID namespace or its image owns `/init` (s6-overlay refuses to run outside pid 1).
- **Rules are defaults, not a contract.** When one fights a case, break it and say why
  at the place it breaks — a one-line comment, or the README. A short note that carries
  a fact is worth keeping even where a style rule would seem to forbid it: what a stub
  is for, why a layer is only a fallback, a vendor quirk, a value that was chosen over
  a better-looking one.
- **Images track upstream.** Every image carries an explicit `:latest` — never a pin,
  never a bare tag. Upstream drift is accepted the way `apt upgrade` is, and the
  monthly refresh repairs a bad release.
- **Anything that can drift is a variable** — paths, ports, uids, package lists,
  per-node facts go in `group_vars`, a compose `.env`, or `${VAR:-default}`, not inside
  a task or a literal line. Reuse the names already in use (`homelab_root`, `user`,
  `compose_stacks`, `docker_prune_filter`, `config_syspkgs`, `backups_paths`,
  `HOMELAB_TZ`, `MEDIA_ROOT`, `WG_HOST`) rather than adding near-duplicates.
  A compose `ipv4_address:` may stay a literal until it earns a name; name it once
  another node would have to change it (`ADGUARD_IPV4`).

## 2. Think long-term and extensible

One node today (`[master]`), a cluster later: a second node — e.g. the AMD BC250 box
running a different subset — is a new group in `ansible/hosts` and its own playbook
in this repo, not a new repo and not a playbook that branches.

- Node facts live in `group_vars`, not in roles: `ansible/group_vars/all.yml` for
  shared values, one file per group for per-node overrides. A role that hardcodes a
  path, a uid or a host name cannot serve a second node.
- Keep roles small and composable; a per-node playbook opts into the roles it needs.
- One compose stack per service group (`docker/<stack>/docker-compose.yml`) so a node
  runs a subset; the stack names live in `ansible/group_vars/all.yml:compose_stacks`,
  not in a task.
- No single-host literals in shared files (`/home/<user>`, `/mnt/<disk>`, uid `1001`):
  name them (`homelab_root`, `deploy_samba_share`, `deploy_docker_subnet`) so the next
  node overrides a variable instead of editing the file.

## 3. Style — code and docs

- **Self-documenting first.** Descriptive names, small units, obvious structure
  (`docker_prune_filter`, `apt_cache_valid_time_installs`, `config_refresh_cadence`).
- **Comments are one line**, and only where the "why" cannot be read from the file
  itself: an unsafe or fragile contract, a vendor quirk, a marshalling rule, a
  non-obvious constant, what a stub is for, why a layer is only a fallback.
- **Switchable settings stay in code**: separator banners inside a file
  (`End of Arr configuration`), and commented-out knobs this host does not use
  (`# - samba`, `# - 51821:51821/tcp`, `# OnUnitActiveSec=2weeks`). Keep them beside the
  live block — they are settings, not dead code.
- **No narration.** Comments, docs and commit messages state facts and rules, never
  decisions, plans, discoveries, or who found what. Drop "planned", "not yet",
  "as discussed above", "the linter caught this"; keep the fact the note carried.
- **Docs are scanned, not studied**: short lines, plain wording, no storytelling about
  how a trick works. A doc states facts and rules; the rationale for a setting lives
  with the setting. Long-form docs live in `docs/`; in-repo docs are
  `README.md`, `docs/README.md` and `backups/configs/README.md`.
- **Markdown pages: one H1 title, `##` sections**, bulleted, no first-person narration.
  Link text says what the target holds (`[Docker stacks](docs/DOCKER.md)`), never the bare
  filename; relative links only, and every page ends with a `## Related` block that
  points at [the docs index](docs/README.md).

## 4. Layout

| Path | Role |
| --- | --- |
| `ansible/` | roles (`config`, `deploy`, `backups`), `hosts`, `group_vars/all.yml`, `requirements.yml` |
| `ansible/*.yml` | the entry playbooks: `software-deploy`, `os-config`, `docker-refresh`, `backup` |
| `docker/<stack>/` | one compose stack per service group: `media`, `monitoring`, `networking`, `others`, `web` |
| `docker/<stack>/.env` | node facts for that stack, tracked |
| `docker/<stack>/.secrets.env` | secrets for that stack, gitignored, read through `env_file` |
| `docker/web/web/` | submodule → the `web` repo; the served tree is `site/`, mount that, never the checkout root |
| `backups/configs/` | saved node state (`configs-*.zip`) + its README |
| `docs/` | long-form documentation, index `docs/README.md` |
| `lint.sh`, `setup.sh`, `secrets.sh` | local mirror of CI; first-run bootstrap on a fresh node; writes the gitignored stack secrets once |
| `.yamllint`, `.ansible-lint`, `.ansible-lint-ignore`, `.gitattributes` | the linters' own configs, at the **repo root** (discovery is working-directory based — see §5) |
| `img/`, `logs/` | screenshots and saved logs (`logs/` gitignored) |

## 5. Verification

- Run `./lint.sh` (or CI's `.github/workflows/lint.yml`) before committing YAML/Ansible
  changes; it must exit 0.
- ansible-lint reads `.ansible-lint` and `.ansible-lint-ignore` from the **current
  directory**, so run `ansible-lint ansible` from the repo root. Inside `ansible/` it
  silently uses the default ruleset — a green run there proves nothing.
- This host has no `ansible`, `ansible-lint`, or `yamllint`; install them outside the
  repo, never as repo dependencies. `docker compose config` runs here, but nothing
  deploys and no container starts here: playbook behaviour and container runtime are
  **not** verifiable on this machine. Never claim a deploy or a container was verified.
- An entry in `.ansible-lint-ignore` names its file and rule; revisit a skip instead
  of letting skips accumulate.

## 6. Commits

- Scope a commit to one logical block; never one commit per micro-task.
- Fold a small follow-up into the commit it fixes: `git commit --amend`, or
  `git reset --soft <parent>` plus one commit for a run at the tip. No trail of
  "fix", "typo", "also" commits.
- Subject: imperative, `Area: what changed`, `Area` one of Ansible | Docker | Docs |
  CI | Submodules | Config | Scripts | Clean.
- Body optional, bullets-only, usually absent. Never narrate the process.
- The remote carries `V1`, `V2`, `isew` as backup branches: never delete them, never
  force-push over them.
- Never `git push` unless explicitly asked; every other git operation is allowed.

## 7. Gotchas that will bite again

- `.gitignore` tracks the stack dirs, their `docker-compose.yml` and their `.env`, and
  ignores everything else inside them, `docker/*/.secrets.env` included: a new stack's
  compose file is addable straight away, its state dirs stay untracked.
- `logs/`, `.pi/`, `.cache/`, `.ansible/` are ignored; do not re-add generated state.
- `git submodule update` checks out the **pinned** sha, and the pin follows `main` only
  when moved deliberately: pushing the `web` repo never reaches the node by itself.
- `ansible-lint` requires role-level vars to carry the role prefix (`deploy_*`,
  `backups_*`, `config_*`); `group_vars/all.yml` vars do not.
- systemd units need absolute executables (`/usr/bin/ansible-playbook`, not a bare
  name).
- `docker_compose_v2` with `pull: always` always reports a change — the monthly-refresh
  timer's intent, not a bug.
- A container with `network_mode: host` or `pid: host` sits outside the `homelab`
  network and cannot resolve any `10.0.1.x` peer: it reaches siblings through a shared
  volume or the public URL (`beszel-agent`, `BESZEL_URL`, `beszel.sock`).
- compose interpolates `$` inside values substituted from a `.env`, so an argon2 hash
  written into a `.env` doubles every `$` (`$$` in the file is one `$` at runtime); an
  unescaped hash arrives mangled and the service silently loses its auth.

## 8. Docs and references

- [Repo README](README.md): public description and the TODO roadmap — update it when
  conventions or layout change.
- [docs/README.md](docs/README.md): index of the long-form pages — hardware, OS,
  software, backups, Ansible, Docker, first-time setup. It links every page; pages link
  back to it under `## Related`. There is no `ansible/README.md` or `docker/README.md`.
- [Backups README](backups/configs/README.md): what state is saved on the node and when.
- Update this file whenever a convention changes.
