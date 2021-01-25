#!/bin/bash
###
# File: install.sh
# Project: diy-nas
# File Created: Wednesday, 20th January 2021 7:15:06 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 3:37:12 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
# 
# usage:
#       wget -O - https://raw.githubusercontent.com/Josh5/diy-nas/master/install.sh | bash
#
###


PROJECT_PATH="/opt/diy-nas"
PROJECT_INSTALL_ENV_FILE="${PROJECT_PATH}/source/install.env"


# Ensure we are run as root...
if [[ $(id -u) -gt 0 ]]; then
    echo "ERROR! This needs to be run as root... Exiting..."
    exit 1
fi


# Ensure script deps are installed...
`command -v git &> /dev/null` || apt_deps_install_list="${apt_mergerfs_install_list} git"
`command -v curl &> /dev/null` || apt_deps_install_list="${apt_mergerfs_install_list} curl"

if [[ ! -z ${apt_deps_install_list} ]]; then
    echo "Missing dependencies:"
    echo "Run the following command before running this script."
    echo "      'apt install ${apt_deps_install_list}'"
    echo
    echo "Exit!"
    exit 1
fi


#  _   _                _           
# | | | | ___  __ _  __| | ___ _ __ 
# | |_| |/ _ \/ _` |/ _` |/ _ \ '__|
# |  _  |  __/ (_| | (_| |  __/ |   
# |_| |_|\___|\__,_|\__,_|\___|_|   
#                                   

echo
echo -e "${CLMAG}Installing/Upgrading D.I.Y. NAS Config ${CNORM}"
echo
echo


#  ___       _ _   _       _   ___           _        _ _ 
# |_ _|_ __ (_) |_(_) __ _| | |_ _|_ __  ___| |_ __ _| | |
#  | || '_ \| | __| |/ _` | |  | || '_ \/ __| __/ _` | | |
#  | || | | | | |_| | (_| | |  | || | | \__ \ || (_| | | |
# |___|_| |_|_|\__|_|\__,_|_| |___|_| |_|___/\__\__,_|_|_|
#                                                         

if [[ ! -L ${PROJECT_PATH} ]]; then
    mkdir -p ${PROJECT_PATH}
    # TODO: Dont make this RW by everyone...
    chmod a+rw ${PROJECT_PATH}

    pushd ${PROJECT_PATH}

    # Initi the git repo (if required)
    [[ -e ${PROJECT_PATH}/.git/config ]] || git init
    `grep -q 'git@github.com:Josh5/diy-nas.git' ${PROJECT_PATH}/.git/config` || git remote add origin https://github.com/Josh5/diy-nas.git

    # Clean directory
    git clean -fd
    [[ `git rev-list --all --count` -gt 0 ]] && git reset --hard HEAD

    # Pull latest changes
    git fetch origin
    git checkout master
    git pull

    popd
fi


# Source the environment variables from the project install env file
source ${PROJECT_INSTALL_ENV_FILE}


# Update log file
cat << EOF >> ${SCRIPT_LOG_FILE}

#############################################

Running script on $(date)

EOF


# Make missing directory structure
mkdir -p \
    ${PROJECT_PATH}/config


#  ____              
# |  _ \ _   _ _ __  
# | |_) | | | | '_ \ 
# |  _ <| |_| | | | |
# |_| \_\\__,_|_| |_|
#                    

for source_path in ${PROJECT_PATH}/source/*; do
    if [[ -e ${source_path}/setup.sh ]]; then
        if _check_script_md5sum "${source_path}/setup.sh"; then
            script_path=$(dirname $(readlink -e ${source_path}/setup.sh))
            echo -e "${CHEAD}  ... Skipping section '$(basename ${script_path})' (No changes found) ...${CNORM}" >> ${SCRIPT_LOG_FILE}
        else
            chmod +x ${source_path}/setup.sh
            ${source_path}/setup.sh
            _set_script_md5sum ${source_path}/setup.sh
        fi
    fi
done


#  _____           _            
# |  ___|__   ___ | |_ ___ _ __ 
# | |_ / _ \ / _ \| __/ _ \ '__|
# |  _| (_) | (_) | ||  __/ |   
# |_|  \___/ \___/ \__\___|_|   
#                               

echo -e "${CLMAG}Installing/Upgrading D.I.Y. NAS Config - Done! ${CNORM}"
echo
echo -e "${CLMAG}For details on any failed items above, view the logs found in: ${CNORM}"
echo -e "${CLMAG}    ${SCRIPT_LOG_FILE} ${CNORM}"
echo -e "${CNORM}"

exit
