---
title: "Helm"
weight: 15
date: 2019-05-03T16:00:00+08:00
draft: false
tags: ["kubernetes", "helm"]
---

The package manager for Kubernetes

- [https://helm.sh/](https://helm.sh/)


## 安装

```sh
brew install kubernetes-helm
```

## 初始化

初始化并部署 Tiller

```sh
helm init --service-account tiller \
  --history-max 200 --tiller-image=omio/gcr.io.kubernetes-helm.tiller:v2.13.1 \
  --stable-repo-url=http://mirror.azure.cn/kubernetes/charts/
```

## 资源

### Mirror

微软提供了helm 仓库的镜像，国内请使用这个：

- stable: http://mirror.azure.cn/kubernetes/charts/
- incubator:	http://mirror.azure.cn/kubernetes/charts-incubator/

**注意**

- [Role-based Access Control](https://helm.sh/docs/using_helm/#role-based-access-control)
