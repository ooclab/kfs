# Basic Addons

## Flannel

```shell
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# 修改 kube-flannel.yml 中网络为 172.16.0.0/16
kubectl apply -f kube-flannel.yml
```
