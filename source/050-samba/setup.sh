#!/bin/bash
###
# File: setup.sh
# Project: 050-samba
# File Created: Monday, 25th January 2021 12:04:48 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 12:09:05 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function install_samba {
    # Ensure Samba server is installed
    _header "Ensuring Samba server is installed"

    if ! `dpkg -la | grep ' samba ' &> /dev/null`; then
        _stage_header "Installing package(s) [samba]"
        apt-get install -y samba &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    mkdir -p /etc/samba &>> ${SCRIPT_LOG_FILE}
    if [[ ! -e /etc/samba/smb.conf.original ]]; then
        _stage_header "Backup original Samba config"
        cp /etc/samba/smb.conf /etc/samba/smb.conf.original &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    _stage_header "Installing Samba config"
    install -m 644 ${script_path}/files/smb.conf /etc/samba/smb.conf
    _update_stage_header ${?}

    _stage_header "Allow Samba in firewall rules"
    ufw allow samba &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Restarting Samba server"
    systemctl restart smbd.service nmbd.service &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}


install_samba
