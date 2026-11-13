# AGENTS.md — rules for this repository

Scope: the whole repo — `ansible/` (deploy automation), `docker/` (one compose stack
per service group), `docker/web/web` (submodule of the personal page), `backups/`,
`img/`, `logs/`, the root scripts, and the root config files.

## 1. Design

- **Simple and minimal beats capable.** Prefer the service that is cheap to set up,
  cheap to run, and light on RAM over the one that does more: `beszel` over `netdata`,
  `wg-easy` over a hand-rolled OVPN/iptables setup. When a lighter tool covers the
  need, switch to it and delete the heavier one.
- **Fewer moving parts per layer.** One `style` of setup across a stack, no parallel
  ways to do the same thing (no shell script *and* an ansible task doing one job).
  If a layer is only kept as a fallback, say so in its README.
- **Security over convenience.** Secrets never live in tracked files: node facts go
  in a tracked per-stack `docker/<stack>/.env`, secrets go in a gitignored one
  (`.gitignore` re-ignores `docker/monitoring/.env`). A credential that must survive a
  from-scratch redeploy is committed only as a one-way hash (`CODE_SERVER_HASHED_PASSWORD`
  is argon2), never as ciphertext keyed by something in the repo. Unattended system upgrades
  are the OS layer, not an ansible task. Every container gets `init: true` unless it
  shares the host PID namespace.
- **Images track upstream.** Every image carries an explicit `:latest`, never a pin
  and never a bare tag: upstream drift is accepted the way `apt upgrade` is accepted,
  and the monthly refresh repairs a bad release.
- **Anything that can drift should be a variable.** Hardcoded paths, ports, uids,
  package lists, and per-node facts belong in `group_vars`, a compose `.env`, or a
  `${VAR:-default}` in the compose file, not inside a task or a literal line. The
  names in use — `homelab_root`, `user`, `compose_stacks`, `docker_prune_filter`,
  `deploy_samba_share`, `config_syspkgs`, `backups_paths`, `HOMELAB_TZ`, `MEDIA_ROOT`,
  `WG_HOST` — are the names to reuse, not to duplicate.

## 2. Think long-term and extensible

One node today (`[master]`), a cluster later: a second node — e.g. the AMD BC250 box
running a different subset — is a new group in `ansible/hosts` and its own playbook
in this repo, not a new repo and not a playbook that branches.

- Node facts live in `group_vars`, not in roles: `ansible/group_vars/all.yml` for
  shared values, one file per group for per-node overrides. A role that hardcodes a
  path, a uid, or a host name cannot serve a second node.
- Keep roles small and composable; a per-node playbook opts into the roles it needs.
- One compose stack per service group (`docker/<stack>/docker-compose.yml`) so a node
  runs a subset; the stack names live in `ansible/group_vars/all.yml:compose_stacks`,
  not in a task.
- No single-host literals in shared files (`/home/<user>`, `/mnt/<disk>`, uid `1001`):
  name them (`homelab_root`, `deploy_samba_share`, `deploy_docker_subnet`) so the next
  node overrides a variable instead of editing the file.

## 3. Style — code and docs

- **Self-documenting first.** Descriptive names, small units, obvious structure:
  `docker_prune_filter`, `apt_cache_valid_time_installs`, `config_refresh_cadence`.
- **One-line comments**, only where the "why" is unreadable from the file itself: an
  unsafe or fragile contract, a vendor quirk, a marshalling rule, a non-obvious
  constant.
- **Allowed:** separator banners that delimit groups inside a file (`End of Arr
  configuration`), and commented-out options that record a knob this host does not
  use (`# - samba`, `# - 51821:51821/tcp`, `# OnUnitActiveSec=2weeks`). Keep them next
  to the live block they belong to; they are switchable settings, not dead code.
- **Not allowed:** prose about the code — narrated blocks, step-by-step narration,
  restating what the line already says, how-to instructions, references to other files.
- **Docs carry the narrative** and are scanned, not studied: short lines, plain
  wording, no storytelling about how a trick works. Long-form docs live on the GitHub
  wiki; in-repo docs are `README.md` and `backups/configs/README.md`. A doc states
  facts and rules, never the rationale for a setting — that lives with the setting.
- **No metatext.** Comments, docs, and commit messages state facts and rules, never
  commentary about decisions, plans, discoveries, or who found what. "planned",
  "not yet", "as discussed above", "the linter caught this" are metatext: delete the
  note, keep the fact it carries.
- A design note that would otherwise sit in a comment goes in a README; the code stays
  bare.

## 4. Layout

| Path | Role |
| --- | --- |
| `ansible/` | roles (`config`, `deploy`, `backups`), `hosts`, `group_vars/all.yml`, `requirements.yml` |
| `ansible/*.yml` | the entry playbooks: `software-deploy`, `os-config`, `refresh`, `backup` |
| `docker/<stack>/` | one compose stack per service group: `media`, `monitoring`, `networking`, `others`, `web` |
| `docker/<stack>/.env` | node facts for that stack, tracked; `docker/monitoring/.env` is gitignored |
| `docker/web/web/` | submodule → the `web` repo; the served tree is `site/`, mount that, never the checkout root |
| `backups/configs/` | saved node state (`configs-*.zip`) + its README |
| `lint.sh`, `setup.sh` | local mirror of CI; first-run bootstrap on a fresh node |
| `.yamllint`, `.ansible-lint`, `.ansible-lint-ignore`, `.yamlfmt`, `.gitattributes` | the linters' own configs, at the **repo root** (discovery is working-directory based — see §5) |
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
  CI | Submodules | Config | Scripts.
- Body optional, bullets-only, usually absent. Never narrate the process.
- Never `git push` unless explicitly asked; every other git operation is allowed.

## 7. Gotchas that will bite again

- `.gitignore` tracks the stack dirs, their `docker-compose.yml` and their `.env`, and
  ignores everything else inside them: a new stack's compose file is addable straight
  away, its state dirs stay untracked.
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

## 8. References

- `README.md` is the roadmap (its TODO lists) and the public description — update it
  when conventions or layout change.
- Long-form documentation lives on the GitHub wiki (hardware, OS, services, backups,
  ansible); there is no `ansible/README.md` or `docker/README.md`.
- `backups/configs/README.md` states what state is saved on the node and when.
- Update this file whenever a convention changes.
