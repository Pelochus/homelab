# AGENTS.md — rules for this repository

Scope: the whole repo — `ansible/` (the deploy automation), `docker/` (one
compose stack per service group), `docker/web/web` (submodule of the personal page),
`backups/`, `img/`, `logs/`, the two root scripts, and the root config files.

## 1. Design

- **Simple and minimal beats capable.** Prefer the service that is cheap to set
  up, cheap to run, and light on RAM over the one that does more: `beszel` over
  `netdata`, `wg-easy` over a hand-rolled OVPN/iptables setup. When a lighter tool
  covers the need, switch to it and delete the heavier one.
- **Fewer moving parts per layer.** One `style` of setup across a stack, no
  parallel ways to do the same thing (no shell script *and* an ansible task doing
  one job). If a layer is only kept as a fallback, say so in its README.
- **Security over convenience.** Secrets never live in tracked files: a stack that
  needs one reads a gitignored `.env`. Unattended system upgrades are the OS layer,
  not an ansible task. Every container gets `init: true` unless it shares the host
  PID namespace.
- **Images track upstream.** Every image carries an explicit `:latest`, never a pin
  and never a bare tag: upstream drift is accepted the way `apt upgrade` is accepted,
  and the monthly refresh repairs a bad release.
- **Anything that can drift should be a variable.** Hardcoded paths, ports, uids,
  package lists, and per-node facts belong in `group_vars`, a compose `.env`, or a
  `${VAR:-default}` in the compose file, not inside a task or a literal line. The
  names already in use — `homelab_root`, `user`, `compose_stacks`,
  `docker_prune_filter`, `deploy_samba_share`, `config_syspkgs`, `backups_paths`,
  `HOMELAB_TZ`, `MEDIA_ROOT`, `WG_HOST` — are the pattern to follow, not examples to
  invent.

## 2. Think long-term and extensible

This repo describes one node today and is expected to grow into a cluster (a
second node, e.g. the AMD BC250 box, running a different subset). So:

- Put node facts in `group_vars`, not in roles: `ansible/group_vars/all.yml` for
  shared values, a file per group for per-node overrides. A role that hardcodes a
  path, a uid, or a host name cannot serve a second node.
- Group hosts by capability (`ansible/hosts` — today one group, `[master]`, with
  `localhost`; a second node is a new group, not a new repo), keep roles small and
  composable, and let a per-node playbook opt into the roles it needs — the cluster
  plan is "same repo, different playbook per node", not "one playbook that branches".
- Keep compose stacks separate per service group (`docker/<stack>/docker-compose.yml`) so
  a node can run a subset, and keep the stack names in
  `ansible/group_vars/all.yml:compose_stacks` rather than listing dirs in a task.
- Do not bake single-host assumptions into shared files (`/home/<user>`,
  `/mnt/<disk>`, uid `1001`): name them (`homelab_root`, `deploy_samba_share`,
  `deploy_docker_subnet`) so the next node overrides a variable instead of editing the
  file.

## 3. Style — code and docs

- **Self-documenting first.** Descriptive names, small units, obvious structure.
  `docker_prune_filter`, `apt_cache_valid_time_installs`, `config_refresh_cadence`.
- **Minimal comments** in code, config, YAML, and templates: one line, only where
  the "why" is unreadable from the file itself — an unsafe/fragile contract, a
  vendor quirk, an ABI/marshalling rule, a non-obvious constant.
- **Allowed:** separator banners that delimit groups inside a file (`End of Arr
  configuration`), and commented-out options that record a knob this host does not
  use (`# - samba`, `# - 51821:51821/tcp`, `# OnUnitActiveSec=2weeks`). Keep them next
  to the live block they belong to; they are switchable settings, not dead code.
- **Not allowed:** sentences about the code — narrated blocks, step-by-step narration,
  restating what the line already says. The reason belongs in a doc, the setting stays
  in code.
- **Docs carry the narrative**, and they are scanned, not studied: short lines,
  plain wording, no storytelling about how a trick works. Long-form docs live on the
  GitHub wiki; in-repo docs are `README.md` and `backups/configs/README.md`. Neither
  states a rationale — the rule belongs in code, the reason belongs in a doc.
- **No metatext.** Comments, docs, and commit messages state facts and rules, never
  commentary about decisions, plans, discoveries, or who found what. A note that reads
  "planned", "not yet", "as discussed above", "the linter caught this" is metatext: delete
  it and put the fact it carries somewhere checkable.
