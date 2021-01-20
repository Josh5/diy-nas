#!/bin/bash
###
# File: install.sh
# Project: diy-nas
# File Created: Wednesday, 20th January 2021 7:15:06 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 20th January 2021 3:37:37 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
# 
# usage:
#       wget -O - https://raw.githubusercontent.com/Josh5/diy-nas/master/install.sh | bash
#
###

# Ensure we are run as root...
if [[ $(id -u) -gt 0 ]]; then
    echo "ERROR! This needs to be run as root... Exiting..."
    exit 1
fi

#  ____        __ _       _ _   _                 
# |  _ \  ___ / _(_)_ __ (_) |_(_) ___  _ __  ___ 
# | | | |/ _ \ |_| | '_ \| | __| |/ _ \| '_ \/ __|
# | |_| |  __/  _| | | | | | |_| | (_) | | | \__ \
# |____/ \___|_| |_|_| |_|_|\__|_|\___/|_| |_|___/
#                                                 

# Set Colours
CNORM="\e[0m";
CHEAD="\e[93m";
CPATCH="\e[92m";
CLBLUE="\e[94m";
CLMAG="\e[95m";
CLRED="\e[91m";
CLGREEN="\e[92m";
CLCYAN="\e[36m";

# CMODIFIED="\e[1;94m"; # M Light Blue (bold)
# CUNTRACKED="\e[1;4;95m"; # ? Light Mag (bold underlined)
# CMISSING="\e[1;4;36m"; # ! Cyan (bold underlined)
# CREMOVED="\e[1;91m"; # R Light Red (bold)
# CADDED="\e[1;92m"; # A Light Green (bold)

# Set path definitions
PROJECT_PATH="/opt/diy-nas"
SCRIPT_LOG_FILE="/tmp/diy-nas-install-debug.log"


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
    git checkout --track origin/master

    popd
fi

# Update log file
cat << EOF >> ${SCRIPT_LOG_FILE}

#############################################

Running script on $(date)

EOF

# Make missing directory structure
mkdir -p \
    ${PROJECT_PATH}/config


#  _   _      _                   _____                 _   _                 
# | | | | ___| |_ __   ___ _ __  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___ 
# | |_| |/ _ \ | '_ \ / _ \ '__| | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
# |  _  |  __/ | |_) |  __/ |    |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
# |_| |_|\___|_| .__/ \___|_|    |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
#              |_|                                                            
#                                             

# Helper functions
function _header {
    echo -e "" >> ${SCRIPT_LOG_FILE}
    echo -e "${CHEAD}  ... ${@} ...${CNORM}" >> ${SCRIPT_LOG_FILE}
    echo -e "${CHEAD}  ... ${@} ...${CNORM}"
}

function _stage_header {
    echo -e "      - ${CLCYAN}STAGE: ${@}${CNORM}" >> ${SCRIPT_LOG_FILE}
    echo -n "      - ${@}"
}

function _standalone_stage_header {
    echo -e "      - ${@}"
}

function _update_stage_header {
    if [[ ${1} -gt 0 ]]; then
        echo -e "          - ${CLRED} FAILED ${CNORM}"
        echo -e "          - ${CLRED} FAILED ${CNORM}" >> ${SCRIPT_LOG_FILE}
    else
        echo -e "          - ${CLGREEN} SUCCESS ${CNORM}"
        echo -e "          - ${CLGREEN} SUCCESS ${CNORM}" >> ${SCRIPT_LOG_FILE}
    fi
}

function _exec_command {
    cmd_stdout=$(eval ${@})
    cmd_res=${?}

}


#  __  __       _         _____                 _   _                 
# |  \/  | __ _(_)_ __   |  ___|   _ _ __   ___| |_(_) ___  _ __  ___ 
# | |\/| |/ _` | | '_ \  | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
# | |  | | (_| | | | | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
# |_|  |_|\__,_|_|_| |_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
#                                                                     

