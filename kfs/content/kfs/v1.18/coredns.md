---
title: "CoreDNS"
weight: 92
pre: "<b>9.2 </b>"
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["kfs", "dns", "coredns", "addons"]
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
NAMESPACE     NAME                          READY   STATUS    RESTARTS   AGE     IP              NODE       NOMINATED NODE   READINESS GATES
kube-system   coredns-fdb5f4b49-hk8d8       1/1     Running   0          14s     172.16.1.2      node-1     <none>           <none>
kube-system   kube-flannel-ds-amd64-b9j8p   1/1     Running   0          2m31s   192.168.0.188   master-1   <none>           <none>
kube-system   kube-flannel-ds-amd64-k46zf   1/1     Running   0          2m31s   192.168.0.189   node-1     <none>           <none>
```

**重要** 我们看到 coredns 分配到了IP。现在请在各个节点执行 `ping 172.16.0.2` 的测试，如果不能 ping ，请检查防火墙配置。


## 测试 DNS 服务是否 OK

**重要** 请务必完成下面测试，确认 DNS 服务已经OK。否则 K8S 集群基本不可用！！

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
192.168.0.188 master-1
192.168.0.189 node-1
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

**提示** 本处出现这样的错误，原因通常是重置集群数据后，忘记 [配置 RBAC for Kubelet Authorization](/kfs/v1.16/install-master/#rbac-for-kubelet-authorization)

### HINFO: read udp 53: i/o timeout

错误日志如下：

```
.:53
[INFO] plugin/reload: Running configuration MD5 = a13c7690ba4c30d1686f80686d2d9de8
CoreDNS-1.6.5
linux/amd64, go1.13.4, c2fd1b2
[ERROR] plugin/errors: 2 4485263620504323756.6831942502343133694. HINFO: read udp 172.16.39.2:56535->192.168.1.1:53: i/o timeout
[ERROR] plugin/errors: 2 4485263620504323756.6831942502343133694. HINFO: read udp 172.16.39.2:58847->192.168.1.1:53: i/o timeout
[ERROR] plugin/errors: 2 4485263620504323756.6831942502343133694. HINFO: read udp 172.16.39.2:60050->192.168.1.1:53: i/o timeout
[ERROR] plugin/errors: 2 4485263620504323756.6831942502343133694. HINFO: read udp 172.16.39.2:60533->192.168.1.1:53: i/o timeout
[ERROR] plugin/errors: 2 4485263620504323756.6831942502343133694. HINFO: read udp 172.16.39.2:36231->192.168.1.1:53: i/o timeout
```

修改 `Corefile` 配置示例：

```yaml
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        prometheus :9153
        forward . 8.8.8.8
        cache 30
        loop
        reload
        loadbalance
    }
```

使用 `8.8.8.8` （任何可靠的外部 DNS Server）代替 `/etc/resolv.conf`

分析：

> 实验环境是 ovs + kvm 的虚拟机。网络路由大致为 pod -> calico / flannel -> ipvs / iptables -> ovs -> 192.168.31.1 (小米路由) -> 192.168.1.1 (联通盒子) -> 公网测试。测试 `forward . 192.168.31.1` 和 `forward . 192.168.1.1` 都不可以。`forward . 8.8.8.8` 可行。

参考：

- [i/o timeout when set upstream](https://github.com/coredns/coredns/issues/2287)
- [Known issues](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/#known-issues)
- [Dns server is null in some pods.](https://github.com/kubernetes/kubernetes/issues/30215)

## CentOS 8 (iptables > 1.8) 环境 kube-proxy 的服务配置规则无效

- 官方文档 [kube-proxy](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/)
- [kube-proxy currently incompatible with `iptables >= 1.8`](https://github.com/kubernetes/kubernetes/issues/71305)

```
$ kubectl exec -it busybox-sleep -- nslookup kubernetes
;; connection timed out; no servers could be reached

command terminated with exit code 1
```

使用 CentOS 8 系统部署 k8s node ，发现集群服务地址无效。

当前测试的解决方案：

1. 切换 ipvs 作为 kube-proxy 后端
2. 在各节点执行 `iptables -F -t nat`

**注意** ：我的测试中，手动删除 `iptables -t nat -D KUBE-SERVICES 1` 这些规则即可，对比发现，仅下面一条规则：

```
-A KUBE-SERVICES -m comment --comment "Kubernetes service cluster ip + port for masquerade purpose" -m set --match-set KUBE-CLUSTER-IP src,dst -j KUBE-MARK-MASQ
```

不过很快 kube-proxy 进程会自动补全该规则。

最后，在 kube-proxy 配置 `/etc/kube-proxy/kube-proxy-config.yaml` 添加 `clusterCIDR` 。

```yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/etc/kube-proxy/kubeconfig"
mode: "ipvs"
clusterCIDR: "10.32.0.0/16"
```

```
--cluster-cidr string
The CIDR range of pods in the cluster. When configured, traffic sent to a Service cluster IP from outside this range will be masqueraded and traffic sent from pods to an external LoadBalancer IP will be directed to the respective cluster IP instead
```

查看 iptables ，发现上面的规则排除了 `10.32.0.0/16` 。已经可以成功执行 `nslookup kubernetes.default.svc.cluster.local 10.32.0.10` 。

```
-A KUBE-SERVICES ! -s 10.32.0.0/16 -m comment --comment "Kubernetes service cluster ip + port for masquerade purpose" -m set --match-set KUBE-CLUSTER-IP dst,dst -j KUBE-MARK-MASQ
```

**说明** `clusterCIDR` 的值应该与进群中 Pod 的 CIDR 相同，上面设置为 `10.32.0.0/16` 与集群的 Cluster Service CIDR 相同是错误的。我们的配置中，正确的设置应该是 `172.16.0.0/16`

### 继续测试

目前（环境为 CentOS 8 x86_64 + K8S 1.18.0 + Flannel）测试结果，无论 `clusterCIDR` 配置与否，值如何选择。无法做到在所有节点(host)和Pod里同时访问 10.32.0.1 和 10.32.0.10 服务。即下面访问之一会失败：

```
curl -k https://10.32.0.1
# 和
nslookup kubernetes.default.svc.cluster.local 10.32.0.10
```

将 flannel 换成 calico (https://docs.projectcalico.org/getting-started/kubernetes/quickstart) ，该问题解决。

```
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## IPVS

切换 ipvs 的一个方便的地方是，在各个节点都可以 ping 通 Service 的 IP 。如：

```
ping 10.32.0.10
```
