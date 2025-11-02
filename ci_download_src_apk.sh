#!/bin/bash
set -e

verify_apk() {
    . ci_versions/deps.sh
    "./deps/Android/Sdk/build-tools/${BUILD_TOOLS_VER}/apksigner" verify --print-certs "$1" > /tmp/result.txt || exit 1
    grep -q "$2" /tmp/result.txt && return 0
    echo "Cert SHA256 digest mismatch" >&2
    exit 2
}

. ci_versions/src_apk.sh

rm -fr apk armv7apk
mkdir -p apk armv7apk

releases=$(curl -s -H "Authorization: token ${PAT_TOKEN}" "https://api.github.com/repos/Puella-Care/en-apk/releases/tags/init" | jq -r '.assets[] | "\(.name) \(.url)"')
ARMV8_URL=$(echo "${releases}" | awk '$1=="armv8.apk"{print $2}')
ARMV7_URL=$(echo "${releases}" | awk '$1=="armv7.apk"{print $2}')

[[ -z "${ARMV7_URL}" || -z "${ARMV8_URL}" ]] && echo "Missing apk" && exit 1

curl -L -H "Authorization: token ${PAT_TOKEN}" -H "Accept: application/octet-stream" "${ARMV8_URL}" -o out.apk
verify_apk out.apk "${SRCAPK_CERT_SHA256}" && mv out.apk "./apk/src_${SRCAPK_VER}.apk"

curl -L -H "Authorization: token ${PAT_TOKEN}" -H "Accept: application/octet-stream" "${ARMV7_URL}" -o out.apk
verify_apk out.apk "${SRCAPK_CERT_SHA256}" && mv out.apk "./armv7apk/armv7src_${SRCAPK_VER}.apk"
