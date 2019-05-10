---
title: "组件"
weight: 5
date: 2019-05-04T09:00:00+08:00
draft: false
tags: ["Kubernetes", "Components"]
---


## 参考

- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
- [A Complete Introduction to Kubernetes — an Orchestration Tool for Containers](https://dzone.com/articles/a-complete-introduction-to-kubernetes-an-orchestra)

## Components

![Kubernetes 结构图](/kubernetes/static/components.png)

### Kubernetes Master (控制节点)

![Kubernetes Master 结构](/kubernetes/static/kubernetes-master.png)

Master 包含一组应用程序（组件），通常部署在一台服务器上，也可以分别部署在多台服务器。

#### etcd

Kubernetes 集群数据全部存储在 etcd （通常是集群）中。

#### kube-apiserver

Kubernetes 集群对外 API 接口服务。

#### kube-scheduler

依据调度策略，为 Pod 分配可用的 Node 节点。

#### kube-controller-manager

运行一系列的 `controllers` 。

#### cloud-controller-manager

运行在一些云平台中，与之集成。

#### 进阶

如何创建高可用的 Kubernetes 集群？

- [Creating Highly Available Clusters with kubeadm](https://kubernetes.io/docs/setup/independent/high-availability/)

### Kubernetes Node (工作节点)

![Kubernetes Node 结构](/kubernetes/static/kubernetes-node.png)

Kubernetes Node 通常运行以下组件。

#### kubelet

集群中每一个 `Node` 都需要运行 kubelet 。kubelet 运行并管理有 Kubernetes 创建的 Pod 。

#### kube-proxy

Kubernetes 对于服务 (Service)的抽象网络，需要 kube-proxy 在 Node 上执行特定的规则才能生效。同时 kube-proxy 也提供转发服务。

#### Container Runtime

Kubernetes 支持：
- Docker
- containerd
- cri-o
- rktlet
- 任何支持 Kubernetes CRI (Container Runtime Interface) 标准的容器 Runtime