- When a comment would explain design, move it to the README and keep the code bare.

## 4. Layout

| Path | Role |
| --- | --- |
| `ansible/` | roles (`config`, `deploy`, `backups`), `hosts`, `group_vars/all.yml`, `requirements.yml` |
| `ansible/*.yml` | the entry playbooks: `software-deploy`, `os-config`, `refresh`, `backup` |
| `docker/<stack>/` | one compose stack per service group: `media`, `monitoring`, `networking`, `others`, `web` |
| `docker/web/web/` | submodule → the `web` repo; the served tree is `site/`, mount that, never the checkout root |
| `backups/configs/` | saved node state (`configs-*.zip`) + its README |
| `lint.sh`, `setup.sh` | local mirror of CI; first-run bootstrap on a fresh node |
| `.yamllint`, `.ansible-lint`, `.ansible-lint-ignore`, `.yamlfmt`, `.gitattributes` | the linters' own configs, at the **repo root** (discovery is working-directory based — see §5) |
| `img/`, `logs/` | screenshots and saved logs (both gitignored except `img/`) |

## 5. Verification

- Run `./lint.sh` (or CI's `.github/workflows/lint.yml`) before committing YAML/Ansible
  changes; it must exit 0.
- ansible-lint reads `.ansible-lint` and `.ansible-lint-ignore` from the **current
  directory**, so run it from the repo root (`ansible-lint ansible`). Running it inside
  `ansible/` silently uses the default ruleset — a green run there proves nothing.
- This host has no `ansible`, `ansible-lint`, or `yamllint`; install them outside the
  repo, never as repo dependencies. `docker compose config` runs here, but nothing
  deploys and no container starts here: playbook behaviour and container runtime are
  **not** verifiable on this machine. Never claim a deploy or a container was verified.
- Keep linter configs and the ignore file in sync with the code: an entry in
  `.ansible-lint-ignore` is a deliberate skip, so name the file and rule, and revisit
  it instead of letting skips accumulate.

## 6. Commits

- Scope a commit to one logical block; never one commit per micro-task.
- **Amend and squash when applicable**, and that is the default for small follow-ups:
  a minor fix to something in a very recent commit folds into that commit
  (`git commit --amend`, or `git reset --soft <parent>` + one commit for a run at the
  tip). Do not leave a trail of "fix", "typo", "also" commits.
- Subject: imperative, `Area: what changed`, `Area` one of Ansible | Docker | Docs |
  CI | Submodules | Config | Scripts. Say what changed, in as few words as fit.
- Body is optional, bullets-only, and usually absent. Never narrate the process.
- Never `git push` unless explicitly asked; every other git operation is allowed.

## 7. Gotchas that will bite again

- `.gitignore` keeps the stack dirs and their compose files and ignores everything
  inside them, so a new stack's `docker-compose.yml` is addable straight away while
  its state dirs stay untracked.
- `logs/` and `.pi/`, `.cache/`, `.ansible/` are ignored on purpose; do not re-add
  generated state.
- Submodule pins follow `main` only when moved deliberately; `git submodule update`
  checks out the **pinned** sha, so a push to the `web` repo never reaches the node
  by itself.
- `ansible-lint` requires role-level vars to carry the role prefix (`deploy_*`,
  `backups_*`, `config_*`); global vars in `group_vars/all.yml` do not.
- systemd units need absolute executables (`/usr/bin/ansible-playbook`, not a bare
  name), and `docker_compose_v2` with `pull: always` always reports a change — that
  is the monthly-refresh timer's intent, not a bug.
- A container with `network_mode: host` or `pid: host` sits outside the `homelab`
  network and cannot resolve any `10.0.1.x` peer: it reaches siblings through a
  shared volume or the public URL (`beszel-agent`, `BESZEL_URL`, `beszel.sock`).

## 8. References

- `README.md` is the roadmap (its TODO list) and the public description — keep it
  honest, update it when conventions or layout change.
- Long-form documentation lives on the GitHub wiki (hardware, OS, services, backups,
  ansible) — there is no `ansible/README.md` or `docker/README.md`, the wiki replaced
  them.
- `backups/configs/README.md` states what state is saved on the node and when.
- Update this file whenever a convention changes; it is the contract, not a note.
