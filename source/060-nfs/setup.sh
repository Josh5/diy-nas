#!/bin/bash
###
# File: setup.sh
# Project: 060-nfs
# File Created: Monday, 25th January 2021 12:07:32 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 12:09:15 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function install_nfs {
    # Ensure NFS server is installed
    _header "Ensuring NFS server is installed"

    if ! `dpkg -la | grep ' nfs-kernel-server ' &> /dev/null`; then
        _stage_header "Installing package(s) [nfs-kernel-server]"
        apt-get install -y nfs-kernel-server &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    if [[ ! -e /etc/exports.original ]]; then
        _stage_header "Backup original NFS exports config"
        cp /etc/exports /etc/exports.original &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    _stage_header "Installing NFS config"
    install -m 644 ${script_path}/files/exports /etc/exports
    _update_stage_header ${?}

    _stage_header "Reloading NFS exports"
    exportfs -ra
    _update_stage_header ${?}

    _stage_header "Restarting NFS server"
    systemctl restart nfs-kernel-server
    _update_stage_header ${?}
    
    echo
}


install_nfs
