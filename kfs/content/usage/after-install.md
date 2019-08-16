---
title: "集群部署之后"
weight: 6
date: 2019-05-04T09:00:00+08:00
draft: false
tags: ["Kubernetes", "install"]
---

集群部署之后有一些初始化。

## 配置域名解析

可以配置 host 系统的 `/etc/resolv.conf` 文件，添加：

```text
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.32.0.10
```

CentOS 7 安装 `bind-utils` 包：

```shell
yum install bind-utils
```

使用 `nslookup` 查询 Service 解析，示例：

```shell
# nslookup kubernetes
Server:         10.32.0.10
Address:        10.32.0.10#53

Name:   kubernetes.default.svc.cluster.local
Address: 10.32.0.1
```
