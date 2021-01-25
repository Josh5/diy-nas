#!/bin/bash
###
# File: setup.sh
# Project: 220-project_docker_compose_stack
# File Created: Monday, 25th January 2021 3:49:00 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 5:03:14 pm
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

function configure_system_max_map_count {
    # Update default docker-compose services
    _header "Updating system VM max_map_count"

    _stage_header "Set the current session to '262144'"
    sysctl -w vm.max_map_count=262144 &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Add this config to /etc/sysctl.conf for all subsequent boots"
    if ! grep -q "^vm.max_map_count=" /etc/sysctl.conf; then
        echo "vm.max_map_count=262144" >> /etc/sysctl.conf
        echo "" >> /etc/sysctl.conf
    fi
    sed -i "s|^vm.max_map_count=.*$|vm.max_map_count=262144|" /etc/sysctl.conf &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}

function configure_system_overcommit_memory {
    # Update default docker-compose services
    _header "Updating system VM overcommit_memory"

    _stage_header "Set the current session to true"
    sysctl -w vm.overcommit_memory=1 &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Add this config to /etc/sysctl.conf for all subsequent boots"
    if ! grep -q "^vm.overcommit_memory=" /etc/sysctl.conf; then
        echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
        echo "" >> /etc/sysctl.conf
    fi
    sed -i "s|^vm.overcommit_memory=.*$|vm.overcommit_memory=1|" /etc/sysctl.conf &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}

function create_required_directory_structure {
    # Update default docker-compose services
    _header "Creating required directory strucuture for system Docker stack"

    _stage_header "Create elasticsearch directory"
    mkdir -p ${PROJECT_PATH}/system_appdata/elasticsearch/data &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Set correct ownership of elasticsearch directory"
    chown -R 1000:1000 ${PROJECT_PATH}/system_appdata/elasticsearch &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
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


configure_system_max_map_count
configure_system_overcommit_memory
create_required_directory_structure
update_project_system_docker_stack
