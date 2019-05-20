---
title: "使用私有 image 仓库"
date: 2019-05-20T16:20:00+08:00
draft: false
---

使用私有 image 仓库 (比如 harbor)。

## 参考

- [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)

## 步骤

### 方法一：从已有的 docker 密钥创建

#### 1. 登录

```sh
docker login 私有仓库地址
```

#### 2.  创建 secret

取名为 `regcred` ：

```sh
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
    --type=kubernetes.io/dockerconfigjson
```

`config.json` 需要使用全路径，比如我的路径是 `/Users/gwind/.docker/config.json`


### 方法二：命令行直接配置验证方式

```sh
kubectl create secret docker-registry regcred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```

## 测试

查看 `regcred` :

```sh
kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

使用私有 image 创建 Pod 测试：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-reg
spec:
  containers:
  - name: private-reg-container
    image: <your-private-image>
  imagePullSecrets:
  - name: regcred
```

## FAQ

### MacOS 的 `osxkeychain`

`~/.docker/config.json` 示例：

```json
{
        "auths": {
                "https://index.docker.io/v1/": {},
                "hub.ooclab.com": {}
        },
        "HttpHeaders": {
                "User-Agent": "Docker-Client/18.09.1 (darwin)"
        },
        "credsStore": "osxkeychain",
        "stackOrchestrator": "swarm"
}
```

这里的 auth 可以自己构造一个：

```
echo "用户名:密码" | base64
```

创建的 `config.json` 类似这样：

```json
{
  "auths": {
    "你的 Private Registry 地址": {
      "username": "用户名",
      "password": "密码",
      "auth": "上面构造的 auth 值"
    }
  }
}
```
