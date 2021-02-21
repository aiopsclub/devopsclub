---
title : "docker系列之buildkit"
weight : 1 
---
> 下一代镜像构建工具buildkit 

## BuildKit 简介

buildkit 是下一代 docker 构建组件，拥有众多特性：

- 自动垃圾收集
- 可扩展的前端格式
- 并发依赖项解析
- 高效的指令缓存
- 构建缓存导入/导出
- 嵌套的构建作业调用
- 可配置的构建底层,包括 OCI (runc)和 containerd，未来将加入更多的构建底层
- 多种输出格式
- 可插拔架构
- 无需 root 权限  

**BuildKit的build输出**：
![](https://static01.imgkr.com/temp/b3d0f333180f4924afd992e4dae05ed4.png)

## Buildkit 内部格式 LLB

**BuildKit**构建基于一种称为 LLB 的二进制中间格式，该格式用于为构建流程定义依赖关系图，依赖 LLB 的优点，它为构建流程提供强大的特性:

- 可封装为 Protobuf messages
- 并行执行
- 高效缓存
- 供应商中立[可自定义其实现]

## BuildKit 新语法之 RUN --mount

注意：为了支持此语法，需在 dockerfile 文件加入以下内容

```bash
# syntax=docker/dockerfile:1.2
```

RUN --mount 允许您创建 mount，该 mount 作为构建期间可以访问的一部分。该特性可用于从构建的其他部分绑定文件，而无需复制、访问构建 secrets 或 ssh-agent 套接字，或着创建缓存位置从而加速构建。  
支持以下语法：

- RUN --mount=type=bind 默认挂载类型  
  这种挂载类型允许将上下文或 image 中的目录(只读)绑定到构建容器中。  
  
|选项               |描述|
|---------------------|-----------|
|`target` (required)  | 挂载路径.|
|`source`             | 源路径基于`from`. 默认是`from`的根路径.|
|`from`               | 指定挂载的源头，可以是构建阶段名称或者镜像名称. 默认为构建上下文.|
|`rw`,`readwrite`     | 读写模式，数据将会被丢弃.|
- RUN --mount=type=cache  
此挂载类型允许挂载缓存目录，从而访问缓存。  

|Option               |Description|
|---------------------|-----------|
|`id`                 | 可选 区分不同的缓存|
|`target` (required)  | 挂载路径.|
|`ro`,`readonly`      | 是否只读.|
|`sharing`            | `shared`, `private`, `locked`三者其一. 默认`shared`. `shared` 缓存挂载可以被多个写入器同时使用. `private` 如果有多个写入，则创建一个新的挂载. `locked` 暂停第二个写入器，直到第一个写入器释放mount.|
|`from`               | 作为缓存挂载的基础的构建阶段名称。默认为空目录|
|`source`             | 将要挂载的`from`的子路径. 默认是`from`的根路径.|
|`mode`               | 新缓存目录的文件模式. 默认0755.|
|`uid`                | 新缓存目录的用户ID. 默认为0.|
|`gid`                | 新缓存目录的组ID. 默认为0.|
- RUN --mount=type=tmpfs   
这种挂载类型允许在build容器时挂载tmpfs。 

|Option               |Description|
|---------------------|-----------|
|`target` (required)  | 挂载路径.|
- RUN --mount=type=secret
这种挂载类型允许生成容器访问安全文件，比如私钥，而无需将它们放入映像中  

|Option               |Description|
|---------------------|-----------|
|`id`                 | secret的id. 默认为target path的basename.|
|`target`             | 挂载路径. 默认`/run/secrets/` + `id`.|
|`required`           | 如果设置为`true`，当secret不可用时，指令会出错。默认为`false`.|
|`mode`               | 文件的模式. 默认为0400.|
|`uid`                | UID. 默认 0.|
|`gid`                | Group ID. 默认 0.|

- RUN --mount=type=ssh  
这种挂载类型允许构建容器通过ssh agent访问 SSH keys，并支持密码.  

|Option               |Description|
|---------------------|-----------|
|`id`                 | SSH代理套接字或密钥ID. 默认为"default".|
|`target`             | SSH代理套接字路径. 默认为`/run/buildkit/ssh_agent.${N}`.|
|`required`           | 如果设置为`true`，当secret不可用时，指令会出错。默认为`false`.|
|`mode`               | 套接字文件模式. 默认0600.|
|`uid`                | socket的用户ID. 默认0.|
|`gid`                | socket的组ID. 默认0.|


## BuildKit 新语法之 RUN --security=insecure|sandbox
注意: 使用此语法需要在dockerfile加入以下内容:
```bash
#syntax=docker/dockerfile:1.2-labs
```
使用--security=insecure，构建器可以在非安全模式下运行非沙盒的命令，再运行需要特权的工作流中是需要的(例如containerd)。作用类似于`docker run --privileged`。为了启用此特性，`security.insecure`应该开启，即在buildkitd启动时开启(--allow-unsecure-entitlement security.insecure)和(--allow security.insecure)选项。

默认的sandbox模式可以通过 --security=sandbox开启，但这是没什么作用的。  

## BuildKit 新语法之 RUN --network=none|host|default
注意: 使用此语法需要在dockerfile加入以下内容:
```bash
#syntax=docker/dockerfile:1.2-labs
```
此指令主要为了构建运行命令是指定不同的网络模式。


## BuildKit 支持情况

自 docker 18.06 起，BuildKit 就被集成到 docker build 中，设置 docker BUILDKIT=1 环境变量即可轻松开启。

参考文档：

- https://github.com/moby/buildkit
- https://docs.docker.com/develop/develop-images/build_enhancements/
- https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md

