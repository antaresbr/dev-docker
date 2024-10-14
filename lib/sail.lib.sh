#!/bin/bash

SAIL_DIR="$(dirname "$(realpath $0)")"
SAIL_DOCKER_DIR="${SAIL_DIR}/docker"
SAIL_CONFIG_DIR=""
START_DIR=$(pwd)

WORKSPACE_CONFIG_DIR="${SAIL_DIR}"
while [ -n "${WORKSPACE_CONFIG_DIR}" ]
do
  if [ -d "${WORKSPACE_CONFIG_DIR}/.config" ]
  then
    WORKSPACE_CONFIG_DIR="${WORKSPACE_CONFIG_DIR}/.config"
    break
  fi
  WORKSPACE_CONFIG_DIR="$(dirname "${WORKSPACE_CONFIG_DIR}")"
  [ "${WORKSPACE_CONFIG_DIR}" != "/" ] || WORKSPACE_CONFIG_DIR=""
done
[ -n "${WORKSPACE_CONFIG_DIR}" ] && [ -d "${WORKSPACE_CONFIG_DIR}/sail" ] && SAIL_CONFIG_DIR="${WORKSPACE_CONFIG_DIR}/sail"

function sailError() {
  echo "sailError | $@"
  exit 1
}

function workDir() {
  local targetDir="$1" && shift
  [ -n "${targetDir}" ] || sailError "workDir | Parameter not supplied, targetDir"

  cd "${targetDir}"
  [ "${targetDir}" == "$(realpath "$(pwd)")" ] || sailError "Failed to access, ${targetDir}"
}

function dockerConfigsLocal() {
  local zFile="$1"

  if [ -n "${SAIL_CONFIG_DIR}" ] && [ -n "${zFile}" ]
  then
    local confFile="${SAIL_CONFIG_DIR}/${zFile}"
    [ ! -f "${confFile}.yaml" ] || DOCKER_CONFIGS="${DOCKER_CONFIGS} --file ${confFile}.yaml"
    [ ! -f "${confFile}.yml" ] || DOCKER_CONFIGS="${DOCKER_CONFIGS} --file ${confFile}.yml"
  fi
}

function dockerConfigs() {
  DOCKER_CONFIGS="--file docker-compose.yaml"

  if [ -n "${SAIL_CONFIG_DIR}" ]
  then
    dockerConfigsLocal "docker-compose-local"
    dockerConfigsLocal "docker-compose-${SAIL_SERVICE}"
  fi

  [ -n "${SAIL_DOCKER_SOCK_FILE}" ] || SAIL_DOCKER_SOCK_FILE="/var/run/docker.sock"
  if [ "${SAIL_DOCKER_SOCK_ENABLED^^}" == "TRUE" ] && [ -S "${SAIL_DOCKER_SOCK_FILE}" ]
  then
    export DOCKER_HOST_GID=$(getent group docker | cut -d':' -f 3)
    DOCKER_CONFIGS="${DOCKER_CONFIGS} --file docker-sock.yaml"
  fi
}

function externalNetworks_up() {
  local networks="${WORKSPACE_EXTERNAL_NETWORKS}"
  [ -n "${networks}" ] || networks="workspace-net"
  local network=""
  for network in ${networks}
  do
    ${DOCKER_BIN} network inspect ${network} &> /dev/null
    [ $? -eq 0 ] || ${DOCKER_BIN} network create ${network}
    [ $? -eq 0 ] || sailError "Failed to create network '${network}'"
  done
}

function externalNetworks_down() {
  local networks="${WORKSPACE_EXTERNAL_NETWORKS}"
  [ -n "${networks}" ] || networks="workspace-net"
  local network=""
  for network in ${networks}
  do
    local netCount="$(${DOCKER_BIN} network inspect ${network} | jq -r '.[0].Containers | length')"
    if [ $? -eq 0 ] && [ "${netCount}" == "0" ]
    then
      ${DOCKER_BIN} network rm ${network}
    fi
  done
}

