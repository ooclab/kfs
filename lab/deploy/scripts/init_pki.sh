#!/bin/bash

[ -z "${KFS_CONFIG}" ] && echo "KFS_CONFIG ：请设置 kfs 配置目录"
[ -z "$KFS_K8S_PUBLIC_ADDRESS" ] && echo "KFS_K8S_PUBLIC_ADDRESS ：请设置 k8s 内网地址！"
[ -z "$KFS_K8S_EXTERNAL_PUBLIC_ADDRESS" ] && echo "KFS_K8S_EXTERNAL_PUBLIC_ADDRESS ：请设置 k8s 外网地址！"

mkdir -pv ${KFS_CONFIG}
pushd ${KFS_CONFIG}

echo "创建 ca 证书"
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

echo "创建 kubernetes 证书"
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,${KFS_K8S_PUBLIC_ADDRESS},${KFS_K8S_EXTERNAL_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default,kubernetes.default.svc \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

for name in admin kube-controller-manager kube-scheduler kube-proxy service-account; do
  echo "创建 ${name} 证书"
  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    ${name}-csr.json | cfssljson -bare ${name}
done

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)


popd
