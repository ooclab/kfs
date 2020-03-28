# 部署 K8S

```bash
cd scripts
# 修改配置
vi setting
# 执行各个脚本
```

创建各个 node 证书示例：

```
NODE_NAME=master-1 NODE_IP=192.168.31.10 ./create-node-certs.sh
NODE_NAME=node-1 NODE_IP=192.168.31.11 ./create-node-certs.sh
NODE_NAME=node-2 NODE_IP=192.168.31.12 ./create-node-certs.sh
```

下载依赖的软件包

```
./get_pkgs.sh
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
