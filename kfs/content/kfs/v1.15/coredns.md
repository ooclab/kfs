---
title: "CoreDNS"
weight: 92
pre: "<b>9.2 </b>"
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["v1.15", "kfs", "dns", "coredns", "addons"]
---

[CoreDNS](https://coredns.io/) 可以提供基于域名的服务访问。从 [Kubernetes 1.13](https://kubernetes.io/blog/2018/12/03/kubernetes-1-13-release-announcement/) 开始，**CoreDNS** 作为默认的 DNS（之前是 **kube-dns** ）。

- [https://github.com/coredns/coredns](https://github.com/coredns/coredns)

**提示** ：在 **mbp** 执行操作

## 部署 CoreDNS

进入 `kubernetes/cluster/addons/dns/coredns` 目录：

```sh
cd $KFS_HOME/$KFS_K8S_VERSION/kubernetes/cluster/addons/dns/coredns
```


创建 `coredns.yaml`

```sh
export DNS_SERVER_IP="10.32.0.10"
export DNS_DOMAIN="cluster.local"
sed \
  -e 's/__PILLAR__DNS__SERVER__/'$DNS_SERVER_IP'/g' \
  -e 's/__PILLAR__DNS__DOMAIN__/'$DNS_DOMAIN'/g' \
  -e 's/__PILLAR__DNS__MEMORY__LIMIT__/70Mi/g' \
  -e 's/k8s.gcr.io/coredns/g' \
  coredns.yaml.base > coredns.yaml
```

应用 `coredns.yaml` :
```sh
kubectl apply -f coredns.yaml
```

查看 kubernetes 信息：

```
$ kubectl get pod --all-namespaces -o wide
NAMESPACE     NAME                          READY   STATUS    RESTARTS   AGE   IP             NODE     NOMINATED NODE   READINESS GATES
kube-system   coredns-f764bd964-rzwht       1/1     Running   0          53s   172.16.0.2     node-1   <none>           <none>
kube-system   kube-flannel-ds-amd64-klkd2   1/1     Running   0          78s   192.168.1.71   node-1   <none>           <none>
kube-system   kube-flannel-ds-amd64-rbch6   1/1     Running   0          78s   192.168.1.72   node-2   <none>           <none>
```

**重要** 我们看到 coredns 分配到了IP。现在请在各个节点执行 `ping 172.16.0.2` 的测试，如果不能 ping ，请检查防火墙配置。


## 测试 DNS 服务是否 OK

### 方法一

```sh
# 运行一个 busybox
kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
# 查看 pods
kubectl get pods -l run=busybox
# 获取 POD_NAME
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
# 通过 nslookup 查看 DNS 服务是否正确
kubectl exec -ti $POD_NAME -- nslookup kubernetes
```

返回结果如下：

```
Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
```

### 方法二

在 master-1 节点的 `/etc/resolv.conf` 文件最前面加入如下行：

```
nameserver 10.32.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
```

安装 bind-utils 软件

```
yum install bind-utils
```

使用 nslookup 查询域名：

```
# nslookup kubernetes
Server:         10.32.0.10
Address:        10.32.0.10#53

Non-authoritative answer:
Name:   kubernetes.default.svc.cluster.local
Address: 10.32.0.1
```

## FAQ

### dial tcp: lookup node-2 on 192.168.1.1:53: no such host

测试 coredns 服务是否正确过程中，我们执行测试：

```sh
kubectl exec -ti $POD_NAME -- nslookup kubernetes
```

出现如下错误：

```
Error from server: error dialing backend: dial tcp: lookup node-2 on 192.168.1.1:53: no such host
```

原因是 `node-2` 主机名称没有通过 `192.168.1.1:53` 域名服务器查找到。`192.168.1.1:53` 是局域网环境默认的 DNS 服务器。
即所有主机需要能否知道所有的节点自定义主机名（如：`master-1`, `node-1`, `node-2`等）的对应 IP。

#### 方法一：手动维护 `/etc/hosts`

在 `k8s-master-1` 节点的 `/etc/hosts` 增加：

```
192.168.1.61 master-1
192.168.1.71 node-1
192.168.1.72 node-2
```

### error: unable to upgrade connection: Forbidden

执行 exec 或 log 子命令：

```sh
kubectl exec -ti $POD_NAME -- nslookup kubernetes
```

详细错误如下：

```
error: unable to upgrade connection: Forbidden (user=kubernetes, verb=create, resource=nodes, subresource=proxy)
```

是因为 `kube-apiserver` 没有操作 `kubelet` 相关资源的权限，请确保 `system:kube-apiserver-to-kubelet` 权限及相关绑定已经存在：

```sh
# kubectl get clusterrole system:kube-apiserver-to-kubelet
NAME                               AGE
system:kube-apiserver-to-kubelet   6m3s
# kubectl get clusterrolebinding system:kube-apiserver
NAME                    AGE
system:kube-apiserver   4m50s
```

**提示** 本处出现这样的错误，原因通常是重置集群数据后，忘记 [配置 RBAC for Kubelet Authorization](/kfs/v1.15/install-master/#rbac-for-kubelet-authorization)
