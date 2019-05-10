---
title: "crictl"
date: 2019-05-02T13:00:00+08:00
draft: false
---


```
crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a
```

配置 `/etc/crictl.yaml` :

```sh
cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: true
EOF
```

现在执行 crictl 命令，无需指定 `--runtime-endpoint`：
```
crictl ps -a
```

## 加载 images

需要使用 containerd 安装安装包中的 `ctr` 命令
```
ctr -n=k8s.io images import /tmp/dashboard.tar
```

## 参考

- [CRICTL User Guide](https://github.com/containerd/cri/blob/master/docs/crictl.md)
