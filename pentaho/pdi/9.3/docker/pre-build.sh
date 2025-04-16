#!/bin/bash

if [[ $(type -t sailError) != function ]]
then
  function sailError() {
    echo ""
    echo "sailError | $@"
    echo ""
    exit 1
  }
fi

UNZIP=$(which unzip)
[ -n "${UNZIP}" ] || sailError "$(basename "$0") | File not found: unzip"

[ -n "${SAIL_PDI_BASE}" ] || sailError "$(basename "$0") | SAIL_PDI_BASE not defined"
PDI_ZIP="${SAIL_PDI_BASE}.zip"

[ -f "temp/${PDI_ZIP}" ] || wget --directory-prefix=temp "https://sinalbr.dl.sourceforge.net/project/pentaho/Pentaho-9.3/client-tools/${PDI_ZIP}"

[ -d "temp/data-integration" ] || unzip "temp/${PDI_ZIP}" -d temp/

tempFile="temp/oci-install.sh"
[ -f "${tempFile}" ] || curl --silent --location --output "${tempFile}" "https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh"

