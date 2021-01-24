#!/bin/bash
###
# File: setup.sh
# Project: 210-project_updater
# File Created: Monday, 25th January 2021 12:15:52 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 12:47:30 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function install_project_updater_script {
    # Install the project updater script
    _header "Installing project updater scripts"
    _stage_header "Installing 'diy-nas-update' script"
    install -m 755 ${script_path}/files/diy-nas-update /usr/local/bin/diy-nas-update &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    echo
}

function update_project_system_docker_stack {
    # Update default docker-compose services
    _header "Updating system Docker stack"

    # Bring down containers (removes issues with port conflicts between old version and new and forces refresh)
    _stage_header "Bringing down system Docker images"
    docker-compose -f ${PROJECT_PATH}/docker-compose.yml --env-file ${PROJECT_PATH}/config/config.env down &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    # Pull updates
    _stage_header "Pulling updates for system Docker images"
    docker-compose -f ${PROJECT_PATH}/docker-compose.yml --env-file ${PROJECT_PATH}/config/config.env pull &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    # Bring up containers
    _stage_header "Bringing up system Docker images"
    docker-compose -f ${PROJECT_PATH}/docker-compose.yml --env-file ${PROJECT_PATH}/config/config.env up --remove-orphans -d &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}


install_project_updater_script
update_project_system_docker_stack
