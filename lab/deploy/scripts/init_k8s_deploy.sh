#!/bin/bash

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CLUSTER_NAME="$1"

INSTALL_DIR=${KFS_HOME}/kfslab
K8S_BIN_DIR="${INSTALL_DIR}/k8s/bin"
PKG_DIR="${INSTALL_DIR}/pkgs"

if [ -z "$CLUSTER_NAME" ]; then
    echo "Usage: $0 CLUSTER_NAME"
    exit 1
fi

echo -e "当前目录 $ROOT_DIR\n配置目录 $CLUSTER_NAME"

if [ -n "$(ls -A $INSTALL_DIR > /dev/null 2>&1 )" ]; then
   echo "初始化目录 \"$INSTALL_DIR\" 非空！如果确定继续，请手动删除该目录。"
   exit 1
fi

echo "初始化目录 $INSTALL_DIR"
mkdir -pv $INSTALL_DIR

echo "拷贝 ansible 模版"
cp -av ${ROOT_DIR}/ansible $INSTALL_DIR/

mkdir -pv $K8S_BIN_DIR $PKG_DIR
${DIR}/copy_pki_config.sh
${DIR}/copy_k8s_bins.sh
# ${DIR}/get_pkgs.sh
