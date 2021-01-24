#!/bin/bash
###
# File: setup.sh
# Project: 290-post_patching_systems
# File Created: Monday, 25th January 2021 12:40:35 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 12:43:01 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
#TODO:
#   - Change short hostname to IP address (compatibility with devices not able to reach by hostname)


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function patching_muximux_for_landing_page {
    # Update default docker-compose services
    _header "Patching muximux for landing page"

    file_to_patch="${PROJECT_PATH}/system_appdata/landing-page/www/muximux/muximux.php"
    patch_attempts=0
    patch_success=1
    while [ ${patch_attempts} -le 5 ]; do
        (( patch_attempts++ ))

        found_file=0

        _standalone_stage_header "Attempting No.${patch_attempts} to patch $(basename ${file_to_patch})"
        if [[ -e ${file_to_patch} ]]; then
            _stage_header "Hiding hamburger menu in $(basename ${file_to_patch})..."
            sed -i "s|'dd navbtn'|'dd navbtn hidden'|" ${file_to_patch} &>> ${SCRIPT_LOG_FILE}
            cmd_code=${?}
            _update_stage_header ${cmd_code}
            [[ ${cmd_code} -gt 0 ]] && patch_success=1
        else
            found_file=1
        fi
        
        # Break if this was a success
        [[ ${found_file} ]] && break
        sleep 1
    done

    watch_for_file="${PROJECT_PATH}/system_appdata/landing-page/www/muximux/settings.ini.php-example"
    patch_attempts=0
    patch_success=1
    while [ ${patch_attempts} -le 5 ]; do
        (( patch_attempts++ ))

        found_file=0

        _standalone_stage_header "Attempting No.${patch_attempts} to install settings.ini.php"
        if [[ -e ${watch_for_file} ]]; then
            _stage_header "Installing muximux settings file"
            install -m 666 ${script_path}/files/settings.ini.php ${PROJECT_PATH}/system_appdata/landing-page/www/muximux/settings.ini.php &>> ${SCRIPT_LOG_FILE}
            _update_stage_header ${?}

            _stage_header "Updating muximux settings with hostname"
            short_hostname=$(hostname -s)
            sed -i "s|://localhost|://${short_hostname,,}.local|" ${PROJECT_PATH}/system_appdata/landing-page/www/muximux/settings.ini.php &>> ${SCRIPT_LOG_FILE}
            _update_stage_header ${?}
        else
            found_file=1
        fi
        
        # Break if this was a success
        [[ ${found_file} ]] && break
        sleep 1
    done

    if [[ -e ${PROJECT_PATH}/system_appdata/landing-page ]]; then
        _stage_header "Setting muximux project file's ownership to default user"
        chown -R 1000:1000 ${PROJECT_PATH}/system_appdata/landing-page &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    echo
}


patching_muximux_for_landing_page
