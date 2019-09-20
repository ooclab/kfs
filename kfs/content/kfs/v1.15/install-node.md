---
title: "搭建 K8S Node"
weight: 80
pre: "<b>8. </b>"
date: 2019-05-16T09:30:00+08:00
draft: false
tags: ["v1.15", "Kubernetes", "拓扑图"]
---


## 准备

同步 **ooclab** 的 `$KFS_HOME` 目录到 k8s-node-1 , k8s-node-2 节点的 `/kfslab` 目录：

```sh
rsync -avz --progress --delete --filter='- v1.15*' $KFS_HOME/ k8s-node-1:/kfslab/
rsync -avz --progress --delete --filter='- v1.15*' $KFS_HOME/ k8s-node-2:/kfslab/
```

以后只要 **ooclab** 的 `$KFS_HOME` 目录有更新，就执行同步操作。

### 网络

Kubernetes 通常使用一个扁平的网络空间（所有 pod 之间网络互动，无论在不在同一个节点），最简单的是 flannel 。

如果您想要深入理解网络配置，请参考 [Flannel From Scratch](/kfs/v1.14.1/flannel-from-scratch/) 提前在所有节点手动部署好 flannel 。
只需要 kubernetes 集群的 etcd 服务搭建好了之后，就可以部署各个节点的 flanneld 服务。

本版本我们使用 kubernetes 部署 flanneld 。

## Node 部署

**说明**

1. 本章流程如无特殊说明，需要在 `k8s-node-1` , `k8s-node-2` `k8s-master-1` 上都进行。
2. 下面示例中，遇到特定主机名等信息，以 `k8s-node-1` 为例。请修改为正在部署节点的具体信息。

### 设置环境变量

设置 `K8S_NODE_ROOT` 环境变量和创建目录：

```sh
export K8S_NODE_ROOT="/root/lab"
mkdir -pv $K8S_NODE_ROOT
```

设置基本环境变量：

```sh
unalias cp
cd $K8S_NODE_ROOT

cat > node-setting <<EOF
KFS_HOME=/kfslab
KFS_CONFIG="\${KFS_HOME}/config"
KFS_INSTALL="\${KFS_HOME}/install"
K8S_NODE_ROOT="/root/lab"
POD_CIDR="172.16.0.0/16"
EOF

source node-setting
```

**注意** 每一次中断部署，再次返回，请先是环境变量生效：

```sh
export K8S_NODE_ROOT="/root/lab"
cd $K8S_NODE_ROOT
source node-setting
```

### 系统准备

创建目录：

```sh
mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin
```

**注意**

- `/etc/cni/net.d` 和 `/opt/cni/bin` 默认命名是这样，不要和已有环境混淆，也不要随便修改命名，除非您非常清楚为什么这样做。

复制二进制程序：

```sh
cd $KFS_INSTALL/node/bin
cp runc kube-proxy kubelet /usr/local/bin/
cd $KFS_INSTALL/node
tar -xvf crictl-v1.15.0-linux-amd64.tar.gz -C /usr/local/bin/
tar -xvf cni-plugins-linux-amd64-v0.8.1.tgz -C /opt/cni/bin/
mkdir -pv /tmp/containerd-1.2.7.linux-amd64
tar -xvf containerd-1.2.7.linux-amd64.tar.gz -C /tmp/containerd-1.2.7.linux-amd64
cp /tmp/containerd-1.2.7.linux-amd64/bin/* /usr/local/bin/
```

### containerd

创建 loopback 配置：

```sh
cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF
```

```sh
mkdir -p /etc/containerd/

cat << EOF | sudo tee /etc/containerd/config.toml
subreaper = true
oom_score = -999

[debug]
        level = "debug"

[metrics]
        address = "127.0.0.1:1338"

[plugins.linux]
        runtime = "runc"
        shim_debug = true

[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
    [plugins.cri.containerd.untrusted_workload_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
    [plugins.cri.containerd.gvisor]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"

[plugins.cri]
  # sandbox_image is the image used by sandbox container.
  sandbox_image = "ibmcom/pause:3.1"

[plugins.cri.registry.mirrors]
  [plugins.cri.registry.mirrors."docker.io"]
    endpoint = ["https://registry.docker-cn.com", "https://dockerhub.azk8s.cn"]
  [plugins.cri.registry.mirrors."quay.io"]
    endpoint = ["https://quay.azk8s.cn"]
  [plugins.cri.registry.mirrors."gcr.io"]
    endpoint = ["http://gcr.azk8s.cn/google_containers/"]

EOF
```

