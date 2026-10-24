0#!/bin/bash
#
# Title: setup.sh
# Author: Pelochus
# Version: 1.0
# Brief: Configures my personal homelab calling Ansible playbooks

#############
### Functions
#############

menu() {
    echo "-------------------------------------------------------------------------------------------------"
    echo
    echo "  ### MENU - Choose an option"
    echo
    echo "  [1] Do everything"
    echo "  [2] Config OS"
    echo "  [3] Deploy Software"
    echo "  [4] Exit"
    echo
    echo "-------------------------------------------------------------------------------------------------"
}

options() {
    case $1 in
    
        # Do something
        2 | 1)
            ansible-playbook -K os-config.yml
        ;;&
        # This "&" makes it possible to execute following options

        # Do something 2
        3 | 1)
            ansible-playbook -K software-deploy.yml
        ;;

        # Exit
        4)
            echo
            echo "-----------"
            echo "Exiting now"
            echo "-----------"
            echo
            exit
        ;;

    esac
}

########
### Main
########

clear

# Run with parameters
if [ $# -gt 0 ]
then
    if [ $1 == '-h' ] || [ $1 == '--help' ]
    then
        echo
        echo "pelochus/homelab Template Script Help"
        echo
        echo "-a / --auto: Runs all options that don't require user's help. Needs root privileges"
        echo "-h / --help: Shows this help screen"
        echo
        echo "For more information visit https://github.com/Pelochus/homelab"
        echo
        exit
    elif [ $1 == '-a' ] || [ $1 == '--auto' ]
    then
        options 1
        echo
        echo "//////////////////////////////"
        echo "Finished automatic deployment!"
        echo "//////////////////////////////"
        echo
        exit
    fi
fi

echo
echo "-------------------------------------------------------------------------------------"
echo "This script calls the Ansible playbooks responsible for deploying the homelab"
echo "You should not need to run this as sudo, but it will ask the sudo password"
echo "Continue? [Y/N]"
echo "-------------------------------------------------------------------------------------"
echo

read continue

if [ $continue == 'Y' ] || [ $continue == 'y' ]
then
    clear

    echo "-----------------------------------"
    echo "Checking if Ansible is installed..."
    echo "-----------------------------------"
    apt install ansible -y

    clear
    cd ansible

    while true
    do
        menu
        read chosen
        options $chosen
    done
else
    echo
    echo "-----------"
    echo "Exiting now"
    echo "-----------"
    echo
fi
