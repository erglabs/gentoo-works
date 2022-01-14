#!/bin/bash
# warning this script will need you to think very, very hard of what you want to do
# you are going to use it to format a block device (usb stic, hard drive or whatever else)
# that means one mistake on your side can and probably will result in loss of data
# please read the documentation very carrefully,
# we are trying to make this tool as safe as possible and tested in as many envs as it is possible

# last update 2022-01-13
# maintaienr esavier/erglabs

# if something is wrong, please open the issue and we will fix it asap :)
# than you for using our stuff !
if [[ ! -z ${GIG_GS_FULL_DEBUG} ]] ; then set -x ; fi

SCRIPT_ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_ROOT_DIR}/aux.sh"

DEFAULT_LUKS_PASSWORD="AssPliersRaspberries"

if [[ "${EUID}" -ne 0 ]] || [[ -z ${1} ]]
then
  echo "please read the documentation provided in the file itself and in readme"
  echo "i need access to block devices and ability to mount and format those"
  echo "therefore, please run this tool as root"
  echo "this is very..."
  echo "...VERY..."
  echo "...dangerous"
  echo "make sure you understand what you are doing"
  exit -1
fi

echo "working with device : $(realpath ${1}) ;"

if [[ -z ${1} ]]
then
  echo "device not specified, panicking"
  exit -1
fi

if [[ ! -b ${1} ]]
then
  echo " for now using non-block devices is not supported yet"
  echo " i am bailing, please re-run the tool and provide proper blocdevice"
  exit -1
fi

# then
#   echo "what you provided does not look like block device (which is the default)"
#   if ! ynquestion "are you sure you wnat to proceed ?" 
#   then
#     echo "okay, bye then!"
#     exit -1
#   fi
# fi

# for now we are only doing dos type partition with legacy boot scheme
# two partitions:
# /boot 1Gib
# /     rest of the device
# this should be viable for usb drive and for standard pc system


# optional:
# wipefs ${1}

if grep -in "/dev/mapper/ecroot" /proc/mounts &>/dev/null ; 
then 
  echo "/dev/mapper/ecroot is busy, release it and retry"
  exit -1
fi

if grep -in "${1}" /proc/mounts &>/dev/null ; 
then 
  echo "device pointed at (${1}) is busy, release it and retry"
  exit -1
fi

if [[ ! -b ${1}1 ]] || [[ ! -b ${1}2 ]]
then
  echo 'there are problems with disk config'
  echo " i can not find either ${1}1 or ${1}2"
  exit
fi

if [[ -b "/dev/mapper/ecroot" ]] 
then
  echo "/dev/mapper/ecroot is already in use"
  echo "either edit the script or make ecroot available as a mount option :)"
  exit -1
fi

sfdisk --wipe always ${1} < partition.dos.sf
mkfs.ext4 -F ${1}1

printf '%s\n' "$DEFAULT_LUKS_PASSWORD" "$DEFAULT_LUKS_PASSWORD" | sudo cryptsetup luksFormat "${1}2"
printf '%s\n' "$DEFAULT_LUKS_PASSWORD" "$DEFAULT_LUKS_PASSWORD" | sudo cryptsetup open "${1}2" ecroot
mkfs.btrfs -f /dev/mapper/ecroot

# mounting as user
mount -o uid=1000,gid=1000 /dev/mapper/ecroot ${SCRIPT_ROOT_DIR}/workarea
mkdir -p ${SCRIPT_ROOT_DIR}/workarea/boot

#todo: image verification
#todo: download or seed mount and instalation scripts