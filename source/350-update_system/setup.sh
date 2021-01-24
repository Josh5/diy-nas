#!/bin/bash
###
# File: setup.sh
# Project: 350-update_system
# File Created: Monday, 25th January 2021 12:17:55 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 12:39:24 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function update_system_packages {
    # Update all system packages
    _header "Updating all system packages"

    _stage_header "Fetching latest package lists"
    apt-get update &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Upgrading packages"
    apt-get upgrade -y &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Removing old packages"
    apt-get autoremove -y &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}


update_system_packages