# Main functions
function install_default_config {
    # Install default config file if does not exist
    if [[ ! -e ${PROJECT_PATH}/config/config.env ]]; then
        _header "Installing default user config"

        _stage_header "Copy default config.env file"
        cp ${PROJECT_PATH}/source/config.env ${PROJECT_PATH}/config/config.env
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

function install_mount_script {
    # Install the mount script
    _header "Installing mount scripts"
    _stage_header "Installing 'disk-mount' script"
    install -m 755 ${PROJECT_PATH}/source/disk-mount /usr/local/bin/disk-mount &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    echo
}

function install_systemd_unit {
    # Install systemd unit
    _header "Installing systemd unit"
    _stage_header "Installing 'disk-mount@.service' unit"
    install -m 644 ${PROJECT_PATH}/source/disk-mount@.service /etc/systemd/system/disk-mount@.service &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    _stage_header "Reloading systemd units"
    systemctl daemon-reload &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    echo
}

function install_udev_rules {
    # Install the UDEV rules
    _header "Installing UDEV rules"
    _stage_header "Installing '99-media-automount.rules' UDEV rules"
    install -m 664 ${PROJECT_PATH}/source/99-media-automount.rules /etc/udev/rules.d/99-media-automount.rules &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    _stage_header "Reloading UDEV rules"
    udevadm control --reload-rules &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    echo
}

function install_mergerfs {
    # Install mergerfs
    _header "Ensuring MergerFS is installed"
    apt_mergerfs_install_list=""
    `command -v mergerfs &> /dev/null` || apt_mergerfs_install_list="${apt_mergerfs_install_list} mergerfs"
    `command -v fusermount &> /dev/null` || apt_mergerfs_install_list="${apt_mergerfs_install_list} fuse"
    `command -v xattr &> /dev/null` || apt_mergerfs_install_list="${apt_mergerfs_install_list} xattr"
    if [[ ! -z ${apt_mergerfs_install_list} ]]; then
        _stage_header "Installing package(s) [${apt_mergerfs_install_list} ]"
        apt-get install -y ${apt_mergerfs_install_list} &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    else
        _standalone_stage_header "MergerFS already installed"
    fi
    echo
}

function install_fstab_config {
    # Build the initial mounts in fstab
    _header "Updating fstab mount config"
    if [[ ! -e /etc/fstab.original ]]; then
         _stage_header "Backup original fstab config"
        cp /etc/fstab /etc/fstab.original &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    original_fstab=$(cat /etc/fstab.original)

    echo "${original_fstab}" > /etc/fstab
    echo "" >> /etc/fstab

    _standalone_stage_header "Adding TMPFS mount points for disks and storage"
    echo "# TMPFS for mount points:" >> /etc/fstab
    # Create a mount for our merged storage
    echo "tmpfs   /storage              tmpfs nosuid,nodev,noatime 0 0" >> /etc/fstab
    # Create a mount point for our disks
    echo "tmpfs   /mnt/disks            tmpfs nosuid,nodev,noatime 0 0" >> /etc/fstab
    # Create an initial ramdisk mount of really low limited size for the initial mergerfs pool
    echo "tmpfs   /mnt/disks/ramdisk    tmpfs nosuid,nodev,noatime,size=12k 0 0" >> /etc/fstab
    echo "" >> /etc/fstab

    if [[ -e ${PROJECT_PATH}/config/config.env ]]; then
        source ${PROJECT_PATH}/config/config.env
        if [[ ! -z ${CACHE_DISK_PART1_UUID} ]]; then
            _standalone_stage_header "Adding storage cache mount point"
            echo "# MergerFS Cache:" >> /etc/fstab
            cache_disk_part1_fs_type=$(blkid -o value -s TYPE /dev/disk/by-uuid/${CACHE_DISK_PART1_UUID})
            echo "/dev/disk/by-uuid/${CACHE_DISK_PART1_UUID}    /storage/cache    ${cache_disk_part1_fs_type}    defaults 0 0" >> /etc/fstab
            echo "" >> /etc/fstab
        else
            _standalone_stage_header "No storage cache mount configured...ignoring"
            echo "# (No cache disk part1 configured)" >> /etc/fstab
            echo "" >> /etc/fstab
        fi

        if [[ ! -z ${CACHE_DISK_PART2_UUID} ]]; then
            _standalone_stage_header "Adding MergerFS cache mount point"
            echo "# MergerFS Cache:" >> /etc/fstab
            cache_disk_part2_fs_type=$(blkid -o value -s TYPE /dev/disk/by-uuid/${CACHE_DISK_PART2_UUID})
            echo "/dev/disk/by-uuid/${CACHE_DISK_PART2_UUID}    /mnt/disks/cache    ${cache_disk_part2_fs_type}    defaults 0 0" >> /etc/fstab
            echo "" >> /etc/fstab
        else
            _standalone_stage_header "No MergerFS cache mount configured...ignoring"
            echo "# (No cache disk part2 configured)" >> /etc/fstab
            echo "" >> /etc/fstab
        fi
    else
        _standalone_stage_header "No config file found...no cache will be used"
        echo "# (No config file found)" >> /etc/fstab
        echo "" >> /etc/fstab
    fi

    # # [WIP] Detect all current disks - If they are internal, then add them to fstab
    # echo "# Data disks:" >> /etc/fstab
    # for disk_uuid in `ls /dev/disk/by-uuid/ 2> /dev/null`; do
    #     if [[ " ${DISK_UUID_BLACKLIST[@]} " =~ " ${disk_uuid} " ]]; then
    #         # Dont add to fstab
    #         echo "# Ignoring disk '${disk_uuid}' due to config.env file DISK_UUID_BLACKLIST list"
    #         continue
    #     fi
    #     # Ensure that they are not already in the fstab file
    #     if `grep "${disk_uuid}" /etc/fstab &> /dev/null` ; then
    #         # Dont add duplicate to fstab
    #         echo "# Ignoring disk '${disk_uuid}' due to UUID existing in fstab"
    #         continue
    #     fi
    #     # Get the disk FS type
    #     disk_fs_type=$(blkid -o value -s TYPE /dev/disk/by-uuid/${disk_uuid})
    #     # If that failed, dont bother adding it to fstab
    #     [[ -z ${disk_fs_type} ]] && continue
    #     # Don't add vfat FS partitions to the fstab file
    #     if [[ "${disk_fs_type,,}" =~ ^(vfat|swap|crypto_luks)$ ]]; then
    #         # Dont add duplicate to fstab
    #         echo "# Ignoring disk '${disk_uuid}' due to fs type being '${disk_fs_type}'"
    #         continue
    #     fi
    #     # Get the disk FS type
    #     disk_part_label=$(blkid -o value -s LABEL /dev/disk/by-uuid/${disk_uuid})
    #     if [[ "${disk_part_label,,}" =~ ^(efi|boot|system|recovery|settings|boot|root0|share0)$ ]]; then
    #         # Dont add duplicate to fstab
    #         echo "# Ignoring disk '${disk_uuid}' due to part label being '${disk_part_label}'"
    #         continue
    #     fi
    #     # Figure out a mount point to use
    #     ## Find out devbase
    #     devbase=$( basename $( readlink -e /dev/disk/by-uuid/${disk_uuid} ) )
    #     mount_label=${disk_part_label}
    #     if [[ -z "${mount_label}" ]]; then
    #         LABEL=${devbase}
    #     elif /bin/grep -q " /media/${LABEL} " /etc/mtab; then
    #         # Already in use, make a unique one
    #         mount_label+="-${devbase}"
    #     fi
    #     mount_label=$(echo "${mount_label// /_}")
    #     mount_point="/mnt/disks/${mount_label}"
    #     # Global mount options
    #     OPTS="rw,relatime"
    #     # File system type specific mount options
    #     if [[ "${disk_fs_type,,}" =~ ^(vfat|ntfs)$ ]]; then
    #         OPTS+=",users,gid=100,umask=000,shortname=mixed,utf8=1,flush"
    #     fi
    #     # Create fstab entry
    #     echo "/dev/disk/by-uuid/${disk_uuid}    ${mount_point}    ${disk_fs_type}    defaults,nofail,${OPTS} 0 0" >> /etc/fstab
    # done
    # disk_fs_type=""
    # echo "" >> /etc/fstab

    _standalone_stage_header "Adding MergerFS pool mount point"
    # Build MergerFS /storage/pool mount args
    storage_pool_mount_options="defaults,allow_other,direct_io,use_ino,minfreespace=1G,fsname=mergerfs"
    # Specify the create policy as mspmfs - most free space
    storage_pool_mount_options="${storage_pool_mount_options},category.create=mfs"
    # # [TODO] Specify the policy for ENOSPC (no space left on device) or EDQUOT (disk quota exceeded) as mfs - most free space
    # storage_pool_mount_options="${storage_pool_mount_options},moveonenospc=true"
    # Specify the policy for file caching as partial - Enables page caching. Underlying files cached, mergerfs files cached while open.
    storage_pool_mount_options="${storage_pool_mount_options},cache.files=partial,dropcacheonclose=true"

    echo "# MergerFS Mounts:" >> /etc/fstab
    echo "/mnt/disks/*   /storage/pool   fuse.mergerfs   ${storage_pool_mount_options}   0   0" >> /etc/fstab
    echo "" >> /etc/fstab

    # Mount it now
    _stage_header "Creating mount point '/storage'"
    mkdir -p /storage &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    _stage_header "Mounting '/storage'"
    mount /storage &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Creating mount point '/mnt/disks'"
    mkdir -p /mnt/disks &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    _stage_header "Mounting '/mnt/disks'"
    mount /mnt/disks &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Creating mount point '/mnt/disks/ramdisk'"
    mkdir -p /mnt/disks/ramdisk &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    _stage_header "Mounting '/mnt/disks/ramdisk'"
    mount /mnt/disks/ramdisk &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Creating mount point '/storage/pool'"
    mkdir -p /storage/pool &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    _stage_header "Mounting '/storage/pool'"
    mount /storage/pool &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    
    echo
}

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

function install_samba {
    # Ensure Samba server is installed
    _header "Ensuring Samba server is installed"

    if ! `dpkg -la | grep ' samba ' &> /dev/null`; then
        _stage_header "Installing package(s) [samba]"
        apt-get install -y samba &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    mkdir -p /etc/samba &>> ${SCRIPT_LOG_FILE}
    if [[ ! -e /etc/samba/smb.conf.original ]]; then
        _stage_header "Backup original Samba config"
        cp /etc/samba/smb.conf /etc/samba/smb.conf.original &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    _stage_header "Installing Samba config"
    install -m 644 ${PROJECT_PATH}/source/smb.conf /etc/samba/smb.conf
    _update_stage_header ${?}

    _stage_header "Restarting Samba server"
    systemctl restart smbd &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}

function install_nfs {
    # Ensure NFS server is installed
    _header "Ensuring NFS server is installed"

    if ! `dpkg -la | grep ' nfs-kernel-server ' &> /dev/null`; then
        _stage_header "Installing package(s) [nfs-kernel-server]"
        apt-get install -y nfs-kernel-server &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    if [[ ! -e /etc/exports.original ]]; then
        _stage_header "Backup original NFS exports config"
        cp /etc/exports /etc/exports.original &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    _stage_header "Installing NFS config"
    install -m 644 ${PROJECT_PATH}/source/exports /etc/exports
    _update_stage_header ${?}

    _stage_header "Reloading NFS exports"
    exportfs -ra
    _update_stage_header ${?}

    _stage_header "Restarting NFS server"
    systemctl restart nfs-kernel-server
    _update_stage_header ${?}
    
    echo
}

function install_cockpit {
    # Ensure Cockpit is installed
    _header "Ensuring Cockpit is installed"

    if ! `dpkg -la | grep cockpit &> /dev/null`; then
        _stage_header "Installing package(s) [cockpit]"
        apt-get install -y cockpit &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    else
        _standalone_stage_header "Cockpit already installed"
    fi

    #  # Install cockpit docker [MAYBE...]
    #  mkdir -p /opt/cockpit
    #  if [[ ! -e /opt/cockpit/cockpit-docker_215-1~ubuntu19.10.1_all.deb ]]; then
    #      wget -o /dev/null \
    #          -O /opt/cockpit/cockpit-docker_215-1~ubuntu19.10.1_all.deb \
    #          https://launchpad.net/ubuntu/+source/cockpit/215-1~ubuntu19.10.1/+build/18889196/+files/cockpit-docker_215-1~ubuntu19.10.1_all.deb
    #  fi
    #  `dpkg -la | grep cockpit-docker &> /dev/null` || apt-get install -y /opt/cockpit/cockpit-docker_215-1~ubuntu19.10.1_all.deb

    _stage_header "Restarting cockpit server"
    systemctl restart cockpit
    _update_stage_header ${?}

    echo
}

function install_project_updater_script {
    # Install the project updater script
    _header "Installing project updater scripts"
    _stage_header "Installing 'diy-nas-update' script"
    install -m 755 ${PROJECT_PATH}/source/diy-nas-update /usr/local/bin/diy-nas-update &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}
    echo
}


