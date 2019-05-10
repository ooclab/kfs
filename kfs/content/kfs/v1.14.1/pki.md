---
title: "配置 PKI"
weight: 50
pre: "<b>5. </b>"
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["v1.14.1", "Kubernetes", "拓扑图"]
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
    "size": 2048
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
    "size": 2048
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
    k8s-node-1 192.168.100.31
    k8s-node-2 192.168.100.32
END
)

function genpem() {
    name=$1
    ip=$2
    echo $ip $hostname

    cat > ${name}-csr.json <<EOF
    {
      "CN": "system:node:${name}",
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
      -hostname=${name},${ip} \
      -profile=kubernetes \
      ${name}-csr.json | cfssljson -bare ${name}
}

while read -r line; do
    a=($(echo "$line" | tr ' ' '\n'))
    name="${a[0]}"
    ip="${a[1]}"
    genpem $ip $name
done <<< "$NODES"
```

生成

```
➜  pki ls -al k8s-node-*.pem
-rw-------  1 gwind  staff  1679 May  8 18:03 k8s-node-1-key.pem
-rw-r--r--  1 gwind  staff  1468 May  8 18:03 k8s-node-1.pem
-rw-------  1 gwind  staff  1679 May  8 18:03 k8s-node-2-key.pem
-rw-r--r--  1 gwind  staff  1468 May  8 18:03 k8s-node-2.pem
```

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
KUBERNETES_PUBLIC_ADDRESS="192.168.100.11"

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
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

## 分发到各个服务器

`k8s-master-1` 需要：

- ca.pem
- ca-key.pem
- kubernetes.pem
- kubernetes-key.pem
- kube-controller-manager.pem
- kube-controller-manager-key.pem
- kube-scheduler.pem
- kube-scheduler-key.pem
- service-account.pem
- service-account-key.pem

`k8s-node-1` , `k8s-node-2` 需要：

- ca.pem
- k8s-node-{N}.pem
- k8s-node-{N}-key.pem
- kube-proxy.pem
- kube-proxy-key.pem

**注意** 

1. 我们挂载了 Host 的 `$KFS_HOME` 到每一个 Guest 虚拟机的 `/kfslab` 目录。因此只需要到时候系统内 copy 即可。生产环境请在部署完成后，确保 node 上只包含自己需要的证书，确保安全。