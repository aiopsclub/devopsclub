---
title : "DevOps系列Helm as code"
weight : 1
---
> Helm as code 

### Helm as code
>作者介绍： helm 分支维护者 helmfile核心维护者

> 随着云原生的流行，kubernetes已然成为云原生的重要基础设施，但就k8s而言，其本身还是相当复杂，尤其是其各种资源的定义与配置，在经历千山万水构建好应用并且成功在k8s中运行后，应用本身的分发与配置又成为一个难题，这时helm就应运而生，原理就是通过Go模板语言结合kubernetes的资源定义文件，通过外部传值，来定义应用的不同行为，并且通过chart的形式来分发应用，解决k8s中原生应用管理的痛点。目前已经成为cncf毕业项目，在github上 star数量为20k以上，可见其流行程度。接下来我们将要学习helm以及如何实现helm的技术设施即代码： helm as code.
## Helm介绍
Helm 帮助您管理 Kubernetes 应用—— Helm Chart，即使是最复杂的 Kubernetes 应用程序，都可以帮助您定义，安装和升级。
Helm Chart 易于创建、发版、分享和发布，所以停止复制粘贴，开始使用 Helm 吧。
Helm 是 CNCF 的毕业项目，由 Helm 社区维护。

优势：
* 复杂性管理  
即使是最复杂的应用，Helm Chart 依然可以描述， 提供使用单点授权的可重复安装应用程序。
* 易于升级  
随时随地升级和自定义的钩子消除您升级的痛苦。
* 分发简单  
Helm Chart 很容易在公共或私有化服务器上发版，分发和部署站点。
* 回滚  
使用 helm rollback 可以轻松回滚到之前的发布版本  

官方文档: [helm.sh](helm.sh)

## Helm操作

##### 1. helm构建chart包
```bash
helm create helmascode
```
##### 2. helm安装应用
```bash
helm install [NAME] [CHART] [flags]
```
##### 3. helm升级应用
```bash
helm upgrade [RELEASE] [CHART] [flags]
```
##### 4. helm回滚应用
```bash
helm rollback <RELEASE> [REVISION] [flags]
```
##### 5. helm列出版本历史
```bash
helm history RELEASE_NAME [flags]
```
##### 6. helm添加repo
```bash
helm repo add [NAME] [URL] [flags]
```
> 以上命令可通过--help快速获取帮助

## Helmfile介绍

helmfile以声明式方式部署您的 Kubernetes 清单、Kustomize 配置和chart来生成helm release。通常会在部署涉及多个chart以及repo，这些chart和repo管理同样有很大的问题，尤其是在保证可重复性以及版本化配置方面，而helmfile就是来解决这个痛点。  
优势：
* 独特的环境概念，可对具体环境应用不同的配置
* 支持diff以及sync操作，方便集成到CI/CD系统中
* 声明式管理helm资源，版本化配置以及部署可重复性
* 丰富的模板函数，满足各种需求
* 模块化配置

helmfile: [github.com/helmfile/helmfile](github.com/helmfile/helmfile)

## helmfile原理
helmfile本质上是通过yaml的配置方式来定义本身的行为，包括helm中的repositories、release以及chart相关信息，通过helmfile diff查看变更，确认后即可helmfile sync完成本次部署，同时在配置不变的情况，多次操作为幂等，这就是声明式配置的魅力。同时，helmfile依赖helm以及helm-diff插件，来完成整个流程:

配置:
```yaml
# 环境配置，每个key为一个环境，通过helmfile -e指定，不同环境通过values配置不同的值
environments:
  # The "default" environment is available and used when `helmfile` is run without `--environment NAME`.
  default:
    values:
    - environments/default/values.yaml 
# helm repo配置
repositories:
 - name: prometheus-community
   url: https://prometheus-community.github.io/helm-charts
# release 配置
releases:
- name: prom-norbac-ubuntu
  namespace: prometheus
  chart: prometheus-community/prometheus
  set:
  - name: rbac.create
    value: false
```
操作:
```bash
# 1. helmfile自动比较差异，有变更时自动更新
helmfile apply

# 2. 分步骤确认更新
helmfile -e default diff # 只比较差异，并前台打印
helmfile -e default sync
```
以上只是最简的配置，helmfile的更高级功能参考官方文档: [https://helmfile.readthedocs.io/en/latest/](https://helmfile.readthedocs.io/en/latest/)

本质上，helmfile通过模板语言来生成helm的release配置，同时进行应用，此外，helm的模板函数之外，helmfile还新增多个好用到爆的函数，具体参考: [https://helmfile.readthedocs.io/en/latest/#templating](https://helmfile.readthedocs.io/en/latest/#templating)
## Helm As Code
通过helm和helmfile介绍与学习，我们已经具备helm as code的必要条件，那helm as code应该如何玩？其实就三个关键词: helm + helmfile + gitlab.
* helm: chart制作、打包以及分发
* helmfile: 声明式管理helm资源，集成进CI/CD
* gitlab: 版本化管理helmfile配置以及CI/CD底座

通过helm的应用编排，封装应用的资源文件，同时通过chart的方式进行分发，借助helmfile的能力，声明管理helm的部署，具有高度可重复、声明式以及版本化特性，同时在gitlab的加持下，利用gitlab  CI/CD，helmfile可以方便集成为工作流，helmfile diff查看变更，helmfile sync进行应用变更，做到心中有数，万事不愁。

## 总结

随着基础设施即代码概念的流行，我相信这会改变运维整体格局，每个运维人都需要做变革，在技术洪流中保持先进。helm as code 应用即代码，希望这篇文章可以对大家有所启发，互相交流。

> 文章同步发布: aiopsclub.com

> helmfile: github.com/helmfile/helmfile  
helm: github.com/helm/helm  
gitlab: gitlab.cn  
