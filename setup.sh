#!/usr/bin/env bash
# Entry point for the Ansible playbooks that build the homelab.
# OS upgrades are unattended: this script never reboots the host.

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

run_playbooks() {
    echo "--> ansible-playbook $*"
    ansible-playbook -K "$@"
}

########
### Main
########

if ! command -v ansible-playbook >/dev/null; then
    echo "Ansible is not installed; installing it now."
    sudo apt install ansible -y
fi

if ! ansible-galaxy collection list 2>/dev/null | grep -q 'community\.docker'; then
    echo "Installing the Ansible collections this repo needs."
    ansible-galaxy collection install -r "$playbooks_dir/requirements.yml"
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
        run_playbook docker-refresh.yml
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
                1) run_playbooks os-config.yml ;;
                2) run_playbooks software-deploy.yml ;;
                3) run_playbooks docker-refresh.yml ;;
                4) run_playbooks backup.yml ;;
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
