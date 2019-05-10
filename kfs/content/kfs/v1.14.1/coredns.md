---
title: "CoreDNS"
weight: 90
pre: "<b>9. </b>"
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["v1.14.1", "kfs", "dns", "coredns"]
---

[CoreDNS](https://coredns.io/) 可以提供基于域名的服务访问。从 [Kubernetes 1.13](https://kubernetes.io/blog/2018/12/03/kubernetes-1-13-release-announcement/) 开始，**CoreDNS** 作为默认的 DNS（之前是 **kube-dns** ）。

- [https://github.com/coredns/coredns](https://github.com/coredns/coredns)

**提示** ：在 **mbp** 执行操作

## 部署 CoreDNS

进入 `kubernetes/cluster/addons/dns/coredns` 目录：

```sh
cd $KFS_HOME/v1.14.1/kubernetes/cluster/addons/dns/coredns
```


创建 `coredns.yaml`

```sh
export DNS_SERVER_IP="10.32.0.10"
export DNS_DOMAIN="cluster.local"
sed \
  -e 's/__PILLAR__DNS__SERVER__/'$DNS_SERVER_IP'/g' \
  -e 's/__PILLAR__DNS__DOMAIN__/'$DNS_DOMAIN'/g' \
  -e 's/k8s.gcr.io/coredns/g' \
  coredns.yaml.base > coredns.yaml
```

应用 `coredns.yaml` :
```sh
kubectl apply -f coredns.yaml
```

查看 kubernetes 信息：

```
$ kubectl get all --all-namespaces -o wide
NAMESPACE     NAME                          READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
kube-system   pod/coredns-8854569d4-csrzr   1/1     Running   0          33s   172.16.55.3   k8s-node-1   <none>           <none>

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE   SELECTOR
default       service/kubernetes   ClusterIP   10.32.0.1    <none>        443/TCP                  10h   <none>
kube-system   service/kube-dns     ClusterIP   10.32.0.10   <none>        53/UDP,53/TCP,9153/TCP   33s   k8s-app=kube-dns

NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                  SELECTOR
kube-system   deployment.apps/coredns   1/1     1            1           33s   coredns      coredns/coredns:1.3.1   k8s-app=kube-dns

NAMESPACE     NAME                                DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                  SELECTOR
kube-system   replicaset.apps/coredns-8854569d4   1         1         1       33s   coredns      coredns/coredns:1.3.1   k8s-app=kube-dns,pod-template-hash=8854569d4
```

## 测试 DNS 服务是否 OK

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
