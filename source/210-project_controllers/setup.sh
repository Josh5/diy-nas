#!/bin/bash
###
# File: setup.sh
# Project: 210-project_controllers
# File Created: Monday, 25th January 2021 12:15:52 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 3:49:22 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function install_project_updater_script {
    # Install the project updater script
    _header "Installing project controller scripts"

    _stage_header "Installing 'diy-nas-update' script"
    install -m 755 ${script_path}/files/diy-nas-update /usr/local/bin/diy-nas-update &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Installing 'diy-nas-start' script"
    install -m 755 ${script_path}/files/diy-nas-start /usr/local/bin/diy-nas-start &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Installing 'diy-nas-stop' script"
    install -m 755 ${script_path}/files/diy-nas-stop /usr/local/bin/diy-nas-stop &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}


install_project_updater_script
