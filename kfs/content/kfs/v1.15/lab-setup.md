---
title: "搭建实验环境"
weight: 12
pre: "<b>4. </b>"
date: 2019-05-15
draft: false
tags: ["v1.15", "kvm"]
---

![服务器规划](/kfs/v1.15/static/servers.png)

**说明**

1. 使用 libvirtd + kvm + openvswitch 在 ooclab 工作站上搭建的 3 个实验用的虚拟机。


## 初始化服务器

实验环境使用 ansible 统一初始化服务器。

```sh
mkdir -pv $KFS_INSTALL/kubernetes-setup/
cd $KFS_INSTALL/kubernetes-setup/
cat > hosts <<EOF
[masters]
master-1 ansible_host=192.168.1.61 ansible_user=root ansible_port=22

[nodes]
master-1 ansible_host=192.168.1.61 ansible_user=root ansible_port=22
node-1 ansible_host=192.168.1.71 ansible_user=root ansible_port=22
node-2 ansible_host=192.168.1.72 ansible_user=root ansible_port=22
EOF
```

### Master

创建 **master-playbook.yml** 内容如下：

```sh
cat > master-playbook.yml <<EOF
- hosts: masters
  become: true

  roles:
  - geerlingguy.repo-epel

  tasks:

  - name: set hostname to {{inventory_hostname}}
    hostname:
      name: "{{ inventory_hostname }}"

  - name: 禁用 selinux
    selinux:
      state: disabled

  - name: 禁用 aliyun service
    service:
      name: aliyun
      enabled: no
      state: stopped

  - name: 禁用 aegis
    service:
      name: aegis
      enabled: no
      state: stopped

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
      - ntp
      - bind-utils
EOF
```

初始化所有 Master 节点：

```sh
ansible-playbook -i hosts master-playbook.yml
```

### Node

创建 **node-playbook.yml** 内容如下：

```sh
cat > node-playbook.yml <<EOF
- hosts: nodes
  become: true

  roles:
  - geerlingguy.repo-epel

  tasks:

  - name: set hostname to {{inventory_hostname}}
    hostname:
      name: "{{ inventory_hostname }}"

  - name: 禁用 selinux
    selinux:
      state: disabled

  - name: 禁用 aliyun service
    service:
      name: aliyun
      enabled: no
      state: stopped

  - name: 禁用 aegis
    service:
      name: aegis
      enabled: no
      state: stopped

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
      - ntp
      - socat
      - conntrack
      - ipset
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
Host k8s-master-1
    port 22
    user root
    hostname 192.168.1.61
Host k8s-node-1
    port 22
    user root
    hostname 192.168.1.71
Host k8s-node-2
    port 22
    user root
    hostname 192.168.1.72
```

现在可以从 ooclab 通过 ssh 登录：

```
ssh -v k8s-master-1
ssh -v k8s-node-1
ssh -v k8s-node-2
```

**注意**

我使用的 openvswitch , 所有 Master , Node 节点和 ooclab ， mbp （我的工作笔记本）都在一个局域网。
我在后面测试 `kubectl proxy` 时，需要从 mbp 上执行该命令，以便 mbp 上的浏览器可以访问 `localhost`
域的 kubernetes dashborad 。

### 操作系统

确认 **k8s-master-1** , **k8s-node-1** , **k8s-node-2** 操作系统配置：

1. 禁止 selinux （运行 `sestatus` 检查）
2. 如果 swap 分区启用的话，请禁用之（运行 `free` 检查，运行 `swapoff -a` 禁用, 并修改 **/etc/fstab** 禁止 swap 分区）
3. 检查虚拟机的第一块网卡的 IP 是否为局域网的 IP ，如果不是，在安装 flannel 服务时，请修改 flannel 的默认网卡行为。
