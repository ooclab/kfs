#!/bin/bash

if [ -z "${KFS_CONFIG}" ]; then
    echo "KFS_CONFIG ：请设置 kfs 配置目录"
    exit 0
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mkdir -pv ${KFS_CONFIG}
cp -iv ${DIR}/pki_templates/* ${KFS_CONFIG}
