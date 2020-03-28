#!/bin/bash

## 创建 kubelet certs

# NODE_NAME="master-1"
# NODE_IP="10.10.15.210"

if [ -z "${KFS_CONFIG}" ]; then
  echo "KFS_CONFIG ：请设置 kfs 配置目录"
  exit 0
fi

if [ -z "${KFS_K8S_PUBLIC_ADDRESS}" ]; then
  echo "KFS_K8S_PUBLIC_ADDRESS ：请设置 kube-apiserver 的地址！"
  exit 0
fi

if [ -z "${NODE_NAME}" ]; then
  echo "NODE_NAME ：请设置节点名称！"
  exit 0
fi

if [ -z "${NODE_IP}" ]; then
  echo "NODE_NAME ：请设置节点IP！"
  exit 0
fi

function gen_certs() {
    hostname=$1
    ip=$2
    echo $hostname $ip

    cat > ${hostname}-csr.json <<EOF
    {
      "CN": "system:node:${hostname}",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "L": "BeiJing",
          "O": "system:nodes",
          "OU": "Kubernetes From Scratch",
          "ST": "BeiJing"
        }
      ]
    }
EOF

    cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -hostname=${hostname},${ip} \
      -profile=kubernetes \
      ${hostname}-csr.json | cfssljson -bare ${hostname}
}

function gen_kubeconfig() {
    instance=$1

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
}

pushd $KFS_CONFIG
gen_certs $NODE_NAME $NODE_IP
gen_kubeconfig $NODE_NAME $NODE_IP
popd
