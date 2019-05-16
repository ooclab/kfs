---
title: "kubectl"
weight: 7
date: 2019-04-29T13:00:00+08:00
draft: false
tags: ["Kubernetes", "kubectl"]
---

`kubectl` 是 Kubernetes 的一个命令行工具，可以执行各种操作。目标是成为 `git` 一样的使用方法（风格），和一样的领域地位的工具。

- [官方文档](https://kubectl.docs.kubernetes.io/)

```sh
brew link --overwrite kubernetes-cli
# 覆盖 docker 安装的版本
brew link --overwrite kubernetes-cli
# 检查版本
kubectl version
```

## Tips

### 设置默认的配置文件

```sh
export KUBECONFIG="/path/to/my.kubeconfig"
kubectl get all --all-namespaces
```

### taint

```
# 设置 taint
kubectl taint nodes node1 key1=value1:NoSchedule

# 去除 taint
kubectl taint nodes node1 key1:NoSchedule-
```

如 master 不可调度的特性管理：

```
# 设置
kubectl taint nodes 节点名 node-role.kubernetes.io/master=:NoSchedule
# 移除
kubectl taint nodes 节点名 node-role.kubernetes.io/master:NoSchedule-
```
