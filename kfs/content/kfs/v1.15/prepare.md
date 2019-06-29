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
mkdir -pv ~/k8s/v1.15.0-beta.2
cd ~/k8s/v1.15.0-beta.2/
# 下载
wget https://github.com/kubernetes/kubernetes/releases/download/v1.15.0-beta.2/kubernetes.tar.gz
# 解压
tar xf kubernetes.tar.gz
# 下载 Kubernetes 二进制文件
cd kubernetes/cluster/
./get-kube-binaries.sh
# 上面命令提示下载位置，输入 y 以示确认
```

下载完成后，拷贝 **hk-1** 服务器上的 **v1.15.0-beta.2** 目录到 **ooclab** 的 **$KFS_HOME** ，在 **ooclab** 执行：

```bash
# hk-1 是我在香港的服务器
cd $KFS_HOME
mkdir -pv $KFS_K8S_PKG_DIR
rsync -avz --progress hk-1:~/k8s/${KFS_K8S_VERSION} $KFS_K8S_PKG_DIR
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
# 拷贝 ooclab 需要的 kubectl
cp kubectl /usr/local/bin/
```

### etcd

从 [https://github.com/etcd-io/etcd/releases](https://github.com/etcd-io/etcd/releases) 下载合适的版本，以 `v3.3.12` 为例：

```sh
ETCD_VER=v3.3.13

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

### Node 组件

**说明** 在 **ooclab** 下载需要的软件包到 `$KFS_INSTALL/node` 目录。

- [runc](https://github.com/opencontainers/runc/releases)
- [CNI plugins](https://github.com/containernetworking/plugins/releases)
- [cri-tools](https://github.com/kubernetes-sigs/cri-tools/releases)
- [containerd](https://github.com/containerd/containerd/releases)

```sh
mkdir -p $KFS_INSTALL/node/bin
cd $KFS_INSTALL/node
wget -q --show-progress --https-only --timestamping \
    https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
    https://github.com/containernetworking/plugins/releases/download/v0.8.1/cni-plugins-linux-amd64-v0.8.1.tgz \
    https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.14.0/crictl-v1.14.0-linux-amd64.tar.gz \
    https://github.com/containerd/containerd/releases/download/v1.2.7/containerd-1.2.7.linux-amd64.tar.gz
    
chmod a+x runc.amd64
mv runc.amd64 bin/runc
```

说明：

1. `--show-progress --https-only` 选项在 wget `1.20` 及以上版本测试可以，如果环境中的 wget 版本不支持，可以去掉。
2. 下载的 image 很可能应为网络问题，出现中断。可以做下一致性校验。比如： [cni-plugins-linux-amd64-v0.8.1.tgz.sha1](https://github.com/containernetworking/plugins/releases/download/v0.8.1/cni-plugins-linux-amd64-v0.8.1.tgz.sha1)

### golang

我们需要使用 golang 编译一些软件包，如 cfssl 。因此需要先安装好 golang 程序。


需要代理，在 hk-1 下载

```sh
cd /tmp/
wget https://dl.google.com/go/go1.12.5.linux-amd64.tar.gz
```

从 hk-1 拷贝到 ooclab, 在 ooclab 执行：

```sh
cd $KFS_INSTALL
rsync -avz --progress hk-1:/tmp/go1.12.5.linux-amd64.tar.gz .
tar -C /usr/local -xzf go1.12.5.linux-amd64.tar.gz
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
