---
title: "准备工作"
weight: 11
pre: "<b>3. </b>"
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["v1.14.1", "Kubernetes", "prepare"]
---


## 准备

### SSH

在 **mbp** 配置 **~/.ssh/config** , 确保相关服务器可以公钥免密登录，如：登录 **hk-1**

```
ssh hk-1
```

## 下载

### Kubernetes

登录 **hk-1** 服务器，下载 Kuberentes：

1. 从 [https://github.com/kubernetes/kubernetes/releases](https://github.com/kubernetes/kubernetes/releases) 选择一个合适的版本
2. 下载指定的版本，本次实验使用 `v1.14.1`

```sh
# 创建一个和版本名称一样的子目录
mkdir -pv ~/k8s/v1.14.1
cd ~/k8s/v1.14.1/
# 下载
wget https://github.com/kubernetes/kubernetes/releases/download/v1.14.1/kubernetes.tar.gz
# 解压
tar xf kubernetes.tar.gz
# 下载 Kubernetes 二进制文件
cd kubernetes/cluster/
./get-kube-binaries.sh
# 上面命令提示下载位置，输入 y 以示确认
```

下载完成后，拷贝 **hk-1** 服务器上的 **v1.14.1** 目录到 **mbp** 的 **$KFS_HOME** ，在 **mbp** 执行：

```bash
# hk-1 是我在香港的服务器
cd $KFS_HOME
mkdir -pv $KFS_K8S_PKG_DIR
rsync -avz --progress hk-1:~/k8s/v1.14.1 $KFS_K8S_PKG_DIR
# 解压二进制程序
cd $KFS_K8S_PKG_DIR/kubernetes/server
tar xf kubernetes-server-linux-amd64.tar.gz
```

同步完成后，拷贝 master , node 需要的二进制程序：

```sh
# 创建目录
mkdir -pv ${KFS_INSTALL}/{master,node}/bin
cd $KFS_K8S_PKG_DIR/kubernetes/server/kubernetes/server/bin/
# 拷贝 master 需要的二进制程序
cp kubectl kube-apiserver kube-scheduler kube-controller-manager ${KFS_INSTALL}/master/bin/
# 拷贝 node 需要的二进制程序
cp kubectl kubelet kube-proxy ${KFS_INSTALL}/node/bin
```

### etcd

从 [https://github.com/etcd-io/etcd/releases](https://github.com/etcd-io/etcd/releases) 下载合适的版本，以 `v3.3.12` 为例：

```sh
mkdir -pv ${KFS_INSTALL}/master/bin
ETCD_VER=v3.3.12

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GITHUB_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

# 复制到 master/bin
cp /tmp/etcd-download-test/etcd* ${KFS_INSTALL}/master/bin/
```

### cfssl

在 mbp 执行：

```sh
brew install cfssl
```

### kubectl

MacOS 上如果安装了 Docker , 默认已经有 `kubectl` 命令（但是通常版本比较旧）：

```sh
ls -al /usr/local/bin/kubectl
lrwxr-xr-x  1 gwind  staff  55 Jan 25 20:45 /usr/local/bin/kubectl -> /Applications/Docker.app/Contents/Resources/bin/kubectl
```

我们可以重新安装最新的 kubectl ：

```sh
brew install kubernetes-cli
# 覆盖 docker 安装的版本
brew link --overwrite kubernetes-cli
# 检查版本
kubectl version
```

### vagrant & virtualbox & ansible

```sh
brew cask install virtualbox
brew cask install vagrant
brew cask install vagrant-manager
brew install ansible
```
