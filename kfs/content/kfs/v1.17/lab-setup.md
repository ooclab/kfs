---
title: "搭建实验环境"
weight: 12
pre: "<b>4. </b>"
date: 2019-11-24
draft: false
tags: ["kvm"]
---

说明：

1. K8S 的 Master 和 Node 节点操作系统为 `CentOS 8 x86_64`
2. 禁用 `firewalld` 和 `selinux` 服务
3. 禁用 swap 分区
4. 下文示例中的 IP 地址请换为真实 IP。

## 初始化服务器

实验环境使用 ansible 统一初始化服务器。

```sh
mkdir -pv $KFS_INSTALL/kubernetes-setup/
cd $KFS_INSTALL/kubernetes-setup/
cat > hosts <<EOF
[masters]
master-1 ansible_host=192.168.0.188 ansible_user=root ansible_port=22

[nodes]
master-1 ansible_host=192.168.0.188 ansible_user=root ansible_port=22
node-1 ansible_host=192.168.0.189 ansible_user=root ansible_port=22
EOF
```

### Master

本实验中，Master 节点同时也是 Node 角色，在下面 Node 节点初始化即可。

### Node

创建 **node-playbook.yml** 内容如下：

```sh
cat > node-playbook.yml <<EOF
- hosts: nodes
  become: true

  tasks:

  - name: set hostname to {{inventory_hostname}}
    hostname:
      name: "{{ inventory_hostname }}"

  - name: 禁用 selinux
    selinux:
      state: disabled

  - name: update centos
    yum:
      name: '*'
      state: latest

  - name: install basic packages
    yum:
      name: "{{ packages }}"
    vars:
      packages:
      - wget
      - vim
      - htop
      - dstat
      - lsof
      - tree
      - tmux
      - rsync
      - chrony
      - socat
      - conntrack
      - ipset
      - net-tools
      - nfs-utils
EOF
```

初始化所有 Node 节点：

```sh
ansible-playbook -i hosts node-playbook.yml
```


## 检查

### 登录虚拟机

> 实验中执行命令的用户，如果无特殊说明，默认是 root 用户。请配置好 root 用户的 ssh 公钥免密登录。

在 ooclab 的 `~/.ssh/config` 添加配置：

```
Host master-1
    port 22
    user root
    hostname 192.168.0.188
Host node-1
    port 22
    user root
    hostname 192.168.0.189
```

现在可以从 mbp 通过 ssh 登录：

```
ssh -v master-1
ssh -v node-1
```

### 操作系统

确认 **master-1** , **node-1** 操作系统配置：

1. 禁止 selinux （运行 `sestatus` 检查）
2. 如果 swap 分区启用的话，请禁用之（运行 `free` 检查，运行 `swapoff -a` 禁用, 并修改 **/etc/fstab** 禁止 swap 分区）
3. 检查虚拟机的第一块网卡的 IP 是否为局域网的 IP ，如果不是，在安装 flannel 服务时，请修改 flannel 的默认网卡行为。
