# 创建虚拟机

创建 libvirt 虚拟机配置

说明：

- 以 CentOS 8 为例（使用 cloud-init 初始化）

## 初始化

### 配置静态网络

CentOS 8 不要手动编辑 `/etc/sysconfig/network-scripts/ifcfg-ens3` 文件，可使用 nmcli 修改。

```bash
# IP
nmcli c mod ens3 ipv4.address 192.168.31.10/24
# 网关
nmcli c mod ens3 ipv4.gateway 192.168.31.1
# 手动模式
nmcli c mod ens3 ipv4.method manual
# DNS
nmcli c mod ens3 ipv4.dns 8.8.8.8
# 保存
nmcli c up ens3
```
