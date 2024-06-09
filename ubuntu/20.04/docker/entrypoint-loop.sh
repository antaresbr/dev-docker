#!/bin/bash

NAP_TIME=${NAP_TIME:-10}

loop="0"

while :
do
  loop=$((loop+1))
  echo "${HOSTNAME} | [${loop}] $(date '+%Y-%m-%d %H:%M:%S')"
  sleep ${NAP_TIME}
done
