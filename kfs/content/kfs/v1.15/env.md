---
title: "设置环境变量"
weight: 10
pre: "<b>2. </b>"
date: 2019-05-04T12:40:00+08:00
draft: false
tags: ["v1.15", "env"]
---

在 **ooclab** 创建实验工作目录：

```sh
export KFS_HOME=~/kfslab
mkdir -pv $KFS_HOME
cd $KFS_HOME
```

实验过程中，为了保持环境设置一致，我们创建一个 `setting` 文件，存放用到的环境变量，每次离开后再次返回，需要重新使 `setting` 中的环境变量生效。

创建 setting 文件：

```sh
cd $KFS_HOME

cat > setting <<EOF
export KFS_K8S_VERSION=v1.15.0-beta.2
export KFS_HOME=~/kfslab
export KFS_K8S_PKG_DIR="\${KFS_HOME}/\${KFS_K8S_VERSION}"
export KFS_CONFIG="\${KFS_HOME}/config"
export KFS_INSTALL="\${KFS_HOME}/install"
export KFS_K8S_PUBLIC_ADDRESS="192.168.1.61"
EOF

source setting
```

每次中断实验后，再次返回，先使得 `setting` 文件中的环境变量生效：

```sh
cd $KFS_HOME
source setting
```


**说明**

1. 默认我们使用 **~/kfslab** 作为 KFS 实验的主目录，后面的实验步骤中我们会使用 **$KFS_HOME** 环境变量代替该值。
2. 创建一个文件，可以使用任何喜欢的编辑器，注意文件所在的目录即可。示例，创建名为 **setting** 的文件，可以在终端当前目录执行 `vim setting` ，编辑该文件内容，保存退出即可。
