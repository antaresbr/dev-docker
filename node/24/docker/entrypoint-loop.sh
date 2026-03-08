#!/bin/bash

if [ -n "${DOCKER_HOST_GID}" ]
then
  docker_group="$(cat /etc/group | grep ":x:${DOCKER_HOST_GID}:" | cut -d':' -f 1)"
  if [ -z "${docker_group}" ]
  then
    docker_group="docker-host"
    sudo groupadd --force -g ${DOCKER_HOST_GID} docker-host
  fi
  sudo usermod -aG ${docker_group} sail
fi

NAP_TIME=${NAP_TIME:-10}

loop="0"

while :
do
  loop=$((loop+1))
  echo "${HOSTNAME} | [${loop}] $(date '+%Y-%m-%d %H:%M:%S')"
  sleep ${NAP_TIME}
done
