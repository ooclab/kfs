---
title: "配置 kubeconfig"
weight: 60
pre: "<b>6. </b>"
date: 2019-04-28T12:40:00+08:00
draft: false
tags: ["v1.15", "Kubernetes", "kubeconfig"]
---

## 创建配置文件

```sh
cd ${KFS_CONFIG}
# 确保 $KFS_K8S_PUBLIC_ADDRESS 值是正确的
echo $KFS_K8S_PUBLIC_ADDRESS
```

### kubelet

为每个节点的 kubelet 创建独立的配置文件：

```sh
for instance in master-1 node-1; do
  kubectl config set-cluster kfs \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KFS_K8S_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kubelet-${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=kubelet-${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kfs \
    --user=system:node:${instance} \
    --kubeconfig=kubelet-${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=kubelet-${instance}.kubeconfig
done
```

生成 2 个节点的 kubeconfig 配置文件：

```
# ls -al kubelet-*.kubeconfig
-rw-------. 1 root root 6262 May 16 08:04 kubelet-master-1.kubeconfig
-rw-------. 1 root root 6242 May 16 08:04 kubelet-node-1.kubeconfig
```

### kube-proxy

所有节点的 kube-proxy 使用相同的配置文件，创建 `kube-proxy.kubeconfig` :

```sh
kubectl config set-cluster kfs \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KFS_K8S_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kfs \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

### kube-controller-manager

创建 `kube-controller-manager.kubeconfig`

```sh
kubectl config set-cluster kfs \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
    --cluster=kfs \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
```

#### kube-scheduler

创建 `kube-scheduler.kubeconfig` ：

```sh
kubectl config set-cluster kfs \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
    --cluster=kfs \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
```

#### admin

创建 `admin.kubeconfig` ：

```sh
kubectl config set-cluster kfs \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

kubectl config set-context default \
    --cluster=kfs \
    --user=admin \
    --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig
```

#### admin-public

**说明** 创建这个 admin 配置文件，是为了从 **ooclab** , **mbp** 等集群外部机器访问集群。

创建 `admin-public.kubeconfig` ：

```sh
kubectl config set-cluster kfs \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KFS_K8S_EXTERNAL_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=admin-public.kubeconfig

kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin-public.kubeconfig

kubectl config set-context default \
    --cluster=kfs \
    --user=admin \
    --kubeconfig=admin-public.kubeconfig

kubectl config use-context default --kubeconfig=admin-public.kubeconfig
```

## Other

### Data Encryption Config and Key

创建 `encryption-config.yaml` :

```sh
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```
