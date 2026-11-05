#!/bin/bash
# Same checks as .github/workflows/lint.yml, on the local box.
#
#   ./lint.sh        check everything, fail on the first problem
#   ./lint.sh fix    rewrite the YAML files in place
#
# Tools: yamllint and ansible-lint (pip/uv, or the ansible GitHub Action),
# yamlfmt (https://github.com/google/yamlfmt)

set -e

cd "$(dirname "$0")"

for tool in ansible-lint yamllint yamlfmt; do
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
