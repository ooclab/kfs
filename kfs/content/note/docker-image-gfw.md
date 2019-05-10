---
title: "Docker image 在Qiang外怎么办？"
date: 2019-04-29T21:50:00+08:00
draft: false
---


创建 `trans_image.sh` 脚本：

```bash
#! /bin/bash

# https://hub.docker.com
# 第一次运行需要执行 `docker login` 验证帐户

# 将指定的 image 转移到 hub.docker.com 上
# 使用 omio 组织名称

# https://hub.docker.com/u/omio/dashboard/
ORG=omio

# gcr.io/google_containers/pause-amd64:3.0 -> $ORG/gcr.io.google_containers.pause-amd64:3.0
function trans() {
    ORIG_NAME=$1
    NEW_NAME=`echo ${ORIG_NAME} | sed 's@/@.@g'`

    docker pull $ORIG_NAME
    docker tag $ORIG_NAME $ORG/$NEW_NAME
    docker push $ORG/$NEW_NAME
}

for var in "$@"
do
    echo "==> $var"
    trans $var
done
```

比如将 `k8s.gcr.io/pause:3.1` 转换为 `omio/k8s.gcr.io.pause:3.1` ，执行：

```sh
bash trans_image.sh k8s.gcr.io/pause:3.1
```

参考：
- [Docker image 在Qiang外怎么办？](https://plus.ooclab.com/note/article/1386)
