# 部署 K8S

如果需要修改证书有效期，修改 `scripts/pki_templates/ca-config.json` 如下 ：

```json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
```

初始化：

```bash
# 复制 setting 文件到自己的目录，并修改配置
vi setting
source setting
# 回到本目录(kfs/lab/deploy)
# 初始化安装目录
./scripts/init_k8s_deploy.sh <集群名称>
# 初始化 PKI
./scripts/init_pki.sh
# 创建 config
./scripts/init_config.sh
```

创建各个 node 证书示例：

```
NODE_NAME=node-1 NODE_IP=192.168.122.21 ./scripts/create_node_certs.sh
NODE_NAME=node-2 NODE_IP=192.168.122.22 ./scripts/create_node_certs.sh
NODE_NAME=node-3 NODE_IP=192.168.122.23 ./scripts/create_node_certs.sh
```

下载依赖的软件包

```
./scripts/get_pkgs.sh
```

## 部署 K8S

进入 ansible 目录

```
cd $KFS_HOME/kfslab/ansible
```

修改相关配置。

可以把 `$KFS_HOME/kfslab` 同步到 node-1 (k8s master 角色)服务器，再执行 `ansible-playbook`

## 测试

### etcd

```bash
ETCDCTL_API=3 etcdctl member list \
   --endpoints=https://127.0.0.1:2379 \
   --cacert=/etc/etcd/ca.pem \
   --cert=/etc/etcd/kubernetes.pem \
   --key=/etc/etcd/kubernetes-key.pem
```

### k8s

```bash
# systemd 服务状态
systemctl status kube-apiserver kube-controller-manager kube-scheduler
# 查看实时日志
journalctl -u kube-apiserver -f
journalctl -u kube-controller-manager -f
journalctl -u kube-scheduler -f
```

```bash
kubectl get componentstatuses
kubectl get all --all-namespaces
```

## FAQ

### 如果使用 docker 作为容器运行时后端

```shell
iptables -P FORWARD ACCEPT
```

Kubernetes v1.20 开始移除 docker 作为容器运行时后端，建议使用 containerd 。