envFile="${SAIL_DIR}/.env"
if [ -f "${envFile}" ]
then
  source "${envFile}"
  [ $? -eq 0 ] || sailError "Failed to source file, ${envFile}"
fi
unset envFile

if [ -n "${SAIL_CONFIG_DIR}" ]
then
  envFile="${SAIL_CONFIG_DIR}/.env.local"
  if [ -f "${envFile}" ]
  then
    source "${envFile}"
    [ $? -eq 0 ] || sailError "Failed to source file, ${envFile}"
  fi
fi
unset envFile

DOCKER_BIN=$(which docker)
[ -n "${DOCKER_BIN}" ] || sailError "Failed to get DOCKER_BIN"

COMPOSE_BIN="${DOCKER_BIN} compose"
${COMPOSE_BIN} version &> /dev/null
[ $? -eq 0 ] || COMPOSE_BIN=""
[ -n "${COMPOSE_BIN}" ] || COMPOSE_BIN=$(which docker-compose)
[ -n "${COMPOSE_BIN}" ] || sailError "Failed to get COMPOSE_BIN"

pAction=""
pNoInteractive=""
pNoTTY=""

while [ $# -gt 0 ] && [ -z "${pAction}" ]
do
  if [ "$1" == "--no-interactive" ]
  then
    pNoInteractive="$1"
    shift
    continue
  fi
  if [ "$1" == "--no-tty" ]
  then
    pNoTTY="$1"
    shift
    continue
  fi
  pAction="$1"
  shift
done

if [ ! -t 0 ]
then
    pNoInteractive="--no-interactive"
    pNoTTY="--no-tty"
fi

workDir "${SAIL_DIR}"

if [ -n "${SAIL_DATA_DIR}" ]
then
  dirItem=""
  IFS_BAK="${IFS}"
  IFS=$':'
  for dirItem in ${SAIL_DATA_DIR}
  do
    [ -d "${dirItem}" ] || mkdir "${dirItem}" || sailError "Failed to create, $(pwd)/${dirItem}"
  done
  IFS="${IFS_BAK}"
  unset dirItem IFS_BAK
fi

workDir "${SAIL_DOCKER_DIR}"

dockerConfigs

case "${pAction}" in
  'build')
    [ ! -f "./pre-build.sh" ] || ./pre-build.sh || sailError "Failed to execute pre-build action"
    ${COMPOSE_BIN} build $@
    [ ! -f "./pos-build.sh" ] || ./pos-build.sh || sailError "Failed to execute pos-build action"
  ;;
  'exec' | "shell")
    [ -n "${pNoInteractive}" ] || xInteractive="--interactive"
    [ -n "${pNoTTY}" ] || xTTY="--tty"
    [ "${pAction}" == "shell" ] && serviceShell=${SAIL_SHELL}
    docker exec --user ${SAIL_USERNAME:-sail} ${xInteractive} ${xTTY} ${SAIL_BASENAME}-${SAIL_PROJECT}-${SAIL_VERSION_WS} ${serviceShell} $@
  ;;
  'config' | 'down' | 'logs' | 'ls' | 'pipe' | 'ps' | 'restart' | 'top' | 'up')
    [ "${pAction}" == "restart" -o "${pAction}" == "up" ] && externalNetworks_up
    [ "${pAction}" != "pipe" ] || pAction=""
    ${COMPOSE_BIN} ${DOCKER_CONFIGS} ${pAction} "$@"
    [ "${pAction}" == "down" ] && externalNetworks_down
  ;;
  'help' | '--help')
    script=$(basename "$0")
    echo "
${script}: Container ${SAIL_PROJECT}

Use: ${script} <action>

Actions:

  build    Build images
  config   Show configurations
  exec     Execute command in container
  down     Stop end remove service containers
  logs     Show container logs
  ls       List running compose projects
  pipe     Forward command to docker compose
  ps       List containers
  restart  Restart service containers
  shell    Invoke container shell
  top      Show running processes
  up       Start service container
  help     Show this help
"
    exit 0
  ;;
  *)
    sailError "Invalid or not supplied action: '${pAction}'"
  ;;
esac

cd "${START_DIR}"
