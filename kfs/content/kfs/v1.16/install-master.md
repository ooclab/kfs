---
title: "搭建 K8S Master"
weight: 70
pre: "<b>7. </b>"
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["v1.15", "Kubernetes", "拓扑图"]
---

## 准备

同步 **mbp** 的 `$KFS_HOME` 目录到 master-1 节点的 `/kfslab` 目录：

```sh
rsync -avz --progress --delete --filter='- v1.*' $KFS_HOME/ master-1:/kfslab/
```

以后只要 **mbp** 的 `$KFS_HOME` 目录有更新，就执行同步操作。

登录 master-1 虚拟机：

```sh
ssh -v master-1
```

检查 `/kfslab` 目录是否正确（也可以使用 rsync 同步）：

```
# ls /kfslab/
config  install  setting
```

设置 `K8S_MASTER_ROOT` 环境变量和创建目录：

```sh
export K8S_MASTER_ROOT="/root/lab"
mkdir -pv $K8S_MASTER_ROOT
```

设置基本环境变量：

```sh
unalias cp
cd $K8S_MASTER_ROOT

cat > master-setting <<EOF
KFS_HOME=/kfslab
KFS_CONFIG="\${KFS_HOME}/config"
KFS_INSTALL="\${KFS_HOME}/install"
K8S_MASTER_ROOT="/root/lab"
POD_CIDR="172.16.0.0/16"
INTERNAL_IP="192.168.0.188"
EOF

source master-setting
```

**注意** 每一次中断部署，再次返回，请先是环境变量生效：

```sh
export K8S_MASTER_ROOT="/root/lab"
cd $K8S_MASTER_ROOT
source master-setting
```


## Master 部署

### etcd

准备目录：

```sh
# 确保目录存在
mkdir -pv /etc/etcd
# 拷贝证书
cd $KFS_CONFIG
cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd
# 拷贝二进制程序
cd $KFS_INSTALL/master/bin/
cp etcd etcdctl /usr/local/bin/
```

```sh
# 查看 INTERNAL_IP
echo $INTERNAL_IP
ETCD_NAME=$(hostname -s)

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master-1=https://${INTERNAL_IP}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

启动服务
```sh
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

测试 etcd 服务是否 OK
```sh
ETCDCTL_API=3 etcdctl member list \
   --endpoints=https://127.0.0.1:2379 \
   --cacert=/etc/etcd/ca.pem \
   --cert=/etc/etcd/kubernetes.pem \
   --key=/etc/etcd/kubernetes-key.pem
```

### kubernetes master components

本部分我们启动 kubernetes master 相关组件。

准备：

```sh
# 复制 kubernetes master 需要的程序
cd $KFS_INSTALL/master/bin/
cp kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
# 复制 kubernetes master 需要的配置文件
mkdir -pv /etc/kubernetes/
cd $KFS_CONFIG
cp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem encryption-config.yaml /etc/kubernetes/
cp kube-controller-manager.kubeconfig /etc/kubernetes/
cp kube-scheduler.kubeconfig /etc/kubernetes/
```

#### kube-apiserver

注意：

1. 最新版本开始，需要通过 `--service-cluster-ip-range` 指定 service IP 地址域。

创建 `/etc/systemd/system/kube-apiserver.service` :

```sh
# 查看 INTERNAL_IP
echo $INTERNAL_IP
ETCD_SERVERS="https://${INTERNAL_IP}:2379"

cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=1 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/etc/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/etc/kubernetes/ca.pem \\
  --etcd-certfile=/etc/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/etc/kubernetes/kubernetes-key.pem \\
  --etcd-servers=${ETCD_SERVERS} \\
  --event-ttl=1h \\
  --experimental-encryption-provider-config=/etc/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/etc/kubernetes/ca.pem \\
  --kubelet-client-certificate=/etc/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/etc/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/etc/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/etc/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/etc/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

#### kube-controller-manager

创建 `/etc/systemd/system/kube-controller-manager.service` :

```sh
# 查看 POD_CIDR
echo $POD_CIDR

cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=${POD_CIDR} \\
  --allocate-node-cidrs \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/etc/kubernetes/ca.pem \\
  --cluster-signing-key-file=/etc/kubernetes/ca-key.pem \\
  --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/etc/kubernetes/ca.pem \\
  --service-account-private-key-file=/etc/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

#### kube-schedular

创建 `kube-scheduler.yaml` :

