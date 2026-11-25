#!/usr/bin/env bash
# Same checks as .github/workflows/lint.yml, on the local box.
#
#   ./lint.sh             check everything, fail on the first problem
#   ./lint.sh fix         rewrite the YAML files in place
#   ./lint.sh markdown    the markdown checks only, they need no extra tool
#
# Tools: yamllint and ansible-lint (pip/uv, or the ansible GitHub Action),
# yamlfmt (https://github.com/google/yamlfmt)
# LINT_BIN holds the local tool dir when the tools are installed outside the repo.

set -euo pipefail

cd "$(dirname "$0")"

LINT_BIN=${LINT_BIN:-"$HOME/.cache/homelab-lint/bin"}
export LINT_BIN
export PATH="$LINT_BIN:$PATH"

# markdown rules: link text must not repeat the wiki-style prefix, and a relative
# link must resolve next to the page that carries it
check_markdown() {
    local file dir target status=0

    while IFS= read -r file
    do
        dir=$(dirname "$file")

        if grep -q '\[[^]]*\[[^]]*\](' "$file"
        then
            echo "$file: link text repeats the wiki-style prefix"
            status=1
        fi

        while IFS= read -r target
        do
            case "$target" in
                ''|'#'*) continue ;;
                http*) continue ;;
            esac
            if ! [ -e "$dir/$target" ]
            then
                echo "$file -> $target (relative link resolves to nothing)"
                status=1
            fi
        done < <(grep -o '](\([^)]*\))' "$file" 2> /dev/null | sed 's/](\(.*\))/\1/')
    done < <(git ls-files '*.md')

    return "$status"
}

if [ "${1:-}" = 'markdown' ]
then
    check_markdown
    exit $?
fi

for tool in ansible-lint yamllint yamlfmt
do
    if ! command -v "$tool" > /dev/null
    then
        echo "Missing tool: $tool - see the install note in this file"
        exit 1
    fi
done

# ansible-lint reads .ansible-lint from this directory, so it runs here, not inside ansible/
ansible-lint ansible

# yamllint reads .yamllint from the working directory
yamllint .

if [ "${1:-}" = 'fix' ]
then
    yamlfmt .
else
    yamlfmt -lint
fi

if command -v docker > /dev/null
then
    for compose in docker/*/docker-compose.yml
    do
        docker compose -f "$compose" config > /dev/null
    done
fi

check_markdown
