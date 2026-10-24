#!/bin/bash

# Variables
DATE=$(date +"%Y-%m-%d_%H-%M") # Everything but seconds
BASE_DIR="/home/pelochus/homelab"
LOG_DIR="${BASE_DIR}/logs"
LOG_FILE="${LOG_DIR}/maintenance-${DATE}.log"
PLAYBOOK_DIR="${BASE_DIR}/ansible"
PLAYBOOK="os-maintenance.yml"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

cd "$PLAYBOOK_DIR"
ansible-playbook "$PLAYBOOK" -i hosts &> "$LOG_FILE"

# So that if the script is run manually, we can stop before rebooting
echo "Rebooting in 10 seconds..."
sleep 10

reboot
