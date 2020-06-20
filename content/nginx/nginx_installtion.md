---
title: "2. Nginx系列之nginx安装部署"
state: Alpha
---
> 了解了nginx的强大之处，相信您恨不得马上上手开干。接下来就展示一下nginx多种部署方式，让你见识一下如此复杂的nginx竟也能如此平易近人，在你的手上，乖乖听话，任你号令。

##  nginx安装之包管理器

```shell
# 以RHEL/CentOs为例
# 1. 安装依赖工具
sudo yum groupinstall "Development tools" -y
sudo yum install yum-utils -y
# 2. 添加nginx的软件仓库
# 将以下内容写入/etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

# 默认启用的是nginx-stable，如果你想启用长期支持版，即nginx-mainline，可用以下命令开启
sudo yum-config-manager --enable nginx-mainline

# 3. 安装nginx
sudo yum install nginx

# 其他系统的安装方式可通过官方文档查看
http://nginx.org/en/linux_packages.html
```

## nginx安装之源码编译

```shell
# 1. 下载源码
wget http://nginx.org/download/nginx-1.19.0.tar.gz
# 2. 解压
tar xf nginx-1.19.0.tar.gz
# 3. 编译
cd nginx-1.19.0
./configure
    --sbin-path=/usr/local/nginx/nginx
    --conf-path=/usr/local/nginx/nginx.conf
    --pid-path=/usr/local/nginx/nginx.pid
    --with-http_ssl_module
    --with-pcre
    --with-zlib
make && make install
# 简单来说，nginx的编译基本就以上三步，不过在安装的过程中，通常会遇到许多依赖问题，这时候就需要你强大的搜索的技能来解决问题。记住，你遇到的问题肯定有解决办法，实在不行就用google，方法自行百度。

```

## nginx安装之docker部署

```shell
现在微服务日渐流行，docker在微服务的领域中地位非常重要，尤其是在k8s的编排能力加持下，那用起来是真的香。正因为docker的应用虚拟化，我们可以快速启动nginx，同时保持宿主机的整洁性。具体步骤如下
# 1. docker的安装
由于docker安装不是我们的重点，现在贴出文档，依据阿里云的安装文档即可快速安装docker服务； 文档地址：https://yq.aliyun.com/articles/110806?spm=5176.8351553.0.0.31341991DwMLPR
# 2. docker中nginx的安装
docker run --name nginx  --restart  always --net host -v 静态文件目录:/usr/share/nginx/html:ro  -v /etc/nginx/nginx.conf:/etc/nginx/nginx.conf:ro -d nginx
# 简单一条命令，就可以省去安装nginx的过程，直接快速启动我们的web服务，是不是非常爽。
```

## 总结

nginx的安装方式大致就以上三种，个人最爱docker的方式，它不仅仅可以用来快速测试，同时也可以在正式的环境中使用。天下武功，唯快不破。在当今快节奏的环境下，让我们不再为环境依赖而发愁，专注于我们的服务，提高我们的水平才是王道。

