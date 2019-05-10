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

```
brew install kubernetes-helm
```

## 初始化

初始化并部署 Tiller

```
helm init --service-account tiller --history-max 200 --tiller-image=omio/gcr.io.kubernetes-helm.tiller:v2.13.1
```

**注意**

- [Role-based Access Control](https://helm.sh/docs/using_helm/#role-based-access-control)
