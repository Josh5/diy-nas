#!/bin/bash
###
# File: setup.sh
# Project: 010-default_config
# File Created: Sunday, 24th January 2021 11:31:37 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 24th January 2021 11:56:03 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# TODO:
#   - fix issue with restoring UUIDs


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function install_default_config {
    # Install default config file if does not exist
    if [[ ! -e ${PROJECT_PATH}/config/config.env ]]; then
        _header "Installing default user config"

        _stage_header "Copy default config.env file"
        cp ${script_path}/files/config.env ${PROJECT_PATH}/config/config.env
        _update_stage_header ${?}

        _stage_header "Setting user setting 'TIMEZONE=$(cat /etc/timezone)'"
        sed -i "s|TIMEZONE=.*$|TIMEZONE=$(cat /etc/timezone)|" ${PROJECT_PATH}/config/config.env
        _update_stage_header ${?}
    else
        _header "Updating user config"
        # Source the current user config
        source ${PROJECT_PATH}/config/config.env
        # Copy default config replacing current user config
        # Update variables in the user config with what was source above
        for var in $(compgen -v); do
            if `grep -q "${var}=" ${PROJECT_PATH}/config/config.env`; then
                _stage_header "Resetting user setting '${var}=${!var}'"
                sed -i "s|${var}=.*$|${var}=${!var}|" ${PROJECT_PATH}/config/config.env &>> ${SCRIPT_LOG_FILE}
                _update_stage_header ${?}
            fi
        done
    fi
    chmod a+rw ${PROJECT_PATH}/config/config.env
    echo
}


install_default_config
