#!/bin/bash
###
# File: setup.sh
# Project: 040-docker
# File Created: Monday, 25th January 2021 12:02:47 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 12:03:26 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function install_docker {
    # Ensure Docker is installed
    _header "Ensuring Docker is installed"
    if ! `command -v docker &> /dev/null`; then
        _stage_header "Installing package(s) [docker-ce]"
        curl https://get.docker.com | sh &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
        _stage_header "Starting Docker daemon"
        systemctl restart docker &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    else
        _standalone_stage_header "Docker already installed"
    fi
    # Ensure default user is in docker group
    default_username=$(getent passwd | grep 1000 | cut -d: -f1)
    if ! id -a 1000 | grep '(docker)' &> /dev/null; then
        _stage_header "Adding default user '${default_username}' to 'docker' group"
        usermod -aG docker ${default_username} &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    echo
}

function install_docker_compose {
    # Install Docker-compose
    _header "Ensuring Docker-compose is installed"

    # Ensure pip3 is installed...
    if ! `command -v pip3 &> /dev/null`; then
        _stage_header "Installing package(s) [python3-pip]"
        apt-get install -y python3-pip &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    
    # Install docker-compose
    if ! `command -v docker-compose &> /dev/null`; then
        _stage_header "Installing package(s) [docker-compose]"
        pip3 install --no-cache-dir docker-compose &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    else
        _stage_header "Checking for upgrade of package(s) [docker-compose]"
        pip3 install --no-cache-dir --upgrade docker-compose &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    # Add default user ID and default group ID to environment
    grep -q "PUID=1000" /etc/environment 2> /dev/null || echo "PUID=1000" >> /etc/environment
    grep -q "PGID=1000" /etc/environment 2> /dev/null || echo "PGID=1000" >> /etc/environment
    echo
}


install_docker
install_docker_compose
