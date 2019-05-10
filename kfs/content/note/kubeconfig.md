---
title: "kubeconfig"
date: 2019-05-02T17:30:00+08:00
draft: false
---

## kubeconfig file

如果希望 `kubectl` 默认使用某个配置文件，可以：

### 方法一：可以直接复制一个配置文件到指定位置：
```sh
cp admin.kubeconfig ~/.kube/config
```

### 方法二：设置环境变量
```sh
export KUBECONFIG=/path/to/admin.kubeconfig
```
