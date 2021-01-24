#!/bin/bash
###
# File: setup.sh
# Project: 090-main_proxy
# File Created: Monday, 25th January 2021 2:32:59 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 2:46:53 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function installing_main_proxy_config {
    # Update default docker-compose services
    _header "Configure main proxy"

    _stage_header "Installing main proxy config"
    mkdir -p ${PROJECT_PATH}/system_appdata/main-proxy/nginx/site-confs
    install -m 664 ${script_path}/files/default ${PROJECT_PATH}/system_appdata/main-proxy/nginx/site-confs/default &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Updating main proxy config with hostname/IP"
    ip_address=$(hostname -I | cut -d' ' -f1)
    sed -i "s|://localhost|://${ip_address}|" ${PROJECT_PATH}/system_appdata/main-proxy/nginx/site-confs/default &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    if docker ps | grep main-proxy &> /dev/null; then
        # The proxy is running, restart it...
        _stage_header "Restarting the main proxy Docker container"
        docker restart main-proxy &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
}


installing_main_proxy_config
