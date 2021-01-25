#!/bin/bash
###
# File: setup.sh
# Project: 220-project_docker_compose_stack
# File Created: Monday, 25th January 2021 3:49:00 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 4:01:43 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function _compare_compose_files {

    if [[ ! -e ${PROJECT_PATH}/docker-compose.yml ]]; then
        return 1
    fi

    current=$(md5sum -- ${PROJECT_PATH}/docker-compose.yml | awk '{print $1}')
    latest=$(md5sum -- ${script_path}/files/docker-compose.yml | awk '{print $1}')

    if [[ ${current} != ${latest} ]]; then
        return 1
    fi

    return 0
}

function update_project_system_docker_stack {
    # Update default docker-compose services
    _header "Updating system Docker stack"

    if [[ -e ${PROJECT_PATH}/docker-compose.yml ]]; then
        if ! _compare_compose_files; then
            # Files are different
            # Bring down current containers (removes issues with port conflicts between old version and new and forces refresh)
            _stage_header "Bringing down system Docker containers"
            docker-compose -f ${PROJECT_PATH}/docker-compose.yml --env-file ${PROJECT_PATH}/config/config.env down &>> ${SCRIPT_LOG_FILE}
            _update_stage_header ${?}
        fi
    fi
    
    if ! _compare_compose_files; then
        # Install new compose file if it different or does not yet exist
        _stage_header "Installing latest compose file"
        install -m 755 ${script_path}/files/docker-compose.yml ${PROJECT_PATH}/docker-compose.yml &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    # Pull updates
    _stage_header "Pulling updates for system Docker images"
    docker-compose -f ${PROJECT_PATH}/docker-compose.yml --env-file ${PROJECT_PATH}/config/config.env pull &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    # Bring up containers
    _stage_header "Bringing up system Docker containers"
    docker-compose -f ${PROJECT_PATH}/docker-compose.yml --env-file ${PROJECT_PATH}/config/config.env up --remove-orphans -d &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}


update_project_system_docker_stack
