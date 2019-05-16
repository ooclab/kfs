---
title: "实验环境规划"
weight: 9
pre: "<b>1. </b>"
date: 2019-05-04T12:40:00+08:00
draft: false
tags: ["v1.15", "design"]
---

![实验环境拓扑图](/kfs/v1.15/static/lab-topo.png)

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

### ooclab

实验用的工作站，通过 libvirtd + qemu + kvm 运行 3 个 KVM 虚拟机作为 K8S 实验机器。

**配置**

- 16G 内存

**说明**

1. 如无特殊说明， `kubectl` 命令的执行都在 **ooclab** （通过配置 `$KUBECONFIG` 环境变量指向 `admin-ooclab.kubeconfig` 路径实现访问集群的许可）

### 虚拟机

在 ooclab 上，通过 libvirtd + qemu + kvm 运行实验需要的 3 台虚拟机。

| 主机名 | IP | 配置 | 角色 | 说明 |
|-------|----|------|------|-----|
| k8s-master-1 | 192.168.1.61 | 2核CPU，2048M 内存 | Master | 部署 Kubernetes Master 组件，同时部署 Node 组件 |
| k8s-node-1 | 192.168.1.71 |2核CPU，4096M 内存 | Node | 部署 Kubernetes Node 组件 |
| k8s-node-2 | 192.168.1.72 |2核CPU，4096M 内存 | Node | 同上 |

Master 角色虚拟机需要安装：

- etcd
- kube-apiserver
- kube-controller-manager
- kube-scheduler

Node 角色虚拟机需要安装：

- kubelet
- kube-proxy
- containerd

**说明** :

1. k8s-master-1 节点同时部署 Master 和 Node 2 种角色的组件，主要原因是希望通过 Kubernetes 管理 DaemonSet 组件，如： flanneld 。
