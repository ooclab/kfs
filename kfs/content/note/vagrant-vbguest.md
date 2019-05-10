---
title: "安装 vagrant-vbguest 插件"
date: 2019-05-04T12:40:00+08:00
draft: false
tags: ["v1.14.1", "vagrant", "vbguest"]
---


参考：

- [VirtualBox Guest Additions](https://github.com/mesosphere-backup/dcos-vagrant/blob/master/docs/virtualbox-guest-additions.md)
- [https://github.com/dotless-de/vagrant-vbguest/](https://github.com/dotless-de/vagrant-vbguest/)


## 步骤

### 1. 下载 iso

在 [https://download.virtualbox.org/virtualbox](https://download.virtualbox.org/virtualbox) 找到对应的版本，下载并挂载 iso。示例：

```sh
wget https://download.virtualbox.org/virtualbox/6.0.6/VBoxGuestAdditions_6.0.6.iso
sudo cp VBoxGuestAdditions_6.0.6.iso /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso
```

### 2. 安装 vagrant plugin

```sh
vagrant plugin install vagrant-vbguest
```

### 3. 配置 Vagrantfile

**说明**

> Mac 平台如果 /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso 存在，无需配置 iso_path 。

Vagrantfile 中添加配置示例：

```ruby
    # 共享目录（需要安装好 guest 驱动才可以注销掉下面几行）
    config.vm.synced_folder ENV["KFS_HOME"], "/kfslab", type: "virtualbox"
    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false  
    end
```


### 其他

强制重新安装

```
vagrant vbguest --do install
```

## FAQ

### setup: command not found

```
==> k8s-node-1: Checking for guest additions in VM...
The following SSH command responded with a non-zero exit status.
Vagrant assumes that this means the command failed!

 setup

Stdout from the command:



Stderr from the command:

bash: line 4: setup: command not found
```

参考

- [vagrant-vbguest doesn't work with vagrant-reload](https://github.com/dotless-de/vagrant-vbguest/issues/333)

解决方案，在配置文件增加

```ruby
    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false  
    end
```