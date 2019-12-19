---
title: "准备工作"
weight: 11
pre: "<b>3. </b>"
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["v1.15", "Kubernetes", "prepare"]
---


## 准备

### SSH

在 **ooclab** 配置 **~/.ssh/config** , 确保相关服务器可以公钥免密登录，如：登录 **hk-1**

```
ssh hk-1
```

## 下载

### Kubernetes

登录 **hk-1** 服务器，下载 Kuberentes：

1. 从 [https://github.com/kubernetes/kubernetes/releases](https://github.com/kubernetes/kubernetes/releases) 选择一个合适的版本
2. 下载指定的版本，本次实验使用 `v1.15.0-beta.2`（$KFS_K8S_VERSION）

```sh
# 创建一个和版本名称一样的子目录
mkdir -pv ~/k8s/v1.17.0-rc.1
cd ~/k8s/v1.17.0-rc.1/
# 下载
wget https://github.com/kubernetes/kubernetes/releases/download/v1.17.0-rc.1/kubernetes.tar.gz
# 解压
tar xf kubernetes.tar.gz
# 下载 Kubernetes 二进制文件
cd kubernetes/cluster/
./get-kube-binaries.sh
# 上面命令提示下载位置，输入 y 以示确认
```

下载完成后，拷贝 **hk-1** 服务器上的 **v1.17.0-rc.1** 目录到 **mbp** 的 **$KFS_HOME** ，在 **mbp** 执行：

```bash
# hk-1 是我在香港的服务器
cd $KFS_HOME
mkdir -pv $KFS_K8S_PKG_DIR
rsync -avz --progress hk-1:~/k8s/${KFS_K8S_VERSION}/ $KFS_K8S_PKG_DIR/
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
cp kubelet kube-proxy ${KFS_INSTALL}/node/bin
```

### etcd

从 [https://github.com/etcd-io/etcd/releases](https://github.com/etcd-io/etcd/releases) 下载合适的版本，以 `v3.4.3` 为例：

```sh
ETCD_VER=v3.4.3
cd $KFS_INSTALL/master
wget https://github.com/etcd-io/etcd/releases/download/$ETCD_VER/etcd-$ETCD_VER-linux-amd64.tar.gz
tar xzvf etcd-$ETCD_VER-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
cp /tmp/etcd-download-test/etcd* ${KFS_INSTALL}/master/bin/
```

### Node 组件

**说明** 在 **ooclab** 下载需要的软件包到 `$KFS_INSTALL/node` 目录。

- [CNI plugins](https://github.com/containernetworking/plugins/releases)

```sh
mkdir -p $KFS_INSTALL/node/bin
cd $KFS_INSTALL/node
wget https://github.com/containernetworking/plugins/releases/download/v0.8.3/cni-plugins-linux-amd64-v0.8.3.tgz
wget https://github.com/opencontainers/runc/releases/download/v1.0.0-rc9/runc.amd64
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.16.1/crictl-v1.16.1-linux-amd64.tar.gz
wget https://github.com/containerd/containerd/releases/download/v1.3.1/containerd-1.3.1.linux-amd64.tar.gz
# 修改 runc 名称
chmod a+x runc.amd64
mv runc.amd64 bin/runc
```

### golang

我们需要使用 golang 编译一些软件包，如 cfssl 。因此需要先安装好 golang 程序。


需要代理，在 hk-1 下载

```sh
cd /tmp/
wget https://dl.google.com/go/go1.13.4.linux-amd64.tar.gz
```

从 hk-1 拷贝到 ooclab, 在 ooclab 执行：

```sh
cd $KFS_INSTALL
rsync -avz --progress hk-1:/tmp/go1.13.4.linux-amd64.tar.gz .
tar -C /usr/local -xzf go1.13.4.linux-amd64.tar.gz
```

设置 PATH ：

```sh
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc
go version
```

### cfssl

在 ooclab 执行：

```sh
go get -v -u github.com/cloudflare/cfssl/cmd/...
```

如果未设置 $GOPATH , 且 $GOPATH/bin 不在 $PATH 中，可以这样设置：

```sh
echo "export PATH=$PATH:~/go/bin" >> ~/.bashrc
source ~/.bashrc
```

现在执行 `cfssl` 命令应该可以找到。

### ansible

在 ooclab 执行：

```sh
dnf install ansible
ansible-galaxy install geerlingguy.repo-epel
```

### runsc

如果想测试 runsc ，请查看 https://github.com/google/gvisor
