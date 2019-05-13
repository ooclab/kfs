---
title: "Flannel From Scratch"
weight: 81
pre: "<b>8.1 </b>"
date: 2019-04-30T10:00:00+08:00
draft: false
tags: ["v1.14.1", "kfs", "network", "flannel"]
---

## 简介

本章介绍手动部署 flanneld 的方法。

![](/kfs/v1.14.1/static/flannel.png)

说明：

1. `flanneld` 在每个 host 上部署，通常我们会在集群的所有节点上部署。
2. 所有 `flanneld` 之间通过 etcd 共享分布式配置，比如每个主机的 "子网段" 是多少。
3. `containerd` 通过 **cni** 机制从本机的 `flanneld` 管理的 “子网段” 中为即将运行的 **container** 拿到网络配置。
4. 所有使用了 `flanneld` 管理的网络内的 **container** 即可属于同一个网络。

## 准备

### 下载 flannel

请在 **mbp** 上执行：

```sh
cd $KFS_INSTALL/node
wget -q --show-progress --https-only --timestamping \
    https://github.com/coreos/flannel/releases/download/v0.11.0/flanneld-amd64 \
    https://github.com/coreos/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-amd64.tar.gz
```


## 创建 `flanneld` 证书

与 `etcd` 通信需要。

创建 `flanneld-csr.json` ，请在 **mbp** 上执行：

```sh
cd $KFS_CONFIG

cat > flanneld-csr.json <<EOF
{
  "CN": "system:flanneld",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "O": "system:flanneld",
      "OU": "Kubernetes From Scratch",
      "ST": "BeiJing"
    }
  ]
}
EOF
```

创建证书 ：

```sh
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  flanneld-csr.json | cfssljson -bare flanneld
```

## 部署

请在任何需要 flanneld 的节点上执行部署操作。比如： `k8s-master-1` , `k8s-node-1`, `k8s-node-2`

### 准备证书

复制证书到需要的每个节点上 `/etc/flanneld` 目录，以 `k8s-master-1` 节点为例：

```sh
mkdir -pv /etc/flanneld/
cd $KFS_HOME/config
cp ca.pem flanneld.pem flanneld-key.pem /etc/flanneld/
```

### 配置 etcd

在 etcd 中配置网络是一次性的，只需要集群搭建之处执行一次。

在 `k8s-master-1` 机器执行：

```sh
unset ETCDCTL_API
etcdctl \
  --endpoints=https://192.168.100.11:2379 \
  --ca-file /etc/flanneld/ca.pem \
  --cert-file /etc/flanneld/flanneld.pem \
  --key-file /etc/flanneld/flanneld-key.pem \
  set /coreos.com/network/config '{ "Network": "172.16.0.0/16", "Backend": {"Type": "vxlan"}}'
```

**注意** 目前 flanneld 还不支持 etcd v3 协议，所以我们需要用旧的协议写入网络配置。

### 启动 flanneld

拷贝 `flanneld` 程序：

```sh
cd $KFS_INSTALL/node
chmod a+x flanneld-amd64
cp flanneld-amd64 /usr/local/bin/flanneld
```

创建 `flanneld.service` :

```sh
ETCD_SERVERS=${1:-"https://192.168.100.11:2379"}
FLANNEL_NET=${2:-"172.16.0.0/16"}

CA_FILE="/etc/flanneld/ca.pem"
CERT_FILE="/etc/flanneld/flanneld.pem"
KEY_FILE="/etc/flanneld/flanneld-key.pem"

cat <<EOF >/etc/flanneld/flannel
FLANNEL_ETCD="--etcd-endpoints=${ETCD_SERVERS}"
FLANNEL_ETCD_KEY="--etcd-prefix=/coreos.com/network"
FLANNEL_ETCD_CAFILE="--etcd-cafile=${CA_FILE}"
FLANNEL_ETCD_CERTFILE="--etcd-certfile=${CERT_FILE}"
FLANNEL_ETCD_KEYFILE="--etcd-keyfile=${KEY_FILE}"
EOF

cat <<EOF >/usr/lib/systemd/system/flanneld.service
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
Before=containerd.service

[Service]
EnvironmentFile=-/etc/flanneld/flannel
ExecStart=/usr/local/bin/flanneld --iface eth1 --ip-masq \${FLANNEL_ETCD} \${FLANNEL_ETCD_KEY} \${FLANNEL_ETCD_CAFILE} \${FLANNEL_ETCD_CERTFILE} \${FLANNEL_ETCD_KEYFILE}

Type=notify

[Install]
WantedBy=multi-user.target
RequiredBy=containerd.service
EOF
```