**说明**

1. containerd 详细的配置参考 [https://github.com/containerd/cri/blob/master/docs/config.md](https://github.com/containerd/cri/blob/master/docs/config.md)
2. 默认的 `k8s.gcr.io/pause:3.1` 资源在国内无法访问。国内网络需要配置 `sandbox_image` 为一个可以访问的路径；必须在这里配置，在 `kubelet` 使用 `--pod-infra-container-image` 配置无效。
3. 可以使用 `containerd config default` 查看默认的配置（可以基于此修改）
4. 暂时没有使用 `/usr/local/bin/runsc` 运行安全容器，可以先配置。
5. 国内增加 3 个默认的镜像配置

创建 `containerd.service` :

```sh
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

### kubelet

设置环境变量：

```sh
export NODE_NAME="node-1"
```

**注意** 在不同节点上请替换为对应的 HOSTNAME ，本处以 `node-1` 为例。

```sh
mkdir -p /etc/kubelet /etc/kubernetes/
cd $KFS_CONFIG
cp ${NODE_NAME}-key.pem ${NODE_NAME}.pem /etc/kubelet/
cp kubelet-${NODE_NAME}.kubeconfig /etc/kubelet/kubeconfig
cp ca.pem /etc/kubernetes/
```

创建 `kubelet-config.yaml`:

```sh
# 查看 POD_CIDR
echo $POD_CIDR

cat <<EOF | sudo tee /etc/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/etc/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/etc/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/etc/kubelet/${NODE_NAME}.pem"
tlsPrivateKeyFile: "/etc/kubelet/${NODE_NAME}-key.pem"
EOF
```

**注意**

1. `resolvConf` 在使用 `systemd-resolved` 的系统中需要避免 CoreDNS 的循环解析。 在 Ubuntu 下是 `/run/systemd/resolve/resolv.conf` 。本实验是 centos/7 , 暂时使用 `/etc/resolv.conf`
2. 如果是 `k8s-master-1` 节点启动 kubelet ，我们可以使用 `--hostname-override=node-0` 指定一个自定义的主机名 `node-0` 。需要设置节点的 `node-role.kubernetes.io/master` 标签：

```sh
kubectl patch node 节点名 -p '{"spec":{"taints":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master"}]}}'
```

如果后端是 containerd , 创建 `kubelet.service` 配置如下：

```sh
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/etc/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/etc/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

如果后端是 docker , 创建 `kubelet.service` 配置如下：

```sh
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/etc/kubelet/kubelet-config.yaml \\
  --pod-infra-container-image=ibmcom/pause:3.1 \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/etc/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

**说明** :

1. 可以使用 `--register-with-taints` 定义 taints (comma separated <key>=<value>:<effect>)

### kube-proxy

```sh
mkdir -p /etc/kube-proxy
cd $KFS_CONFIG
cp kube-proxy.kubeconfig /etc/kube-proxy/kubeconfig
```

创建 `kube-proxy-config.yaml`:

```sh
cat <<EOF | sudo tee /etc/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/etc/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF
```

创建 `kube-proxy.service`:
```sh
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/etc/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### 启动 node 服务

```sh
systemctl daemon-reload
systemctl enable containerd kubelet kube-proxy
systemctl start containerd kubelet kube-proxy
```

## 测试

查看集群，是否能否发现新加入的节点：

```sh
$ kubectl get nodes -o wide
NAME         STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION               CONTAINER-RUNTIME
k8s-node-1   Ready    <none>   11m   v1.14.1   10.0.2.15     <none>        CentOS Linux 7 (Core)   3.10.0-957.12.1.el7.x86_64   containerd://1.2.6
k8s-node-2   Ready    <none>   6s    v1.14.1   10.0.2.15     <none>        CentOS Linux 7 (Core)   3.10.0-957.12.1.el7.x86_64   containerd://1.2.6
```


## FAQ

### cni config load failed: no network config found in /etc/cni/net.d

```
May 16 02:43:04 node-1 containerd[3962]: time="2019-05-16T02:43:04.734681739Z" level=error msg="Failed to load cni configuration" error="cni config load failed: no network config found in /etc/cni/net.d: cni plugin not initialized: failed to load cni config"
```

检查 `/etc/cni/net.d/` 目录下是否有配置文件。
