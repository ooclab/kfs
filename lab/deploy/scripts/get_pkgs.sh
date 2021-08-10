#!/bin/bash

if [ -z "${KFS_PKGS}" ]; then
    echo "KFS_PKGS ：请设置 kfs 依赖软件包位置"
    exit 0
fi

mkdir -pv ${KFS_PKGS}

# https://github.com/etcd-io/etcd/releases
ETCD_VER=v3.4.16
# https://github.com/opencontainers/runc/releases
RUNC_VER=v1.0.0-rc94
# https://github.com/containernetworking/plugins/releases
CNI_PLUGINS_VER=v0.9.1
# https://github.com/kubernetes-sigs/cri-tools/releases
CRICTL_VER=v1.21.0
# https://github.com/containerd/containerd/releases
CONTAINERD_VER=1.5.1

pushd ${KFS_PKGS}

if ! test -f etcd-$ETCD_VER-linux-amd64.tar.gz; then
    wget https://github.com/etcd-io/etcd/releases/download/$ETCD_VER/etcd-$ETCD_VER-linux-amd64.tar.gz
fi

if ! test -f cni-plugins-linux-amd64-${CNI_PLUGINS_VER}.tgz; then
    wget https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VER}/cni-plugins-linux-amd64-${CNI_PLUGINS_VER}.tgz
fi

if ! test -f runc; then
    wget https://github.com/opencontainers/runc/releases/download/${RUNC_VER}/runc.amd64
    # 修改 runc 名称
    chmod a+x runc.amd64
    mv runc.amd64 runc
fi

if ! test -f crictl-${CRICTL_VER}-linux-amd64.tar.gz; then
    wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VER}/crictl-${CRICTL_VER}-linux-amd64.tar.gz
fi

if ! test -f containerd-${CONTAINERD_VER}.linux-amd64.tar.gz; then
    wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VER}/containerd-${CONTAINERD_VER}-linux-amd64.tar.gz
fi

popd
