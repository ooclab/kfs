---
title: "Flannel"
weight: 91
pre: "<b>9.1 </b>"
date: 2019-05-16T11:00:00+08:00
draft: false
tags: ["v1.15", "kfs", "network", "flannel"]
---


## 部署 kube-flannel.yml

如果未部署 [Flannel From Scratch](/kfs/v1.14.1/flannel-from-scratch/) ，可以直接在集群中部署 flannel 。

```sh
# 下载最新的 kube-flannel.yml
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# 部署到 kubernetes
kubectl apply -f kube-flannel.yml
```

查看部署结果：

```
$ kubectl get all --all-namespaces -o wide
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE    IP             NODE     NOMINATED NODE   READINESS GATES
kube-system   pod/kube-flannel-ds-amd64-jh8mb   1/1     Running   0          111s   192.168.1.71   node-1   <none>           <none>
kube-system   pod/kube-flannel-ds-amd64-s8shn   1/1     Running   0          111s   192.168.1.72   node-2   <none>           <none>

NAMESPACE   NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE    SELECTOR
default     service/kubernetes   ClusterIP   10.32.0.1    <none>        443/TCP   154m   <none>

NAMESPACE     NAME                                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                     AGE    CONTAINERS     IMAGES                                   SELECTOR
kube-system   daemonset.apps/kube-flannel-ds-amd64     2         2         2       2            2           beta.kubernetes.io/arch=amd64     111s   kube-flannel   quay.io/coreos/flannel:v0.11.0-amd64     app=flannel,tier=node
kube-system   daemonset.apps/kube-flannel-ds-arm       0         0         0       0            0           beta.kubernetes.io/arch=arm       111s   kube-flannel   quay.io/coreos/flannel:v0.11.0-arm       app=flannel,tier=node
kube-system   daemonset.apps/kube-flannel-ds-arm64     0         0         0       0            0           beta.kubernetes.io/arch=arm64     111s   kube-flannel   quay.io/coreos/flannel:v0.11.0-arm64     app=flannel,tier=node
kube-system   daemonset.apps/kube-flannel-ds-ppc64le   0         0         0       0            0           beta.kubernetes.io/arch=ppc64le   111s   kube-flannel   quay.io/coreos/flannel:v0.11.0-ppc64le   app=flannel,tier=node
kube-system   daemonset.apps/kube-flannel-ds-s390x     0         0         0       0            0           beta.kubernetes.io/arch=s390x     111s   kube-flannel   quay.io/coreos/flannel:v0.11.0-s390x     app=flannel,tier=node
```

**说明**

1. 如果使用 `vagrant` 实验环境，需要在 `flanneld` 启动时使用 `--iface=eth1` 指定端口。编辑 `kube-flannel.yml` 配置文件。
