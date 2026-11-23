#!/usr/bin/env bash
# Writes the gitignored docker/<stack>/.secrets.env; an existing file is never rewritten,
# a rotated secret invalidates what the service already encrypted. Delete it to regenerate.
# code-server's argon2 hash stays tracked in docker/others/.env.

set -euo pipefail

repo_dir="$(dirname "$(readlink -f "$0")")"
cd "$repo_dir"

command -v openssl >/dev/null 2>&1 || {
    echo "openssl generates the secrets; install it first." >&2
    exit 1
}

stacks=(monitoring)

for stack in "${stacks[@]}"; do
    file="docker/$stack/.secrets.env"

    if [ -e "$file" ]; then
        echo "keep  $file"
        continue
    fi

    # a partial write must not pass the -e check above
    tmp="$file.tmp"
    case "$stack" in
        monitoring)
            cat >"$tmp" <<EOF
# Homarr encrypts its database with this key
SECRET_ENCRYPTION_KEY=$(openssl rand -hex 32)
# Beszel issues both: TOKEN under Settings -> tokens, KEY the hub's SSH public key
# TOKEN=
# KEY=
EOF
            ;;
        *)
            echo "no secrets defined for $stack"
            continue
            ;;
    esac

    chmod 600 "$tmp"
    mv "$tmp" "$file"
    echo "new   $file"
done
