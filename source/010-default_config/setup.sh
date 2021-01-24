#!/bin/bash
###
# File: setup.sh
# Project: 010-default_config
# File Created: Sunday, 24th January 2021 11:31:37 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 3:02:18 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


_config_vars=(
    "TIMEZONE"
    "CACHE_DISK_PART1_UUID"
    "CACHE_DISK_PART2_UUID"
)
_config_arrays=(
    "DISK_UUID_BLACKLIST"
)

function _add_config_variable {
    _variable="${@}"
    if `grep -q "^${_variable}=" ${PROJECT_PATH}/config/config.env`; then
        _stage_header "Resetting user setting '${_variable}=${!_variable}'"
        sed -i "s|^${var}=.*$|${var}=${!var}|" ${PROJECT_PATH}/config/config.env &>> ${SCRIPT_LOG_FILE}
        echo "${_variable}=${!_variable}" &> /dev/null
        _update_stage_header ${?}
        echo "${_variable[1]}"
    fi
}

function _add_config_array {
    _array=$@[@]
    if `grep -q "^${@}=" ${PROJECT_PATH}/config/config.env`; then

        _string="${@}=( \n"
        for value in "${!_array}"; do 
            _string="${_string}    \"${value}\"\n"
        done
        _string="${_string})\n"

        _stage_header "Resetting user setting array '${@}'"
        sed -i "s|^${@}=.*$|${_string}|" ${PROJECT_PATH}/config/config.env &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
}

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
        _stage_header "Copy default config.env file"
        cp ${script_path}/files/config.env ${PROJECT_PATH}/config/config.env
        _update_stage_header ${?}

        # Update variables in the user config with what was sourced above
        for var in ${_config_vars[@]}; do
            _add_config_variable "${var}"
        done

        # Update config arrays in the user config with what was sourced above
        for var in ${_config_arrays[@]}; do
            _add_config_array "${var}"
        done
    fi
    chmod a+rw ${PROJECT_PATH}/config/config.env
    echo
}


install_default_config
