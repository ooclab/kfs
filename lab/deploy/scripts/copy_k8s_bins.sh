#!/bin/bash

if [ -z "${KFS_HOME}" ]; then
    echo "KFS_HOME ：请设置 kfs 安装主目录"
fi

if [ -z "${K8S_PKG_DIR}" ]; then
    echo "KFS_K8S_PKG_DIR ：请设置 k8s 二进制包目录"
fi

pushd $KFS_HOME
mkdir -pv kfslab/k8s/bin
for name in kubectl kube-apiserver kube-scheduler kube-controller-manager kubelet kube-proxy; do
    cp -v ${K8S_PKG_DIR}/server/kubernetes/server/bin/${name} kfslab/k8s/bin/
done
popd
