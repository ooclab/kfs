---
title: "Flannel in kubernetes"
weight: 82
pre: "<b>8.2 </b>"
date: 2019-05-03T17:00:00+08:00
draft: false
tags: ["v1.14.1", "kfs", "network", "flannel"]
---


## 部署 kube-flannel.yml

如果未部署 [Flannel From Scratch](/kfs/v1.14.1/flannel-from-scratch/) ，可以直接在集群中部署 flannel 。

```sh
# 下载最新的 kube-flannel.yml
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# 部署到 kubernetes
kubectl apply -f kube-flannel.yml
```

**说明**

1. 如果使用 `vagrant` 实验环境，需要在 `flanneld` 启动时使用 `--iface=eth1` 指定端口。编辑 `kube-flannel.yml` 配置文件。


## FAQ

### pod cidr not assigned

```
E0503 09:13:14.160194       1 main.go:289] Error registering network: failed to acquire lease: node "k8s-node-2" pod cidr not assigned
```
