#!/bin/bash
###
# File: setup.sh
# Project: 020-mergerfs_diskmount_process
# File Created: Sunday, 24th January 2021 11:55:33 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 24th January 2021 11:59:56 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function install_mount_script {
    # Install the mount script
    _header "Installing mount scripts"
    _stage_header "Installing 'disk-mount' script"
    install -m 755 ${script_path}/files/disk-mount /usr/local/bin/disk-mount &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    echo
}

function install_systemd_unit {
    # Install systemd unit
    _header "Installing systemd unit"
    _stage_header "Installing 'disk-mount@.service' unit"
    install -m 644 ${script_path}/files/disk-mount@.service /etc/systemd/system/disk-mount@.service &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    _stage_header "Reloading systemd units"
    systemctl daemon-reload &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    echo
}

function install_udev_rules {
    # Install the UDEV rules
    _header "Installing UDEV rules"
    _stage_header "Installing '99-media-automount.rules' UDEV rules"
    install -m 664 ${script_path}/files/99-media-automount.rules /etc/udev/rules.d/99-media-automount.rules &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    _stage_header "Reloading UDEV rules"
    udevadm control --reload-rules &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    echo
}

function install_mergerfs {
    # Install mergerfs
    _header "Ensuring MergerFS is installed"
    apt_mergerfs_install_list=""
    `command -v mergerfs &> /dev/null` || apt_mergerfs_install_list="${apt_mergerfs_install_list} mergerfs"
    `command -v fusermount &> /dev/null` || apt_mergerfs_install_list="${apt_mergerfs_install_list} fuse"
    `command -v xattr &> /dev/null` || apt_mergerfs_install_list="${apt_mergerfs_install_list} xattr"
    if [[ ! -z ${apt_mergerfs_install_list} ]]; then
        _stage_header "Installing package(s) [${apt_mergerfs_install_list} ]"
        apt-get install -y ${apt_mergerfs_install_list} &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    else
        _standalone_stage_header "MergerFS already installed"
    fi
    echo
}

install_mount_script
install_systemd_unit
install_udev_rules
install_mergerfs
