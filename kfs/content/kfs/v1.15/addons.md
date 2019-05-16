---
title: "Addons"
weight: 90
pre: "<b>9. </b>"
date: 2019-05-16T11:00:00+08:00
draft: false
tags: ["v1.15", "kfs", "addons"]
---


## 说明

从现在开始，我们主要使用 kubectl 命令访问集群。无论从哪台服务器访问集群，请配置好相关的访问权限即可。

无如特殊说明，我们现在从 **ooclab** 或 **mbp** 等集群外部执行 `kubectl` 命令。

请创建 `addons` 目录，默认我们将一些资源放在这里：

```sh
export KFS_HOME=~/kfslab
mkdir -pv ${KFS_HOME}/addons
cd ${KFS_HOME}/addons
```

### 设置 master-1 节点

#### taint

为了网络打通，我们在 k8s-master-1 节点上也部署了 Node 角色组件，但是我们不希望工作负载调度到该节点。执行下面设置即可：

```sh
kubectl patch node master-1 -p '{"spec":{"taints":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master"}]}}'
```

或者使用 taint 管理：

```sh
kubectl taint nodes master-1 node-role.kubernetes.io/master=:NoSchedule
```

查看 taint 设置：

```
$ kubectl describe node master-1|grep -i taints
Taints:             node-role.kubernetes.io/master:NoSchedule
```

#### label

```
# 设置 label
kubectl label node master-1 node-role.kubernetes.io/master=
# 移除 label
kubectl label node master-1 node-role.kubernetes.io/master-
```