function update_system_packages {
    # Update all system packages
    _header "Updating all system packages"

    _stage_header "Fetching latest package lists"
    apt-get update &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Upgrading packages"
    apt-get upgrade -y &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Removing old packages"
    apt-get autoremove &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    echo
}

function update_project_system_docker_stack {
    # Update default docker-compose services
    _header "Updating system Docker stack"

    # First source the default template (incase user template is missing required variables)
    source ${PROJECT_PATH}/source/config.env
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

function patching_muximux_for_landing_page {
    # Update default docker-compose services
    _header "Patching muximux for landing page"


    _stage_header "Install muximux settings"
    install -m 666 ${PROJECT_PATH}/source/settings.ini.php ${PROJECT_PATH}/system_appdata/landing-page/www/muximux/settings.ini.php &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

    _stage_header "Patch muximux settings with hostname"
    short_hostname=$(hostname -s)
    sed -i "s|://localhost|://${short_hostname,,}.local|" ${PROJECT_PATH}/system_appdata/landing-page/www/muximux/settings.ini.php &>> ${SCRIPT_LOG_FILE}
    _update_stage_header ${?}

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

    echo
}


#  ____              
# |  _ \ _   _ _ __  
# | |_) | | | | '_ \ 
# |  _ <| |_| | | | |
# |_| \_\\__,_|_| |_|
#                    

install_default_config
install_mount_script
install_systemd_unit
install_udev_rules
install_mergerfs
install_fstab_config
install_docker
install_docker_compose
install_samba
install_nfs
install_cockpit
install_project_updater_script
update_system_packages
update_project_system_docker_stack
patching_muximux_for_landing_page


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
