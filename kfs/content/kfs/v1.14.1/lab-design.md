---
title: "实验环境规划"
weight: 9
pre: "<b>1. </b>"
date: 2019-05-04T12:40:00+08:00
draft: false
tags: ["v1.14.1", "design"]
---

![实验环境拓扑图](/kfs/v1.14.1/static/lab-topo.png)

### hk-1

位于阿里云香港区的一台 VPS 。

**配置**

- 1核 CPU
- 512M 内存
- 按流量计费带宽

**用途**

- Google
- 下载软件包，如 `kubernetes`
- 传递一些无法访问的 image ，参考 [DOCKER IMAGE 在QIANG外怎么办？](/posts/docker-image-gfw/)

### mbp

实验用的 Macbook Pro 。

**配置**

- 16G 内存

**说明**

1. 如无特殊说明， `kubectl` 命令的执行都在 **mbp** （通过配置 `$KUBECONFIG` 环境变量指向 `admin-mbp.kubeconfig` 路径实现访问集群的许可）

### 虚拟机

在 mbp 上，通过 vagrant + virtualbox 运行实验需要的 3 台虚拟机。

| 主机名 | IP | 配置 | 角色 | 说明 |
|-------|----|------|------|-----|
| k8s-master-1 | 192.168.100.11 | 2核CPU，2048M 内存 | Master | 部署 Kubernetes Master 组件 |
| k8s-node-1 | 192.168.100.31 |2核CPU，2048M 内存 | Node | 部署 Kubernetes Node 组件 |
| k8s-node-2 | 192.168.100.32 |2核CPU，2048M 内存 | Node | 同上 |

Master 角色虚拟机需要安装：

- etcd
- kube-apiserver
- kube-controller-manager
- kube-scheduler
- flanneld

Node 角色虚拟机需要安装：

- kubelet
- kube-proxy
- containerd
- flanneld
