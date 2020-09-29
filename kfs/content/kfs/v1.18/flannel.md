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

**重要！！！**
请修改 kube-flannel.yml 里的 Network 配置为 POD_CIDR 的值。如果这里配置错误，pod 里无法 ping 通公网，即便 pod 的 IP 在本地网络都是可以相互 ping 通。原因是 kubernetes 会在 iptables 里为 flannel 添加该网段规则。

```text
# iptables-save | grep 172.16.0.0
-A FORWARD -s 172.16.0.0/16 -j ACCEPT
-A FORWARD -d 172.16.0.0/16 -j ACCEPT
-A POSTROUTING -s 172.16.0.0/16 -d 172.16.0.0/16 -j RETURN
-A POSTROUTING -s 172.16.0.0/16 ! -d 224.0.0.0/4 -j MASQUERADE
-A POSTROUTING ! -s 172.16.0.0/16 -d 172.16.1.0/24 -j RETURN
-A POSTROUTING ! -s 172.16.0.0/16 -d 172.16.0.0/16 -j MASQUERADE
```

注意： CentOS 8 里查看不到上面信息，如果 ping 不同 flannel 网络里的 ip 。方法有：

- 方案一：在各个节点执行 `iptables -P FORWARD ACCEPT` 
- 方案二：禁止 firewalld , 使用 ipvs 作为 kube-proxy mode
- 方案三：将 iptables 里的 INPUT 和 FORWARD 最后的 reject 删除，示例如下：

```
# iptables-save | grep -i reject
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
# iptables-save > t
# vi t # 删除两条 --reject-with icmp-host-prohibited 行
# iptables-restore < t
```

`kube-flannel.yml` 配置部分如下：

```yaml
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "172.16.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
```

查看部署结果：

```
$ kubectl get all --all-namespaces -o wide
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE   IP              NODE       NOMINATED NODE   READINESS GATES
kube-system   pod/kube-flannel-ds-amd64-b9j8p   1/1     Running   0          62s   192.168.0.188   master-1   <none>           <none>
kube-system   pod/kube-flannel-ds-amd64-k46zf   1/1     Running   0          62s   192.168.0.189   node-1     <none>           <none>


NAMESPACE   NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE   SELECTOR
default     service/kubernetes   ClusterIP   10.32.0.1    <none>        443/TCP   28m   <none>

NAMESPACE     NAME                                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE   CONTAINERS     IMAGES                                   SELECTOR
kube-system   daemonset.apps/kube-flannel-ds-amd64     2         2         2       2            2           <none>          63s   kube-flannel   quay.io/coreos/flannel:v0.11.0-amd64     app=flannel
kube-system   daemonset.apps/kube-flannel-ds-arm       0         0         0       0            0           <none>          62s   kube-flannel   quay.io/coreos/flannel:v0.11.0-arm       app=flannel
kube-system   daemonset.apps/kube-flannel-ds-arm64     0         0         0       0            0           <none>          63s   kube-flannel   quay.io/coreos/flannel:v0.11.0-arm64     app=flannel
kube-system   daemonset.apps/kube-flannel-ds-ppc64le   0         0         0       0            0           <none>          62s   kube-flannel   quay.io/coreos/flannel:v0.11.0-ppc64le   app=flannel
kube-system   daemonset.apps/kube-flannel-ds-s390x     0         0         0       0            0           <none>          62s   kube-flannel   quay.io/coreos/flannel:v0.11.0-s390x     app=flannel
```

**说明**

1. 如果使用 `vagrant` 实验环境，需要在 `flanneld` 启动时使用 `--iface=eth1` 指定端口。编辑 `kube-flannel.yml` 配置文件。

## FAQ

### 在 Pod 里不能 ping 通外部 IP

如果各个地方看起来都正常，比如 pod 的 ip 在各个节点都能 ping 通。但是 Pod 里，不能 ping 外面 ip 。**请检查 flannel 的网络配置** ，比如是否和 `POD_CIDR` 一致 。

```json
{
  "Network": "172.16.0.0/16",
  "Backend": {
    "Type": "vxlan"
  }
}
```

参考

- [Kubernetes pod can't reach external ip address](https://stackoverflow.com/questions/55877256/kubernetes-pod-cant-reach-external-ip-address/56014342#56014342)
