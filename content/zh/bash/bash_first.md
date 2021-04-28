---
title : "bash脚本还能这么写?"
weight : 1 
---
> 工作学习中，shell脚本是日常基本需求，你印象中的脚本应该是这样的：命令的堆砌、从上到下依次执行、杂乱无章、实现功能就行，导致自己写的脚本自己都不想看，今天我就教你怎么写脚本，学完之后，一定会说一句，脚本还能这么写！

现以nginx控制脚本为例，看一下脚本的美容过程：

```shell
#!/bin/bash
# set用法在文章末尾
set -eu

# nginx配置重载


nginx -c /etc/nginx/nginx.conf -t
kill -1 ```ps auxf | grep -E "nginx:[[:space:]]+master"| awk '{print $2}'`
```

## 1. 变量替换

在平常的开发中，脚本会依赖很多的配置，例如监听端口、配置文件之类的可变参数，如果我们将其硬编码到脚本中，那么改起来就是牵一发动全身了，很麻烦，不可靠。测试我们就需要变量来帮忙了，这样只需要修改一处，脚本整体生效，高效很多。

```shell
#!/bin/bash
# set用法在文章末尾
set -eu
# nginx配置文件在不同环境中可能不同，所以需要将其抽离成可配置变量，后面来引用
NGINX_CONFIG_FILE=/etc/nginx/nginx.conf

# nginx重载配置
nginx -c $NGINX_CONFIG_FILE -t
kill -HUP ```ps auxf | grep -E "nginx:[[:space:]]+master"| awk '{print $2}'`
```



## 2.模块化

运维毕竟开发，写脚本时就是从上到下依次执行，命令的堆砌，这就导致脚本复用性差，不易维护，解决这问题的关键在于函数化、模块化思想，shell虽然是一种比较简单的语言，但语言基本的逻辑控制、函数功能都有，这就让我们编写高质量shell脚本充满了想象。接下来，上菜：
```shell
# 由于nginx配置文件检查是执行其他操作的第一步，所以我们将其独立成一个单独函数
#!/bin/bash
# set命令的奇妙用途留在文章末尾
set -eu
# nginx配置文件在不同环境中，位置可能不同，所以需要将其抽离成可配置变量，脚本来引用
NGINX_CONFIG_FILE=/etc/nginx/nginx.conf

# 抽离配置文件检查为单独的函数
config_test() {
    nginx -c $NGINX_CONFIG_FILE -t

}
get_nginx_master_pid(){
    echo `ps auxf | grep -E "nginx:[[:space:]]+master"| awk '{print $2}'`

}
# 抽离配置重载为独立函数
reload() {
    kill -HUP `get_nginx_master_pid`

}

# nginx重载配置文件
config_test
reload


`````



## 3.main函数

脚本的可维护性在于脚本的结构的好坏，为了拥有更好的结构，通常需要在脚本中定义入口函数，即main函数，让我在维护脚本时，可以更好的把握脚本的组织架构，找到切入点：

```shell
# 由于nginx配置文件检查是执行其他操作的第一步，所以我们将其独立成一个单独函数
#!/bin/bash
# set命令的奇妙用途留在文章末尾
set -eu
# nginx配置文件在不同环境中，位置可能不同，所以需要将其抽离成可配置变量，脚本来引用
NGINX_CONFIG_FILE=/etc/nginx/nginx.conf

# 抽离检查配置文件为函数
config_test() {
    nginx -c $NGINX_CONFIG_FILE -t

}

get_nginx_master_pid(){
    echo `ps auxf | grep -E "nginx:[[:space:]]+master"| awk '{print $2}'`

}
# 抽离配置重载为函数
reload() {
    kill -HUP `get_nginx_master_pid`

}

# 脚本入口
main() {
    config_test
    reload

}

# main在此需要获取脚本本身的参数， 故将$@传递给main函数
main $@
`````



## 4.函数返回值

在其他编程语言，可以通过return获取函数的返回值，但是return语句在shell中含义不同，return在默认会返回上一次命令的执行状态码。那如何实现类似其他编程语言的return效果呢？可以使用echo命令:

```shell
#!/bin/bash
set -eu
NGINX_CONFIG_FILE=/etc/nginx/nginx.conf

config_test() {
    nginx -c $NGINX_CONFIG_FILE -t

}

# 在此处直接把nginx的master pid可以通过反引号来获取echo后的值
get_nginx_master_pid(){
    echo `ps auxf | grep -E "nginx:[[:space:]]+master"| awk '{print $2}'`

}

reload() {
    # `get_nginx_master_pid` 获得nginx master pid
    nginx_pid=`get_nginx_master_pid`
    kill -HUP $nginx_pid 

}

# 脚本入口
main() {
    config_test
    reload

}

# main需要获取脚本本身的所有参数， 故将$@传递给main函数
main $@
`````



## 5.set命令

内置的set命令，可以改变我们脚本的执行行为，让我们对脚本的把握和调试更强，下面是常用的几种set指令，相信你会喜欢的：

- set -e: bash脚本遇到错误立即退出
- set -n: 检查脚本语法但不执行
- set -u: 遇到未设置的变量立即退出
- set -o pipefail: 控制在管道符执行过程中有错误立即退出
- set -x: 分步调试命令

在写脚本时，我们可以直接在脚本开头添加如下内容:

```shell
#!/bin/bash
set -euxo pipefail
`````

检查bash脚本的语法时，可以这样写:

```
bash -n main.sh
```
## 6.组命令
有的时候我们有这样的需求，对文本内容的修改，不是简单一条命令来实现，需要两条命令，在一定条件下，一起执行，类似于事务的概念，这就要通过()来实现，括号中的命令将会新开一个子shell顺序执行，所以括号中的变量不能够被脚本余下的部分使用。括号中多个命令之间用分号隔开，最后一个命令可以没有分号，各命令和括号之间不必有空格。
```shell
ip a | grep docker0 || (ip link add name docker0 type bridge && ip addr add dev docker0 172.17.0.1/16)
    `````

## 7.stderr重定向至stdout
脚本开发过程中，在我们使用管道时，默认只是传递stdout，在某种场景下，比如需要根据stderr的内容进行判断，默认情况下就不支持，需要我们进行特殊处理，stderr重定向至stdout，那具体怎么做呢？看下面的示例:
```shell
 kubectl create clusterrolebinding kube-apiserver:kubelet-apis --clusterrole=system:kubelet-api-admin --user kubernetes 2>&1 | grep -E -i "created|exists" > /dev/null
 `````
重点在于，2>&1。



#### 推荐阅读

---

欢迎关注公众号“**DevOps充电宝**”，原创技术文章第一时间推送。

<center>
    <img src="https://www.aiopsclub.com/images/wxqrcode.jpg" style="width: 300px;">
</center>
 ````
    ````
```
```
````
````
````
````
```
`
```
`
