#!/bin/bash
###
# File: setup.sh
# Project: 070-cockpit
# File Created: Monday, 25th January 2021 12:08:39 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 12:11:48 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function install_cockpit {
    # Ensure Cockpit is installed
    _header "Ensuring Cockpit is installed"

    if ! `dpkg -la | grep cockpit &> /dev/null`; then
        _stage_header "Installing package(s) [cockpit]"
        apt-get install -y cockpit &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    else
        _standalone_stage_header "Cockpit already installed"
    fi

    #  # Install cockpit docker [MAYBE...]
    #  mkdir -p /opt/cockpit
    #  if [[ ! -e /opt/cockpit/cockpit-docker_215-1~ubuntu19.10.1_all.deb ]]; then
    #      wget -o /dev/null \
    #          -O /opt/cockpit/cockpit-docker_215-1~ubuntu19.10.1_all.deb \
    #          https://launchpad.net/ubuntu/+source/cockpit/215-1~ubuntu19.10.1/+build/18889196/+files/cockpit-docker_215-1~ubuntu19.10.1_all.deb
    #  fi
    #  `dpkg -la | grep cockpit-docker &> /dev/null` || apt-get install -y /opt/cockpit/cockpit-docker_215-1~ubuntu19.10.1_all.deb

    _stage_header "Installing Cockpit config"
    mkdir -p /etc/cockpit &>> ${SCRIPT_LOG_FILE}
    install -m 644 ${script_path}/files/cockpit.conf /etc/cockpit/cockpit.conf
    _update_stage_header ${?}

    _stage_header "Restarting cockpit server"
    systemctl restart cockpit
    _update_stage_header ${?}

    echo
}


install_cockpit
