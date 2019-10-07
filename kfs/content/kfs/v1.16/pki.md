---
title: "配置 PKI"
weight: 50
pre: "<b>5. </b>"
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["v1.15", "Kubernetes", "拓扑图"]
---

在 Kubernetes 集群中，各个组件间通过 TLS 进行通信。组件的证书可以代表其唯一性（ Common Name ）。搭建 PKI 可以自由签发证书给需要的组件。

## 初始化 CA

初始化 Certificate Authority ，创建 pki 目录：

```sh
mkdir -pv ${KFS_CONFIG}
cd ${KFS_CONFIG}
```

创建 `ca-config.json` ：

```json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
```

创建 `ca-csr.json` ：

```json
{
  "CN": "KFS",
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "O": "KFS",
      "OU": "CA",
      "ST": "BeiJing"
    }
  ]
}
```

创建 ca.pem 和 ca-key.pem ：
```sh
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

**提示** cfssl 可以查看指定证书详情

```sh
cfssl certinfo -cert ca.pem
```

## 一些客户端证书

### admin

创建 `admin-csr.json` :

```json
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "Kubernetes From Scratch",
      "ST": "BeiJing"
    }
  ]
}
```

创建 admin.pem 和 admin-key.pem ：
```sh
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```

### kubelet

**说明** 我们有2个节点，匹配创建脚本如下

```sh
NODES=$(cat <<-END
    master-1 192.168.0.188
    node-1 192.168.0.189
END
)

function genpem() {
    hostname=$1
    ip=$2
    echo $hostname $ip

    cat > ${hostname}-csr.json <<EOF
    {
      "CN": "system:node:${hostname}",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "L": "BeiJing",
          "O": "system:nodes",
          "OU": "Kubernetes From Scratch",
          "ST": "BeiJing"
        }
      ]
    }
EOF

    cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -hostname=${hostname},${ip} \
      -profile=kubernetes \
      ${hostname}-csr.json | cfssljson -bare ${hostname}
}

while read -r line; do
    a=($(echo "$line" | tr ' ' '\n'))
    hostname="${a[0]}"
    ip="${a[1]}"
    genpem $hostname $ip
done <<< "$NODES"
```

**说明**

1. 我们需要在 k8s-master-1 安装 flannel ，因此需要在 k8s-master-1 节点也部署 Node 角色的组件。所有这里创建它的 kubelet 证书。
2. 我们没有使用 `k8s-` 前缀的主机名，是因为实验中每个节点实际的 hostname 是 `master-1` , `node-1` , `node-2` （可以通过 kubelet 命令修改）。

### kube-controller-manager

创建 `kube-controller-manager-csr.json`

```json
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes From Scratch",
      "ST": "BeiJing"
    }
  ]
}
```

创建 kube-controller-manager.pem 和 kube-controller-manager-key.pem

```sh
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
```

### kube-proxy

创建 `kube-proxy-csr.json`

```json
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "O": "system:node-proxier",
      "OU": "Kubernetes From Scratch",
      "ST": "BeiJing"
    }
  ]
}
```

创建 kube-proxy.pem 和 kube-proxy-key.pem

```sh
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
```

### kube-scheduler

创建 `kube-scheduler-csr.json`

```json
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes From Scratch",
      "ST": "BeiJing"
    }
  ]
}
```

创建证书:

```sh
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
```

### kube-apiserver

检查 `$KFS_K8S_PUBLIC_ADDRESS` 的值是否设置正确：

```
# echo $KFS_K8S_PUBLIC_ADDRESS
192.168.1.61
# echo $KFS_K8S_EXTERNAL_PUBLIC_ADDRESS
k8s-1.example.com
```

创建 `kubernetes-csr.json` :

```json
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "O": "Kubernetes",
      "OU": "Kubernetes From Scratch",
      "ST": "BeiJing"
    }
  ]
}
```

创建证书：

```sh
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,${KFS_K8S_PUBLIC_ADDRESS},${KFS_K8S_EXTERNAL_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
```

### Service Account

创建 `service-account-csr.json` :

```json
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "O": "Kubernetes",
      "OU": "Kubernetes From Scratch",
      "ST": "BeiJing"
    }
  ]
}
```

创建证书：

```sh
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account
```
