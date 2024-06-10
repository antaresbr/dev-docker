#!/bin/bash

DOCKER_BASE_DIR="$(dirname "$(realpath "$0")")"
DOCKER_BASE_DIR="$(realpath --canonicalize-existing --relative-to=${HOME} "${DOCKER_BASE_DIR}" 2> /dev/null)"
[ -z "${DOCKER_BASE_DIR}" ] && echo "$(basename "$0") | ERROR: Unable to get DOCKER_BASE_DIR" && exit 1

createBinLink() {
    local zTarget="$1"
    if [ ! -f "${HOME}/${DOCKER_BASE_DIR}/${zTarget}" ]
    then
      echo "$(basename "$0") | Alvo não encontrado, ${zTarget}"
    else
      [ ! -f "${HOME}/bin/$(basename "$zTarget")" ] && ln --verbose --symbolic "../${DOCKER_BASE_DIR}/${zTarget}" "${HOME}/bin"
    fi
}

[ $# -gt 0 ] || { echo "$(basename "$0") | Nenhum alvo informado"; exit 1; }

while [ $# -gt 0 ]
do
  pTarget="$1"

  [ "${pTarget}" == "all" -o "${pTarget}" == "pentaho-pdi-93" ] && createBinLink "pentaho/pdi/9.3/pentaho-pdi-93.sh"

  [ "${pTarget}" == "all" -o "${pTarget}" == "php-80" ] && createBinLink "php/8.0/php-80.sh"
  [ "${pTarget}" == "all" -o "${pTarget}" == "php-81" ] && createBinLink "php/8.1/php-81.sh"
  [ "${pTarget}" == "all" -o "${pTarget}" == "php-82" ] && createBinLink "php/8.2/php-82.sh"

  [ "${pTarget}" == "all" -o "${pTarget}" == "python-311" ] && createBinLink "python/3.11/python-311.sh"

  [ "${pTarget}" == "all" -o "${pTarget}" == "ubuntu-focal" ] && createBinLink "ubuntu/20.04/ubuntu-focal.sh"
  [ "${pTarget}" == "all" -o "${pTarget}" == "ubuntu-jammy" ] && createBinLink "ubuntu/22.04/ubuntu-jammy.sh"

  shift
done
