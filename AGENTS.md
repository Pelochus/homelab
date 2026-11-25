# AGENTS.md — rules for this repository

Scope: the whole repo — `ansible/` (deploy automation), `docker/` (one compose stack
per service group), `docker/web/web` (submodule of the personal page), `backups/`,
`img/`, `logs/`, the root scripts, and the root config files.

Read [the repo README](README.md) for the public description and the TODO roadmap, and
[the docs index](docs/README.md) for the long-form pages (hardware, OS, software,
backups, Ansible, Docker, first-time setup).

## 1. Design

- **Simple and minimal beats capable.** Prefer what is cheap to set up, cheap to run
  and light on RAM over what does more. When a lighter tool covers the need, switch to it
  and delete the heavier one.
- **One way to do a thing per layer.** No shell script *and* an ansible task for one
  job. A layer kept only as a fallback says so in its README.
- **Security over convenience**, as defaults:
  - Secrets never live in tracked files: node facts go in the tracked `docker/<stack>/.env`,
    secrets in the gitignored `docker/<stack>/.secrets.env`.
  - A credential that must survive a from-scratch redeploy is committed as a one-way
    hash, never as ciphertext keyed by something in the repo.
  - Work that the OS already does unattended stays with the OS, not in an automation task.
- **Rules are defaults, not a contract.** When one fights a case, break it and say why
  at the place it breaks — a one-line comment, or the README. A short note that carries a
  fact (a vendor quirk, a chosen value, why a layer is only a fallback) is worth keeping.
- **Anything that can drift is a variable** — paths, ports, ids, lists and per-node
  facts go in the shared config file for their layer or in a `${VAR:-default}`, not
  inside a task or a literal line. Reuse a name that already exists (`homelab_root`,
  `user`, `compose_stacks`) before adding a near-duplicate.
- **A rule that belongs to one layer lives on that layer's page, not here.** This file
  states the guidelines; `docs/` carries the facts about a stack, a package or a
  vendor quirk.

## 2. Think long-term and extensible

One node today, a cluster later: a second node is a new group in the inventory with
its own playbook in this repo, not a new repo and not a playbook that branches.

- Node facts live in the inventory's group files, not in code: one file for shared
  values, one per group for overrides. Code that hardcodes a path, an id or a host
  name cannot serve a second node.
- Keep roles small and composable; a per-node playbook opts into the roles it needs.
- One deployable unit per service group, so a node runs a subset; the list of groups
  lives in a shared config file, not in a task.
- No single-host literals in shared files (`/home/<user>`, a mount point, an id):
  name them so the next node overrides a variable instead of editing the file.

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
  points at [the docs index](docs/README.md) — the index page itself is the exception.

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
| `.githooks/pre-commit` | the commit gate: `./lint.sh` when its tools resolve; the markdown checks in it run either way |
| `.yamllint`, `.ansible-lint`, `.ansible-lint-ignore`, `.gitattributes` | the linters' own configs, at the **repo root** (discovery is working-directory based — see §5) |
| `img/`, `logs/` | screenshots and saved logs (`logs/` gitignored) |

## 5. Verification

- Run `./lint.sh` (or CI's `.github/workflows/lint.yml`) before committing YAML/Ansible
  changes; it must exit 0.
- `.githooks/pre-commit` is the gate: it runs `./lint.sh` only when all three linters
  resolve — from `LINT_BIN` (`~/.cache/homelab-lint/bin` by default, override it) — and
  says so when one is missing, because a run with a silent tool proves nothing. The
  markdown checks (link text doubled into a wiki-style prefix, relative links that resolve
  to nothing) run either way: they need no extra tool.
- `core.hooksPath = .githooks` is relative to the repo root; `setup.sh` sets it, a
  manual clone sets it with `git config core.hooksPath .githooks`.
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

## 7. Git and ignore rules that bite

- `.gitignore` tracks the stack dirs, their `docker-compose.yml` and their `.env`, and
  ignores everything else inside them, `docker/*/.secrets.env` included: a new stack's
  compose file is addable straight away, its state dirs stay untracked.
- `logs/`, `.pi/`, `.cache/`, `.ansible/` are ignored; do not re-add generated state.
- `git submodule update` checks out the **pinned** sha, and the pin follows `main` only
  when moved deliberately: pushing the `web` repo never reaches the node by itself.

## 8. Docs and references

- [Repo README](README.md): public description and the TODO roadmap — update it when
  conventions or layout change.
- [docs/README.md](docs/README.md): index of the long-form pages — hardware, OS,
  software, backups, Ansible, Docker, first-time setup. It links every page; pages link
  back to it under `## Related`. There is no `ansible/README.md` or `docker/README.md`.
- [Backups README](backups/configs/README.md): what state is saved on the node and when.
- Update this file whenever a convention changes.