**说明**

1. Vagrant 环境需要使用 `--iface eth1` 指定端口，否则所有 flanneld 获取的子网都一样。[Running on Vagrant](https://github.com/coreos/flannel/blob/master/Documentation/running.md#running-on-vagrant)
2. `FLANNEL_NET` 要和 `kube-controller-manager` 中的 `--cluster-cidr` 和 `kubelet` 配置文件中的 `podCIDR` 保持一致。

> Vagrant has a tendency to give the default interface (one with the default route) a non-unique IP (often 10.0.2.15).
> This causes flannel to register multiple nodes with the same IP.
> To work around this issue, use --iface option to specify the interface that has a unique IP.
> If you're running on CoreOS, use cloud-config to set coreos.flannel.interface to $public_ipv4.

重启服务：
```sh
systemctl daemon-reload
systemctl start flanneld
```

### 检查 flanneld

检查服务状态：

```sh
# 服务状态应该是 active (running)
systemctl status flanneld
# 下面文件应该已经获取了可用的网络端配置信息
cat /run/flannel/subnet.env
```

检查 IP 是否能 ping 通：

1. 在任意一个节点查看 ip 信息（ `ip addr show flannel.1 | grep 172` ），如得到 ip `172.16.55.0`
2. 到另外一个节点 ping 该 ip ： `ping 172.16.55.0`
3. 如果能 ping 通，说明 flanneld 服务配置正确


## Flannel 管理

**注意** 本实验部署的 etcd 服务器访问需要配置权限

```
etcdctl --endpoints=https://192.168.100.11:2379 \
  --ca-file /etc/flanneld/ca.pem \
  --cert-file /etc/flanneld/flanneld.pem \
  --key-file /etc/flanneld/flanneld-key.pem \
  get /coreos.com/network/config
```

下面示例省略 etcdctl 的一些配置选项。

```
# 查看 flanneld 网络配置
etcdctl get /coreos.com/network/config
# 查看子网设置
etcdctl ls /coreos.com/network/subnets
# 查看其中之一的子网
etcdctl get /coreos.com/network/subnets/172.16.2.0-24
# 获取更多信息
etcdctl -o extended get /coreos.com/network/subnets/172.16.2.0-24
```

## FAQ

### 为何手动部署 flannel ?

1. KFS 的宗旨是从零部署，加深理解。
2. 我们希望 `master` 和 `node` 节点都可以相互 `ping` 通，方便从 `master` 管理各个节点。手动部署 flannel 比较简单，只需在 `master` 也启动一个 `flanneld` 即可。

### 为何 flanneld 获取的子网会变化

超过一定时间，重启服务，子网可能会发生变化。参考 [Leases and Reservations](https://github.com/coreos/flannel/blob/master/Documentation/reservations.md)

生产环境建议在 kubernetes 部署 flanneld。

示例：查看实验环境的某个 flanneld 获取的子网信息

```sh
etcdctl ls /coreos.com/network/subnets
etcdctl -o extended get /coreos.com/network/subnets/172.16.2.0-24
```

子网信息如下：

```
Key: /coreos.com/network/subnets/172.16.2.0-24
Created-Index: 13
Modified-Index: 13
TTL: 49468
Index: 18

{"PublicIP":"192.168.100.31","BackendType":"vxlan","BackendData":{"VtepMAC":"d6:a2:7e:e0:9c:6e"}}
```

**说明**

1. `TTL` 是租期（秒数），到期前 flanneld 会续租
2. `PublicIP` 是 flanneld 的公网 IP，如果变化，则子网会重新分配
3. 如果 flanneld 续租失败，会尝试通过 `/var/run/flannel/subnet.env` 文件中的信息，续租。再次失败，则重新申请子网。

#### 如何保留子网租期

设置 TTL 为 0 即可：

```
etcdctl set -ttl 0 /coreos.com/network/subnets/172.16.2.0-24 $(etcdctl get /coreos.com/network/subnets/172.16.2.0-24)
```

## 参考

- [Running flannel](https://github.com/coreos/flannel/blob/master/Documentation/running.md)
