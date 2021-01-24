#!/bin/bash
###
# File: install.sh
# Project: 030-fstab_config
# File Created: Sunday, 24th January 2021 10:50:21 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 25th January 2021 12:00:50 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


script_path="$(dirname $(readlink -e ${BASH_SOURCE[0]}))"
source "${script_path}/../install.env"


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
    if [[ ! -e /storage ]]; then
        _stage_header "Creating mount point '/storage'"
        mkdir -p /storage &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    if ! grep -qs ' /storage ' /proc/mounts; then
        _stage_header "Mounting '/storage'"
        mount /storage &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    if [[ ! -e /mnt/disks ]]; then
        _stage_header "Creating mount point '/mnt/disks'"
        mkdir -p /mnt/disks &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    if ! grep -qs ' /mnt/disks ' /proc/mounts; then
        _stage_header "Mounting '/mnt/disks'"
        mount /mnt/disks &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    if [[ ! -e /mnt/disks/ramdisk ]]; then
        _stage_header "Creating mount point '/mnt/disks/ramdisk'"
        mkdir -p /mnt/disks/ramdisk &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    if ! grep -qs ' /mnt/disks/ramdisk ' /proc/mounts; then
        _stage_header "Mounting '/mnt/disks/ramdisk'"
        mount /mnt/disks/ramdisk &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi

    if [[ ! -e /storage/pool ]]; then
        _stage_header "Creating mount point '/storage/pool'"
        mkdir -p /storage/pool &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    if ! grep -qs ' /storage/pool ' /proc/mounts; then
        _stage_header "Mounting '/storage/pool'"
        mount /storage/pool &>> ${SCRIPT_LOG_FILE}
        _update_stage_header ${?}
    fi
    
    echo
}


install_fstab_config
