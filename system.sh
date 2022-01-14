#!/bin/bash
# maintainer - esavier/erglabs

echo GIG_GS_FULL_DEBUG is $GIG_GS_FULL_DEBUG
echo GIG_GS_FAKE_DOWNLOAD is $GIG_GS_FAKE_DOWNLOAD
echo GIG_GS_STATIC_XTRACT_NO_CLEANUP is $GIG_GS_STATIC_XTRACT_NO_CLEANUP
echo GIG_GS_STATIC_NO_XTRACT is $GIG_GS_STATIC_NO_XTRACT
echo ' '

# yeah we will need root for this script too

# allow debugging
if [[ ! -z ${GIG_GS_FULL_DEBUG} ]] ; then set -x ; fi

#find directory
SCRIPT_ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WORKDIR="${SCRIPT_ROOT_DIR}/workarea"
DOWNLOADS="${SCRIPT_ROOT_DIR}/downloads"
mkdir -p ${WORKDIR}
mkdir -p ${DOWNLOADS}

if ! lsblk -f | grep ${WORKDIR} &>/dev/null
then
  echo "tool requires you to mount desired installation target into workarea directory"
  exit -1
fi

function extract_latest_uri() {
 curl -s ${1} | grep -v '^#' | cut -d ' ' -f 1
}

function extract_filename() {
 echo "${1}" | rev | cut -d '/' -f 1 | rev
}

function extract_extension() {
 echo "${1}" | rev | cut -d '.' -f 1 | rev
}

function download_static_resources() {
    # todo  types and stuff, like stage3 vs stage4, systemd vs initrc, hardened etc
    cd "${DOWNLOADS}"
    if [[ -z ${GIG_GS_FAKE_DOWNLOAD} ]]
    then
        curl -O -J "$1"
    fi
    FILENAME="$(extract_filename ${1})"
    echo ${FILENAME} > "${2}"
    echo ${FILENAME}
    cd "${SCRIPT_ROOT_DIR}"
}

function cleanup_and_extract_static_resource() {
  # $1 what
  echo ...extracting ${1} 
  echo ...to workarea
  if [[ ! -f "${DOWNLOADS}/${1}" ]]
  then
    echo 'can not extract file, provided path is not an archive!'
    echo 'panicking!'
    exit
  fi
  if [[ -z ${GIG_GS_STATIC_XTRACT_NO_CLEANUP} ]]
  then
    rm -rf "${WORKDIR}"
    mkdir "${WORKDIR}"
  fi
  if [[ -z ${GIG_GS_STATIC_NO_XTRACT} ]]
  then
    cd "${WORKDIR}"
    tar -axvf "${DOWNLOADS}/${1}"
  fi
}

# todo mirror list:
#   this requires separate functionality i.e. finding closest server
#   this is kidna complicated to do in bash so for now you have to edit this source
#   by yourself. This functionality will be definitively added in the future.

function prepare_for_instalation() {
  mkdir --parents ${WORKDIR}/etc/portage/repos.conf
  cp ${WORKDIR}/usr/share/portage/config/repos.conf ${WORKDIR}/etc/portage/repos.conf/gentoo.conf
  cp --dereference /etc/resolv.conf ${WORKDIR}/etc/
  mount --types proc /proc ${WORKDIR}/proc
  mount --rbind /sys ${WORKDIR}/sys
  mount --make-rslave ${WORKDIR}/sys
  mount --rbind /dev ${WORKDIR}/dev
  mount --make-rslave ${WORKDIR}/dev
  mount --bind /run ${WORKDIR}/run
  mount --make-slave ${WORKDIR}/run 
  test -L /dev/shm && rm /dev/shm && mkdir /dev/shm 
  mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm 
  chmod 1777 /dev/shm
}

BASE_URL="http://gentoo.bloodhost.ru/releases/amd64/autobuilds"
ADMINCD_SOURCE="${BASE_URL}/latest-admincd-amd64.txt"
STAGE3_SYSTEMD_SOURCE="${BASE_URL}/latest-stage3-amd64-systemd.txt"
STAGE3_SYSTEMD_LATEST="${BASE_URL}/$(extract_latest_uri ${STAGE3_SYSTEMD_SOURCE})"

RES=$(download_static_resources "${STAGE3_SYSTEMD_LATEST}" "STAGE3SYTSTEMD")
cleanup_and_extract_static_resource ${RES}
prepare_for_instalation
