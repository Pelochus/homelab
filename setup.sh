#!/usr/bin/env bash
#
# Title: setup.sh
# Author: Pelochus
# Version: 1.0
# Brief: Entry point for the Ansible playbooks that build the homelab.
#        OS upgrades are unattended, so this script never reboots the host.

repo_dir="$(dirname "$(readlink -f "$0")")"
playbooks_dir="$repo_dir/ansible"

#############
### Functions
#############

usage() {
    echo
    echo "pelochus/homelab setup"
    echo
    echo "  ./setup.sh              interactive menu"
    echo "  ./setup.sh -a | --auto  configure the OS, then deploy software"
    echo "  ./setup.sh --refresh    pull Docker images and restart what changed"
    echo "  ./setup.sh -h | --help  this help"
    echo
    echo "Playbooks are idempotent and safe to re-run."
}

run_playbook() {
    local playbook="$1"
    echo "--> ansible-playbook $playbook"
    ansible-playbook -K "$playbook"
}

########
### Main
########

if ! command -v ansible-playbook >/dev/null; then
    echo "Ansible is not installed; installing it now."
    sudo apt install ansible -y
fi

cd "$playbooks_dir" || exit 1

case "${1:-}" in
    -h|--help)
        usage
        ;;
    -a|--auto)
        run_playbook os-config.yml
        run_playbook software-deploy.yml
        ;;
    --refresh)
        run_playbook refresh.yml
        ;;
    "")
        while true; do
            echo
            echo "  [1] Configure OS"
            echo "  [2] Deploy software"
            echo "  [3] Refresh Docker images"
            echo "  [4] Run backups (stub role)"
            echo "  [5] Quit"
            echo
            read -r -p "Choose: " choice
            case "$choice" in
                1) run_playbook os-config.yml ;;
                2) run_playbook software-deploy.yml ;;
                3) run_playbook refresh.yml ;;
                4) run_playbook backup.yml ;;
                5) break ;;
                *) echo "Not a choice." ;;
            esac
        done
        ;;
    *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
esac
