---
title: "Istio"
weight: 10
date: 2019-05-03T19:00:00+08:00
draft: false
tags: ["kubernetes", "istio"]
---


- [https://istio.io](https://istio.io)


## 安装

参考 [Customizable Install with Helm](https://istio.io/docs/setup/kubernetes/install/helm

```sh
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.1.4 sh -
```

```sh
cd istio-1.1.4
cp bin/istioctl /usr/local/bin
```

已经初始化并按照 tiller 的步骤：

```sh
kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
# 检查 crds 是否为 53
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
# 部署默认配置
helm install install/kubernetes/helm/istio --name istio --namespace istio-system
```

## 检查

```sh
kubectl get svc -n istio-system
```

```sh
kubectl get pods -n istio-system
```
