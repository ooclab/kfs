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

配置 `tiller-rbac-config.yaml` ：

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

应用：

```sh
kubectl apply -f tiller-rbac-config.yaml
```

初始化并部署 Tiller

```sh
helm init --service-account tiller \
  --history-max 200 --tiller-image=omio/gcr.io.kubernetes-helm.tiller:v2.13.1 \
  --stable-repo-url=http://mirror.azure.cn/kubernetes/charts/
```

等待片刻，检查 tiller 是否部署完成：

```
$ helm version
Client: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
```


## FAQ

### could not find tiller

如果出现该错误，可能是初始化出错。

## 资源

### Mirror

微软提供了helm 仓库的镜像，国内请使用这个：

- stable: http://mirror.azure.cn/kubernetes/charts/
- incubator:	http://mirror.azure.cn/kubernetes/charts-incubator/

**注意**

- [Role-based Access Control](https://helm.sh/docs/using_helm/#role-based-access-control)
