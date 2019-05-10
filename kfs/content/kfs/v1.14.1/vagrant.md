---
title: "搭建实验环境"
weight: 12
pre: "<b>4. </b>"
date: 2019-05-04T12:40:00+08:00
draft: false
tags: ["v1.14.1", "vagrant"]
---

![服务器规划](/kfs/v1.14.1/static/servers.png)

**说明**

1. 实践过程中，我们需要确保 mbp 的 $KFS_HOME 和其他 3 个虚拟机(k8s-master-1, k8s-node-1, k8s-node-2) 的 /kfslab 目录保持一致。
2. 如果使用 virtualbox 挂载 Host (mbp) $KFS_HOME 目录到每一个虚拟机的 /kfslab 目录，请参考 [安装 vagrant-vbguest 插件](/note/vagrant-vbguest/) 。否则请使用 rsync 等工具，及时同步 mbp 的 $KFS_HOME 到每一个虚拟机 的 /kfslab 目录。


### 创建 vagrant 配置

在 mbp 执行

#### 1. 创建 Vagrantfile

**说明**

> vagrant 主目录（含 Vagrantfile 的目录）不要存放非必要文件，比如 kubernetes 下载包等。
> 因为 vagrant 默认会挂载当前目录到虚拟机的 /vagrant 。[Synced Folders](https://www.vagrantup.com/docs/synced-folders/)

```sh
cd $KFS_VOS
vim Vagrantfile
```

创建 **Vagrantfile** 内容如下：

```ruby
IMAGE_NAME = "centos/7"
TOTAL_MASTER = 1
TOTAL_NODE = 2

if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false  
end

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false
    config.vm.box = IMAGE_NAME
    config.vm.box_check_update = false

    # 禁止默认的目录同步行为
    config.vm.synced_folder ".", "/vagrant", disabled: true

    # 共享目录（需要安装好 guest 驱动才可以注销掉下面几行）
    # config.vm.synced_folder ENV["KFS_HOME"], "/kfslab", type: "virtualbox"
    # if Vagrant.has_plugin?("vagrant-vbguest")
    #     config.vbguest.auto_update = false  
    # end

    config.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.cpus = 2
    end


    (1..TOTAL_MASTER).each do |i|
      config.vm.define "k8s-master-#{i}" do |master|
          master.vm.network "private_network", ip: "192.168.100.#{i + 10}"
          master.vm.hostname = "k8s-master-#{i}"
          master.vm.provision "ansible" do |ansible|
              ansible.playbook = "kubernetes-setup/master-playbook.yml"
          end
      end
    end

    (1..TOTAL_NODE).each do |i|
        config.vm.define "k8s-node-#{i}" do |node|
            node.vm.network "private_network", ip: "192.168.100.#{i + 30}"
            node.vm.hostname = "k8s-node-#{i}"
            node.vm.provision "ansible" do |ansible|
                ansible.playbook = "kubernetes-setup/node-playbook.yml"
            end
        end
    end

end
```

#### 2. 创建 kubernetes-setup 目录

```
mkdir -pv kubernetes-setup
```

#### 3. 创建 kubernetes-setup/master-playbook.yml

```sh
vim kubernetes-setup/master-playbook.yml
```

创建 **kubernetes-setup/master-playbook.yml** 内容如下：

```yaml
- hosts: all
  become: true

  roles:
  - geerlingguy.repo-epel

  tasks:

  # Disable SELinux
  - selinux:
      state: disabled

  - name: Disable SWAP since kubernetes can't work with swap enabled (1/2)
    shell: |
      swapoff -a

  - name: Disable SWAP in fstab since kubernetes can't work with swap enabled (2/2)
    replace:
      path: /etc/fstab
      regexp: '^([^#].+?\sswap\s+.*)$'
      replace: '# \1'

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
      - nginx
```

#### 4. 创建 kubernetes-setup/node-playbook.yml

```sh
vim kubernetes-setup/node-playbook.yml
```

创建 **kubernetes-setup/node-playbook.yml** 内容如下：

```yaml
- hosts: all
  become: true

  roles:
  - geerlingguy.repo-epel

  tasks:

  - name: 禁用 selinux
    selinux:
      state: disabled

  - name: 停用 swap 分区 (kubelet) (1/2)
    shell: |
      swapoff -a

  - name: 修改 fstab ，系统下次启动时禁用 swap 分区 (2/2)
    replace:
      path: /etc/fstab
      regexp: '^([^#].+?\sswap\s+.*)$'
      replace: '# \1'

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
```

### 创建虚拟机并启动

```
vagrant up
```

### 登录虚拟机

> 实验中执行命令的用户，如果无特殊说明，默认是 root 用户

以 __k8s-master-1__ 虚拟机为例，执行：
```sh
$ cd $KFS_HOME
$ vagrant ssh k8s-master-1
[vagrant@k8s-master-1 ~]$ sudo -i
[root@k8s-master-1 ~]# mkdir -p .ssh
[root@k8s-master-1 ~]# vim .ssh/authorized_keys
# 粘贴 mbp 上的 ~/.ssh/id_rsa.pub 内容，保存即可
```

在 mbp 的 `~/.ssh/config` 添加配置：

```
Host k8s-master-1
    port 22
    user root
    hostname 192.168.100.11
```

现在可以从 mbp 通过 ssh 登录 **k8s-master-1** 服务器：

```
ssh -v k8s-master-1
```

其他虚拟机 ( k8s-node-1, k8s-node-2 ) 操作类似。


## 检查

### 操作系统

确认 **k8s-master-1** , **k8s-node-1** , **k8s-node-2** 操作系统配置：

1. 禁止 selinux
2. `swapoff -a` , 并修改 **/etc/fstab** 禁止 swap 分区


## FAQ

### 虚拟机 的 eth0 IP 全部是 **10.0.2.15**

- [eth0 as NAT is a fundamental requirement of Vagrant in its current state](https://github.com/hashicorp/vagrant/issues/2093)

### Read-only file system (RuntimeError)

参考 [trun off swap cause vagrant up failed](https://github.com/hashicorp/vagrant/issues/10593)

`vagrant up` 详细错误如下:

```
==> k8s-node-1: Configuring and enabling network interfaces...
/opt/vagrant/embedded/gems/2.2.4/gems/net-scp-1.2.1/lib/net/scp.rb:398:in `await_response_state': scp: /tmp/vagrant-network-entry-eth1-1557190901-0: Read-only file system (RuntimeError)
        from /opt/vagrant/embedded/gems/2.2.4/gems/net-scp-1.2.1/lib/net/scp.rb:369:in `block (3 levels) in start_command'
        from /opt/vagrant/embedded/gems/2.2.4/gems/net-ssh-5.1.0/lib/net/ssh/connection/channel.rb:323:in `process'
        from /opt/vagrant/embedded/gems/2.2.4/gems/net-ssh-5.1.0/lib/net/ssh/connection/session.rb:250:in `block in ev_preprocess'
        from /opt/vagrant/embedded/gems/2.2.4/gems/net-ssh-5.1.0/lib/net/ssh/connection/session.rb:540:in `each'
```

这里不是参考链接中提到的 swap 问题，而是我们修改 swap 分区时错误地把根分区注释掉，因此出错。

虽然报错，但是服务器已经启动。登录服务器，检查 **/etc/fstab** 最后两行，发现：

```
# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Thu Feb 28 20:50:01 2019
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
# UUID=f52f361a-da1a-4ea0-8c7f-ca2706e86b46 /                       xfs     defaults        0 0
# /swapfile none swap defaults 0 0
```

查看根分区确实挂载为 `ro` :
```
# mount |grep xfs
/dev/sda1 on / type xfs (ro,relatime,attr2,inode64,noquota)
```

重新挂载根分区：

```sh
mount -o remount,rw --uuid f52f361a-da1a-4ea0-8c7f-ca2706e86b46 /
```

### symlink has no referent

vagrant up 详细错误如下：

```
==> k8s-master-1: Rsyncing folder: /Users/gwind/kfslab/ => /vagrant

There was an error when attempting to rsync a synced folder.
Please inspect the error message below for more info.

Host path: /Users/gwind/kfslab/
Guest path: /vagrant
Command: "rsync" "--verbose" "--archive" "--delete" "-z" "--copy-links" "--no-owner" "--no-group" "--rsync-path" "sudo rsync" "-e" "ssh -p 2200 -o LogLevel=FATAL   -o ControlMaster=auto -o ControlPath=/var/folders/5s/fcy1xt5s51d7r6xljhmxh
qj80000gn/T/vagrant-rsync-20190507-75080-1povtee -o ControlPersist=10m  -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i '/Users/gwind/.vagrant.d/insecure_private_key'" "--exclude" ".vagrant/" "/Users/g
wind/kfslab/" "vagrant@127.0.0.1:/vagrant"
Error: /etc/profile.d/lang.sh: line 19: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
symlink has no referent: "/Users/gwind/kfslab/v1.14.1/kubernetes/client/bin"
rsync error: some files could not be transferred (code 23) at /BuildRoot/Library/Caches/com.apple.xbs/Sources/rsync/rsync-52.200.1/rsync/main.c(996) [sender=2.6.9]
```

原因是 kubernetes 在 Vagrantfile 同一级目录。


### 禁用 synced folders

参考 [Disabling synced folders](https://www.vagrantup.com/docs/synced-folders/basic_usage.html#disabling)

默认情况下，vagrant 会将 Vagrantfile 所在的目录同步到虚拟机的 /vagrant 目录。可以禁用这一行为。

### synced folders 不能实时同步

检查 synced_folders 实现：

```
➜  vos cat .vagrant/machines/k8s-master-1/virtualbox/synced_folders
{"rsync":{"/vagrant":{"type":"rsync","guestpath":"/vagrant","hostpath":"/Users/gwind/kfslab/vos","disabled":false,"__vagrantfile":true,"owner":"vagrant","group":"vagrant"}}}
```

发现使用了 `rsync`

配置使用 **virtualbox** 即可。

参考 [Updated CentOS Vagrant Images Available (v1704.01)](https://blog.centos.org/2017/05/updated-centos-vagrant-images-available-v1704-01/)

### Vagrant was unable to mount VirtualBox shared folders

提示 guest OS (CentOS 7) 缺少 **vboxsf** ：

```
==> k8s-master-1: Mounting shared folders...
    k8s-master-1: /kfslab => /Users/gwind/kfslab
Vagrant was unable to mount VirtualBox shared folders. This is usually
because the filesystem "vboxsf" is not available. This filesystem is
made available via the VirtualBox Guest Additions and kernel module.
Please verify that these guest additions are properly installed in the
guest. This is not a bug in Vagrant and is usually caused by a faulty
Vagrant box. For context, the command attempted was:

mount -t vboxsf -o uid=1000,gid=1000 kfslab /kfslab

The error output from the command was:

mount: unknown filesystem type 'vboxsf'
```

需要安装 guest

### vm.rb:649:in `initialize': no implicit conversion of nil into String (TypeError)

我在 Vagrantfile 里使用了环境变量 `$KFS_HOME` , 如果未初始化（不如新开一个终端窗口），执行 `vagrant up` 就会出现下面错误：

```
➜  vos vagrant up
Bringing machine 'k8s-master-1' up with 'virtualbox' provider...
Bringing machine 'k8s-node-1' up with 'virtualbox' provider...
Bringing machine 'k8s-node-2' up with 'virtualbox' provider...
/opt/vagrant/embedded/gems/2.2.4/gems/vagrant-2.2.4/plugins/kernel_v2/config/vm.rb:649:in `initialize': no implicit conversion of nil into String (TypeError)
        from /opt/vagrant/embedded/gems/2.2.4/gems/vagrant-2.2.4/plugins/kernel_v2/config/vm.rb:649:in `new'
        from /opt/vagrant/embedded/gems/2.2.4/gems/vagrant-2.2.4/plugins/kernel_v2/config/vm.rb:649:in `block in validate'
        from /opt/vagrant/embedded/gems/2.2.4/gems/vagrant-2.2.4/plugins/kernel_v2/config/vm.rb:644:in `each'
        from /opt/vagrant/embedded/gems/2.2.4/gems/vagrant-2.2.4/plugins/kernel_v2/config/vm.rb:644:in `validate'
```

解决方案：

```sh
source $KFS_HOME/setting
```