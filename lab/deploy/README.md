# 部署 K8S

```bash
# 修改配置
vi setting
# 初始化安装目录
./scripts/init_k8s_deploy.sh <集群名称>
# 初始化 PKI
./scripts/init_pki.sh
# 创建 config
./scripts/init_config.sh
```

创建各个 node 证书示例：

```
NODE_NAME=master-1 NODE_IP=192.168.31.10 ./scripts/create_node_certs.sh
NODE_NAME=node-1 NODE_IP=192.168.31.11 ./scripts/create_node_certs.sh
NODE_NAME=node-2 NODE_IP=192.168.31.12 ./scripts/create_node_certs.sh
```

下载依赖的软件包

```
./scripts/get_pkgs.sh
```

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
