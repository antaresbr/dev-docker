#!/bin/bash

libFile="$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")/lib/sail.lib.sh"
source "${libFile}"
[ $? -eq 0 ] || { echo "ERROR: Failed to source file, ${libFile}"; exit 1; }
