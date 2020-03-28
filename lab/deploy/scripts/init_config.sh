#!/bin/bash

[ -z "${KFS_CONFIG}" ] && echo "KFS_CONFIG ：请设置 kfs 配置目录"
[ -z "$KFS_K8S_PUBLIC_ADDRESS" ] && echo "KFS_K8S_PUBLIC_ADDRESS ：请设置 k8s 内网地址！"
[ -z "$KFS_K8S_EXTERNAL_PUBLIC_ADDRESS" ] && echo "KFS_K8S_EXTERNAL_PUBLIC_ADDRESS ：请设置 k8s 外网地址！"

mkdir -pv ${KFS_CONFIG}
pushd ${KFS_CONFIG}

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# TODO: 将 pki 和
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


# kube-proxy

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

# kube-controller-manager

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

# kube-scheduler

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

# admin

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

# admin-public

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


popd
