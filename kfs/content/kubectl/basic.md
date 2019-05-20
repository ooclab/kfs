---
title: "kubectl 基本用法"
weight: 7
date: 2019-05-16T20:00:00+08:00
draft: false
tags: ["Kubernetes", "kubectl"]
---

`kubectl` 是 Kubernetes 的一个命令行工具，可以执行各种操作。目标是成为 `git` 一样的使用方法（风格），和一样的领域地位的工具。

- [官方文档](https://kubectl.docs.kubernetes.io/)

## 配置

默认访问配置文件路径是 `~/.kube/config`

## 基本信息

### 版本

```
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.1", GitCommit:"b7394102d6ef778017f2ca4046abbaa23b88c290", GitTreeState:"clean", BuildDate:"2019-04-19T22:12:47Z", GoVersion:"go1.12.4", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"15+", GitVersion:"v1.15.0-alpha.3", GitCommit:"95eb3a67020f6eabef08c3e9caf348149f469798", GitTreeState:"clean", BuildDate:"2019-05-07T18:09:03Z", GoVersion:"go1.12.4", Compiler:"gc", Platform:"linux/amd64"}
```

### 集群信息

```
$ kubectl cluster-info
Kubernetes master is running at https://192.168.1.61:6443
CoreDNS is running at https://192.168.1.61:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```
