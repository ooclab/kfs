---
title: "Kubernetes Dashboard"
weight: 100
pre: "<b>10. </b>"
date: 2019-05-03T10:00:00+08:00
draft: false
tags: ["v1.14.1", "Kubernetes", "Addons"]
---

## 部署 Dashboard

**说明** 在 **mbp** 执行操作

在 [https://github.com/kubernetes/dashboard/releases](https://github.com/kubernetes/dashboard/releases) 下载 `v1.10.1` 配置文件：

```sh
mkdir -p $KFS_HOME/addons/dashboard
cd $KFS_HOME/addons/dashboard
wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```

修改 `kubernetes-dashboard.yaml` ：

- `k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1` 修改为 `omio/k8s.gcr.io.kubernetes-dashboard-amd64:v1.10.1`

部署：

```sh
kubectl apply -f kubernetes-dashboard.yaml
```

启动 `kubectl proxy`：

```
kubectl proxy
```

等待 dashboard 部署完成，访问 [http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy)

## admin user token

参考 [Creating sample user](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user)

创建

```sh
# 创建配置文件
cat > kubernetes-dashboard-admin.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF

# 应用配置
kubectl apply -f kubernetes-dashboard-admin.yaml
# 获取 token
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

最后一条命令输出如下：
```
Name:         admin-user-token-w92l4
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: admin-user
              kubernetes.io/service-account.uid: de39da99-6d55-11e9-98ed-525400261060

Type:  kubernetes.io/service-account-token

Data
====
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLXc5Mmw0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJkZTM5ZGE5OS02ZDU1LTExZTktOThlZC01MjU0MDAyNjEwNjAiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06YWRtaW4tdXNlciJ9.REHia-v_F2d38s78sZjMuY5H9AmJZjPVSBYoKwofhYqC73XYjk3aEk5nOUdkvENUv-X7jqhVKbbqxH0fsDAOZxHkM3MAE1X8b3FbqYAaz9K2EEI_LgmMGcxAG1I4pcPKB9glg1N4hj4nZoW4CweRSUftXTd1cGtaUfVyT9cJBcM_py7DKDe8OPjSMVcoezyseNsZKDdNZIKsg6FcYoQ5zbqBFM6PcKmYfKzfFRVNxZcjzIx9yINTCwlr_YBKnmu4BZDhu0Ty29X9R4uaDwOKjz-dx8nyq6jc3bP-lZy_2TtTUVgUd6qwx55Nm1lDl0kj7W1hFTFWyQSoEOFbU3yyrw
ca.crt:     1318 bytes
```

其中 `token` 即可以在登录 dashboard 时使用。
