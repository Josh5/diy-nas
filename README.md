The D.I.Y. NAS
---

This is the setup process for the D.I.Y. NAS.

Before running this, you need to have Ubuntu 20.04 installed on a USB stick.

After booting Ubuntu, before doing anything else, follow these steps:



# Manditory initial setup

## Update all packages
```
apt update && apt install upgrade
```


## Disable automounting as your primary user
Login to your primary user and run this:
```
gsettings set org.gnome.desktop.media-handling automount false
```

This disables auto-mounting devices that are plugged in. This setup will handle that as a root user.


## Config file

This system has some configureation options that is read during the install/update processes.
Be sure to create this file with any modifications that you may need...

Create a file called `/opt/diy-nas/config/config.env`.
Populate it with the following options as required...


### Blacklist partitions by UUID

You are able to blacklist partitions by adding an array of UUIDs.

Add UUIDs to the `config.env` file as shown below:
```
DISK_UUID_BLACKLIST=(
    "86b758ab-6d21-4e88-a769-6881c735857e"
    "a6c87277-c8ad-4665-b9ad-3eae65c43bc2"
)
```


### Generate configuration for any cache disks (WIP)

You can have a cache disk present. This needs to be formatted into 2 partitions.
One partition (part 1) will be mounted as a directly available mount in `/storage/cache`
The other partition (part 2) will be mounted within the MergerFS pool.

Run the command
```
blkid
```

Fetch the UUID of the partitions of the cache disk

Add the variables in the `config.env` file as shown below:
```
CACHE_DISK_PART1_UUID=90c53f7c-8834-db9a-adb7-f7676bad4e4c
CACHE_DISK_PART2_UUID=837ab7b3-9222-48fd-8508-00b679517cab
```



# Optional initial setup

Some of the parts below are only needed depending on your hardware...

## NVIDIA Drivers
```
# First install deps
apt install dkms pkg-config libglvnd-dev

# Download and install drivers
mkdir -p /opt/nvidia
cd /opt/nvidia
wget https://international.download.nvidia.com/XFree86/Linux-x86_64/455.45.01/NVIDIA-Linux-x86_64-455.45.01.run
chmod +x ./NVIDIA-Linux-x86_64-455.45.01.run
./NVIDIA-Linux-x86_64-455.45.01.run

# Patch the installed driver
wget https://raw.githubusercontent.com/keylase/nvidia-patch/master/patch.sh
bash ./patch.sh
```
