#!/usr/bin/env bash

RED="\e[0;31m"
YELLOW="\e[1;33m"
GREEN="\e[0;32m"
COLOROFF="\e[0m"
NOCOLOR=${COLOROFF}

function ECHO()
{
	echo -e "$@"
}

function INFO()
{
	ECHO "${GREEN}$*${NOCOLOR}"
}

function WARNING()
{
	ECHO "${YELLOW_BOLD}Warning: ${YELLOW}$*${NOCOLOR}" > /dev/stderr
}

function ERROR()
{
	ECHO "${RED_BOLD}ERROR: ${RED}$*${NOCOLOR}"
	exit 1
}

function show_usage()
{
    ECHO ""
    ECHO "This script will run the ${DOCKER_IMAGE} implemented by Sky."
    ECHO "Any arguments passed to this script will be passed as a command to be run inside the docker"
    ECHO "The simplest usage for this script is to run it with /bin/bash as the argument"
    ECHO "    ${YELLOW}./docker-run.sh /bin/bash${NOCOLOR}"
    ECHO "This will put you into a bash shell inside the running docker container, with the your home directory mounted"
    ECHO " and available to you"
    ECHO ""
}

if [[ -z $* ]];then
    show_usage
    exit
fi

# Replace this to change docker image
DOCKER_IMAGE='rdk-kirkstone:latest'
# Standard docker options: use host network, remove after command complete, interactive
DOCKER_OPTIONS=( '--net=host' '--rm' '-it' )
# Mount the home directory
DOCKER_OPTIONS+=( '-v' "${HOME}:${HOME}" \
                  '-e' "LOCAL_START_DIR=${HOME}" )
# Add the host user
DOCKER_GROUP="$(getent group docker | awk -F ':' '{print $3}')"
DOCKER_OPTIONS+=( '-e' "LOCAL_USER_ID=$(id -u)" \
                  '-e' "LOCAL_GROUP_ID=$(id -g)" \
                  '-e' "LOCAL_USER_NAME=${USER}" \
                  '-e' "LOCAL_DOCKER_GROUP=${DOCKER_GROUP}" )
# Docker naming
DOCKER_HOSTNAME="${USER}_${DOCKER_IMAGE/\:*/}"
# Append the time since epoch to the docker name
TIME_SINCE_EPOCH="$(date +'%s')"
DOCKER_NAME="${DOCKER_HOSTNAME}_${TIME_SINCE_EPOCH}"
DOCKER_OPTIONS+=( '--name' "${DOCKER_NAME}" \
                  '--hostname' "${DOCKER_NAME}")

# Check if the part after the final _ describes a different architecture to use.
case "${docker/*_/}" in
    'i386')
        DOCKER_OPTIONS+=( --platform linux/i386 )
        ;;
    # By default use amd64
    'amd64' | *)
        DOCKER_OPTIONS+=( --platform linux/amd64 )
        ;;
esac

if [[ -n "${SSH_AUTH_SOCK}" ]];then
    DOCKER_OPTIONS+=( "-v" "$(dirname ${SSH_AUTH_SOCK}):$(dirname ${SSH_AUTH_SOCK})" "-e" "SSH_AUTH_SOCK=${SSH_AUTH_SOCK}" )
fi
INFO "docker run ${DOCKER_OPTIONS[*]} ${DOCKER_IMAGE} source /usr/local/bin/bashext.sh && cd ${PWD}; $*"
docker run  "${DOCKER_OPTIONS[@]}" "${DOCKER_IMAGE}" "source /usr/local/bin/bashext.sh && cd ${PWD}; $@"

