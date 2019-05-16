---
title: "Smoke Test"
date: 2019-05-16T15:00:00+08:00
draft: false
tags: ["v1.15", "Kubernetes", "Testing"]
---


## Data Encryption

创建一个加密数据：

```sh
kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"
```

查看 etcd 中的加密数据

```sh
ETCDCTL_API=3 etcdctl get \
  --endpoints=https://192.168.1.61:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C
```

结果如下：
```
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
00000040  3a 76 31 3a 6b 65 79 31  3a 22 bb e9 96 78 5b d5  |:v1:key1:"...x[.|
00000050  81 47 04 2b 94 de 09 dc  de 05 11 b7 fe 36 09 22  |.G.+.........6."|
00000060  66 80 d1 c1 04 6c 81 e3  bc 3a 23 2c 05 db c8 92  |f....l...:#,....|
00000070  6e ff 93 79 2b 10 0e fa  f8 54 58 52 f2 2a 7d d8  |n..y+....TXR.*}.|
00000080  c2 33 44 d3 9a 09 8b 07  d9 bc 2b 9e 95 a7 98 23  |.3D.......+....#|
00000090  0f db 96 f6 31 e9 c1 6c  b2 13 00 b0 1d 5b 31 93  |....1..l.....[1.|
000000a0  df 9c b7 eb 57 92 a0 25  74 45 c1 26 6f 20 43 12  |....W..%tE.&o C.|
000000b0  9a 3e 7e 8d bd 53 de 15  15 97 04 59 16 90 f7 48  |.>~..S.....Y...H|
000000c0  ec 2c 52 75 91 20 9b 13  b0 99 c2 ac fd 0a 29 78  |.,Ru. ........)x|
000000d0  17 88 76 9c ae 23 8c 7b  fe 75 14 7c cd cb de 7e  |..v..#.{.u.|...~|
000000e0  e5 f0 e6 02 23 29 10 81  e0 0a                    |....#)....|
000000ea
```

## Deployments

```sh
# 创建 nginx
kubectl run nginx --image=nginx --generator=run-pod/v1
# 查看 pod
kubectl get pods -l run=nginx
# 或者
kubectl get pods -l run=nginx -o wide
# 或者
kubectl get pod/nginx
# 或者
kubectl get pod/nginx -o wide
# 查看 pod 详情
kubectl describe pod/nginx
```

### 端口转发

在 k8s 集群中任一节点（部署了 flanneld , 有 kubectl , 且 kubectl 可以访问集群），
测试 nginx 可访问性：

```
# kubectl get pod/nginx -o wide
NAME    READY   STATUS    RESTARTS   AGE     IP            NODE     NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          4m45s   172.16.92.6   node-1   <none>           <none>
# curl http://172.16.92.6
```

在远程节点（有 kubectl 和 admin.kubeconfig 配置）执行：

```
# POD_NAME=$(kubectl get pods -l run=nginx -o jsonpath="{.items[0].metadata.name}")
# kubectl port-forward $POD_NAME 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

在远程节点另外一个终端执行：

```
# curl --head http://127.0.0.1:8080
HTTP/1.1 200 OK
Server: nginx/1.15.12
Date: Thu, 02 May 2019 08:24:59 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 16 Apr 2019 13:08:19 GMT
Connection: keep-alive
ETag: "5cb5d3c3-264"
Accept-Ranges: bytes
```

**注意**
1. pod 所在的节点必须安装有 `socat` 程序

### Logs

```sh
kubectl logs $POD_NAME
```

### Exec

```sh
kubectl exec -ti $POD_NAME -- nginx -v
```

## Services

```sh
kubectl expose pod nginx --port 80 --type NodePort
```

获取端口:

```sh
NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
```

使用任意节点的外部 IP 测试皆可访问：

```
curl -I "http://192.168.1.72:${NODE_PORT}"
curl -I "http://192.168.1.71:${NODE_PORT}"
curl -I "http://192.168.1.61:${NODE_PORT}"
```

查看日志也可以发现：

```
$ kubectl logs $POD_NAME --tail=3
172.16.1.1 - - [16/May/2019:07:47:24 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.54.0" "-"
172.16.0.0 - - [16/May/2019:07:47:27 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.54.0" "-"
172.16.2.0 - - [16/May/2019:07:47:41 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.29.0" "-"
```
