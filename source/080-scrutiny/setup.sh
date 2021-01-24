#!/bin/bash
###
# File: setup.sh
# Project: 080-scrutiny
# File Created: Monday, 25th January 2021 12:12:44 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 12:36:40 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
#TODO:
#   - autostart unit on boot
#   - fix cron script (no user)


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


function install_scrutiny {
    # Ensure Scrutiny is installed
    _header "Installing Scrutiny"

    # Make install directory structure
    mkdir -p /opt/scrutiny/{config,web,bin,tmp}

    # Fetch the latest version of scrutiny
    _stage_header "Find the latest release of scrutiny"
    latest_scrutiny_version=$(_github_get_latest_release analogj/scrutiny)
    _update_stage_header ${?}

    _standalone_stage_header "Latest version of scrutiny is - ${latest_scrutiny_version}"

    scrutiny_web_server_url="https://github.com/AnalogJ/scrutiny/releases/download/${latest_scrutiny_version}/scrutiny-web-linux-amd64"
    scrutiny_web_frontend_url="https://github.com/AnalogJ/scrutiny/releases/download/${latest_scrutiny_version}/scrutiny-web-frontend.tar.gz"
    scrutiny_collector_url="https://github.com/AnalogJ/scrutiny/releases/download/${latest_scrutiny_version}/scrutiny-collector-metrics-linux-amd64"

    if [[ $(cat /opt/scrutiny/bin/scrutiny-web-linux-amd64-version.txt 2>/dev/null) == "${latest_scrutiny_version}" ]]; then
        _standalone_stage_header "The installed version of scrutiny web server is already the latest version"
    else
        # Download the latest version of scrutiny web server
        _stage_header "Downloading scrutiny-web-linux-amd64"
        wget -o /dev/null \
            -O /opt/scrutiny/bin/scrutiny-web-linux-amd64 \
            ${scrutiny_web_server_url}
        scrutiny_web_server_url_dl_result=${?}
        _update_stage_header ${scrutiny_web_server_url_dl_result}

        _stage_header "Make scrutiny-web-linux-amd64 executable"
        chmod +x /opt/scrutiny/bin/scrutiny-web-linux-amd64
        _update_stage_header ${?}

        if [[ ${scrutiny_web_server_url_dl_result} == 0 ]]; then
            echo "${latest_scrutiny_version}" > /opt/scrutiny/bin/scrutiny-web-linux-amd64-version.txt
        fi
    fi

    if [[ $(cat /opt/scrutiny/web/scrutiny-web-frontend-version.txt 2>/dev/null) == "${latest_scrutiny_version}" ]]; then
        _standalone_stage_header "The installed version of scrutiny web frontend is already the latest version"
    else
        # Download the latest version of scrutiny web frontend
        _stage_header "Downloading scrutiny-web-frontend"
        wget -o /dev/null \
            -O /opt/scrutiny/tmp/scrutiny-web-frontend.tar.gz \
            ${scrutiny_web_frontend_url}
        scrutiny_web_frontend_url_dl_result=${?}
        _update_stage_header ${scrutiny_web_frontend_url_dl_result}

        _stage_header "Extract scrutiny-web-frontend"
        pushd /opt/scrutiny/web &>> ${SCRIPT_LOG_FILE}
        tar xvzf /opt/scrutiny/tmp/scrutiny-web-frontend.tar.gz --strip-components 1 -C . &>> ${SCRIPT_LOG_FILE}
        scrutiny_web_frontend_url_ex_result=${?}
        popd &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${scrutiny_web_frontend_url_ex_result}

        if [[ ${scrutiny_web_frontend_url_dl_result} == 0 && ${scrutiny_web_frontend_url_ex_result} == 0 ]]; then
            echo "${latest_scrutiny_version}" > /opt/scrutiny/web/scrutiny-web-frontend-version.txt
        fi

        rm -f /opt/scrutiny/tmp/scrutiny-web-frontend.tar.gz
    fi

    # Install latest config file
    _stage_header "Configure Scrutiny"
    install -m 644 ${script_path}/files/scrutiny.yaml /opt/scrutiny/config/scrutiny.yaml
    _update_stage_header ${?}

    # Install systemd unit
    _stage_header "Installing 'scrutiny.service' unit"
    install -m 644 ${script_path}/files/scrutiny.service /etc/systemd/system/scrutiny.service &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    _stage_header "Reloading systemd units"
    systemctl daemon-reload &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Restarting Scrutiny Web Server"
    systemctl restart scrutiny.service &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    # Install Scrutiny collector deps
    apt_scrutiny_install_list=""
    `dpkg -la | grep smartmontools &> /dev/null` || apt_scrutiny_install_list="${apt_scrutiny_install_list} smartmontools"
    `dpkg -la | grep cron &> /dev/null` || apt_scrutiny_install_list="${apt_scrutiny_install_list} cron"
    if [[ ! -z ${apt_scrutiny_install_list} ]]; then
        _stage_header "Installing package(s) [${apt_scrutiny_install_list} ]"
        apt-get install -y ${apt_scrutiny_install_list} &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    else
        _standalone_stage_header "Scrutiny dependencies already installed"
    fi

    if [[ $(cat /opt/scrutiny/bin/scrutiny-collector-metrics-linux-amd64-version.txt 2>/dev/null) == "${latest_scrutiny_version}" ]]; then
        _standalone_stage_header "The installed version of scrutiny collector is already the latest version"
    else
        # Download the latest version of scrutiny web server
        _stage_header "Downloading scrutiny-collector-metrics-linux-amd64"
        wget -o /dev/null \
            -O /opt/scrutiny/bin/scrutiny-collector-metrics-linux-amd64 \
            ${scrutiny_collector_url}
        scrutiny_collector_url_dl_result=${?}
        _update_stage_header ${scrutiny_collector_url_dl_result}

        _stage_header "Make scrutiny-collector-metrics-linux-amd64 executable"
        chmod +x /opt/scrutiny/bin/scrutiny-collector-metrics-linux-amd64
        _update_stage_header ${?}

        if [[ ${scrutiny_collector_url_dl_result} == 0 ]]; then
            echo "${latest_scrutiny_version}" > /opt/scrutiny/bin/scrutiny-collector-metrics-linux-amd64-version.txt
        fi
    fi

    # Install collector cron job
    _stage_header "Install cron shedule for Scrutiny collector"
    install -m 644 ${script_path}/files/scrutiny-collector-cron /etc/cron.d/scrutiny-collector-cron
    _update_stage_header ${?}

    # Run an intial collector task
    _stage_header "Run initial Scrutiny collector task"
    /opt/scrutiny/bin/scrutiny-collector-metrics-linux-amd64 run --api-endpoint "http://localhost:5003" &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}


install_scrutiny
