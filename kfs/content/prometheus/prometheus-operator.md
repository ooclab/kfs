---
title: "Prometheus Operator"
date: 2019-05-03T13:00:00+08:00
draft: false
tags: ["v1.14.1", "kubernetes", "addons", "prometheus"]
---

部署：
```sh
wget https://raw.githubusercontent.com/coreos/prometheus-operator/master/bundle.yaml
mv bundle.yaml prometheus-operator-bundle.yaml
kubectl apply -f prometheus-operator-bundle.yaml
```
