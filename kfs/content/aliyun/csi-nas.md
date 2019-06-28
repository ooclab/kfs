---
title: "阿里云 CSI NAS 存储应用"
weight: 101
date: 2019-06-11T07:50:00+08:00
draft: false
tags: ["aliyun", "阿里云", "Kubernetes", "CSI", "存储", "NAS"]
---

创建 NAS

```
mount -t nfs -o vers=3,nolock,proto=tcp,noresvport 1d9434a037-ymk28.cn-beijing.nas.aliyuncs.com:/ /mnt
```

**提示**

1. CentOS 7 需要安装 `yum install nfs-utils rpcbind`
