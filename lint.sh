#!/bin/bash
#
# Title: lint.sh
# Author: Pelochus
# Version: 1.0
# Brief: Runs the same checks as .github/workflows/lint.yml, on the local box
#
# Usage:
#   ./lint.sh        checks everything and fails on the first problem
#   ./lint.sh fix    rewrites the YAML files in place with the formatter
#
# Install: yamllint and ansible-lint are Python packages (pip/uv or the
# ansible/ansible-lint GitHub Action), yamlfmt is a single Go binary from
# https://github.com/google/yamlfmt

set -e

cd "$(dirname "$0")"

for tool in ansible-lint yamllint yamlfmt; do
    if ! command -v "$tool" > /dev/null
    then
        echo "Missing tool: $tool - see the install note in this file"
        exit 1
    fi
done

# ansible-lint finds .ansible-lint at the repo root and derives the project
# root from it, so it has to run here, not inside ansible/
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