```sh
mkdir -p /etc/kubernetes/config/

cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/etc/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

创建 `kube-scheduler.service`

```sh
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

#### Start Kubernetes Master Components

启动 Kubernetes Master 组件：

```sh
systemctl daemon-reload
systemctl enable kube-apiserver kube-controller-manager kube-scheduler
systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

查看状态有多种方法：

```sh
# systemd 服务状态
systemctl status kube-apiserver kube-controller-manager kube-scheduler
# 查看实时日志
journalctl -u kube-apiserver -f
journalctl -u kube-controller-manager -f
journalctl -u kube-scheduler -f
```

查看集群：

```
# kubectl get componentstatuses
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true"}

# kubectl get all --all-namespaces


NAMESPACE   NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
default     service/kubernetes   ClusterIP   10.32.0.1    <none>        443/TCP   22m
```

部署 nginx 以支持默认 80 端口的 `/healthz`

```sh
yum install -y nginx

cat > /etc/nginx/conf.d/kubernetes.default.svc.cluster.local.conf <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /etc/kubernetes/ca.pem;
  }
}
EOF

systemctl start nginx
```

测试 `http://127.0.0.1/healthz` 服务是否正确：

```
[root@k8s-master-1 lab]# curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz
HTTP/1.1 200 OK
Server: nginx/1.12.2
Date: Thu, 16 May 2019 01:24:04 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 2
Connection: keep-alive
X-Content-Type-Options: nosniff

ok
```

## 测试

### 内部访问集群

测试内部访问集群，我们在 **k8s-master-1** 执行测试操作：

准备：

```sh
cd $KFS_CONFIG
cp admin.kubeconfig $K8S_MASTER_ROOT
cd $K8S_MASTER_ROOT
```

### 查看 Kubernetes 集群组件状态

```
[root@master-1 lab]# kubectl get componentstatuses --kubeconfig admin.kubeconfig
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true"}
```

### 外部访问集群

测试外部访问集群，我们在 **ooclab** , **mbp** 等任何能访问 k8s-master-1 的机器上执行测试操作。

测试 healthz ：

```
$ curl -H "Host: kubernetes.default.svc.cluster.local" -i http://192.168.1.61/healthz
HTTP/1.1 200 OK
Server: nginx/1.12.2
Date: Thu, 16 May 2019 01:23:42 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 2
Connection: keep-alive
X-Content-Type-Options: nosniff

ok
```

#### 查看集群组件

设置 kubectl 默认配置文件路径：

```sh
export KUBECONFIG="${KFS_CONFIG}/admin-public.kubeconfig"
```

查看集群组件状态：

```
$ kubectl get componentstatuses
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true"}
```

#### 访问 kube-apiserver 接口

在外部测试（需要 `ca.pem` 和 `k8s-master-1` 的 IP）：

```sh
KFS_K8S_PUBLIC_ADDRESS="192.168.1.61"
curl --cacert ca.pem "https://${KFS_K8S_PUBLIC_ADDRESS}:6443/version"
```

返回结果示例：

```json
{
  "major": "1",
  "minor": "15+",
  "gitVersion": "v1.15.0-alpha.3",
  "gitCommit": "95eb3a67020f6eabef08c3e9caf348149f469798",
  "gitTreeState": "clean",
  "buildDate": "2019-05-07T18:09:03Z",
  "goVersion": "go1.12.4",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

## 其他配置

### RBAC for Kubelet Authorization

`kube-apiserver` 访问 `kubelet` 需要配置 RBAC 权限。

进入 `k8s-master-1` 服务器，
创建一个名为 `system:kube-apiserver-to-kubelet` 的 ClusterRole

```sh
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```

`kube-apiserver` 通过 `--kubelet-client-certificate` 选项指定的证书，作为 `kubernetes` 用户访问 `kubelet` ，绑定上面创建的 `system:kube-apiserver-to-kubelet` ClusterRole 到 `kubernetes` 用户:

```sh
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

## FAQ

### you should increase server_names_hash_bucket_size

k8s-master-1 上部署 nginx 时，启动出现下面错误（可以用 `/usr/sbin/nginx -t` 检查）：

```
nginx: [emerg] could not build server_names_hash, you should increase server_names_hash_bucket_size: 32
nginx: configuration file /etc/nginx/nginx.conf test failed
```

需要手动在 `/etc/nginx/nginx.conf` 配置文件增加下面配置：

```
server_names_hash_bucket_size  64;
```
