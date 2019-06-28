---
title: "阿里云 CSI 云盘存储应用"
weight: 101
date: 2019-06-10T20:40:00+08:00
draft: false
tags: ["aliyun", "阿里云", "Kubernetes", "CSI", "存储"]
---


## FAQ

### Your account does not have enough balance

查看 csi-provisioner 日志：

```sh
kubectl logs -f pod/csi-disk-provisioner-0 -c csi-provisioner
```

错误信息如下：

```
W0610 12:37:14.368966       1 controller.go:685] Retrying syncing claim "default/disk-pvc" because failures 3 < threshold 15
E0610 12:37:14.368997       1 controller.go:700] error syncing claim "default/disk-pvc": failed to provision volume with StorageClass "csi-disk": rpc error: code = Internal desc = SDK.ServerError
ErrorCode: InvalidAccountStatus.NotEnoughBalance
Recommend:
RequestId: CC492D50-D969-46D7-84E2-1ED781BAAE1D
Message: Your account does not have enough balance.
I0610 12:37:14.369032       1 event.go:221] Event(v1.ObjectReference{Kind:"PersistentVolumeClaim", Namespace:"default", Name:"disk-pvc", UID:"07e154db-97d7-4ac4-9d16-aa4c679a0814", APIVersion:"v1", ResourceVersion:"109333", FieldPath:""}): type: 'Warning' reason: 'ProvisioningFailed' failed to provision volume with StorageClass "csi-disk": rpc error: code = Internal desc = SDK.ServerError
ErrorCode: InvalidAccountStatus.NotEnoughBalance
Recommend:
RequestId: CC492D50-D969-46D7-84E2-1ED781BAAE1D
Message: Your account does not have enough balance.
```

原因：账户余额不足 100 元，不可以创建后付费资源（如云盘）

参考： [容器服务集群创建常见错误](https://yq.aliyun.com/articles/74615)
