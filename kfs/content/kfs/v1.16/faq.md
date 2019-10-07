---
title: "FAQ"
weight: 999
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["v1.15", "Kubernetes", "FAQ"]
---

## 常见问题

### 如何重置测试环境数据 ？

#### 关闭并删除数据

所有运行 **Master** 角色的节点执行：

```sh
systemctl stop kube-apiserver kube-controller-manager kube-scheduler etcd
rm -rf /var/lib/etcd
```

所有运行 **Node** 角色的节点执行：

```sh
systemctl stop containerd kube-proxy kubelet
/bin/rm /etc/cni/net.d/10-flannel.conflist /run/flannel/subnet.env
```

#### 启动服务

**Master** 服务启动：

```sh
systemctl start etcd
systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

所有 **Node** 节点执行：

```sh
systemctl start containerd kube-proxy kubelet
```

#### 初始化

[配置 RBAC for Kubelet Authorization](/kfs/v1.15/install-master/#rbac-for-kubelet-authorization)

## etcd

### tls: failed to verify client's certificate: x509: certificate has expired or is not yet valid

详细错误如下：

```
embed: rejected connection from "192.168.50.11:37744" (error "tls: failed to verify client's certificate: x509: certificate has expired or is not yet valid", ServerName "")
```

最后发现因为 etcd 服务器的时间错误（由于使用 vagrant 虚拟机测试，暂停实践时，就把 **mbp** 合上盖休眠，因此虚拟机时间出错）。

```sh
# 安装 ntpdate
yum install -y ntpdate
# 同步时间
ntpdate 0.pool.ntp.org
```

重启 etcd 服务，重试即可。

更好的方法是，安装 ntpd 服务：
```sh
yum install -y ntp
systemctl enable ntpd
systemctl start ntpd
```

## cni

### "cnio0" already has an IP address different from

kubelet 日志错误详情如下：

```
failed to set bridge addr: \"cnio0\" already has an IP address different from 172.16.0.1/16"
```

我这里遇到的情况是之前配置了错误了 podCIDR 网段，因此 `cnio0` 网络设备已经创建并配置 OK。所以我需要删除该网络设备：

```sh
ip link del cnio0
```

重启 worker 相关服务即可。

### invalid CIDR address

`kubelet` 和 `containerd` 都看到该错误信息，通常是 `kubelet` 调用 `containerd` ，错误是同一个。
我遇到的情况是 `/etc/cni/net.d/` 下 `subnet` 没有配置（为空）。


## Other

### SchemaError(io.k8s.api.autoscaling.v2beta2.ResourceMetricStatus)

我的实践中，使用了 mac 上 docker 服务启动安装的 kubectl 命令，版本较低，校验 `kubernetes-dashboard.yaml` `v1.10.1` 版本出错，详情如下：

```sh
$ kubectl apply -f kubernetes-dashboard.yaml
error: SchemaError(io.k8s.api.autoscaling.v2beta2.ResourceMetricStatus): invalid object doesn't have additional properties
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.11", GitCommit:"637c7e288581ee40ab4ca210618a89a555b6e7e9", GitTreeState:"clean", BuildDate:"2018-11-26T14:38:32Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.1", GitCommit:"b7394102d6ef778017f2ca4046abbaa23b88c290", GitTreeState:"clean", BuildDate:"2019-04-08T17:02:58Z", GoVersion:"go1.12.1", Compiler:"gc", Platform:"linux/amd64"}
```

使用新版本的 `kubectl` 解决问题。


#### unknown service runtime.v1alpha2.RuntimeService

`kubelet` 启动错误信息：

```
E0427 15:02:19.024109    8909 remote_runtime.go:85] Version from runtime service failed: rpc error: code = Unimplemented desc = unknown service runtime.v1alpha2.RuntimeService
E0427 15:02:19.024261    8909 kuberuntime_manager.go:196] Get runtime version failed: rpc error: code = Unimplemented desc = unknown service runtime.v1alpha2.RuntimeService
F0427 15:02:19.024289    8909 server.go:265] failed to run Kubelet: failed to create kubelet: rpc error: code = Unimplemented desc = unknown service runtime.v1alpha2.RuntimeService
```

原因分析：一开始使用的系统安装的 docker
```sh
containerd --version
containerd github.com/containerd/containerd 1.2.5 bb71b10fd8f58240ca47fbb579b9d1028eea7c84
```

使用最新的 `containerd` 即可。
