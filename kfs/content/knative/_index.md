---
title: "Knative"
weight: 11
date: 2019-05-16T15:00:00+08:00
draft: false
tags: ["kubernetes", "knative"]
---


- [https://knative.dev](https://knative.dev)


## 安装

参考 [Performing a Custom Knative Installation](https://knative.dev/docs/install/knative-custom-install/)

```sh
kubectl delete svc knative-ingressgateway -n istio-system
kubectl delete deploy knative-ingressgateway -n istio-system
kubectl delete statefulset/controller-manager -n knative-sources
```

```sh
kubectl apply --selector knative.dev/crd-install=true \
 --filename https://github.com/knative/eventing/releases/download/v0.6.0/release.yaml
```

```sh
kubectl apply \
 --filename https://github.com/knative/eventing/releases/download/v0.6.0/release.yaml
```
