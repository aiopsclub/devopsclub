---
title : "kubernetes addons之node-problem-detector"
weight : 1 
---

> 
## node-problem-detector简介
`node-problem-detector`的作用是收集k8s集群管理中节点问题，并将其报告给apiserver。它是在每个节点上运行的守护程序。node-problem-detector可以作为DaemonSet运行，也可以独立运行。 当前，GCE集群中默认开启此扩展。  
项目地址:  <https://github.com/kubernetes/node-problem-detector>

## kubernetes目前问题
* 基础架构守护程序问题：ntp服务关闭；
* 硬件问题：CPU，内存或磁盘损坏；
* 内核问题：内核死锁，文件系统损坏；
* 容器运行时问题：运行时守护程序无响应
* ...  
当kubernetes中节点发生上述问题，在整个集群中，k8s服务组件并不会感知以上问题，就会导致pod仍会调度至问题节点。  

为了解决这个问题，我们引入了这个新的守护进程`node-problem-detector`，从各个守护进程收集节点问题，并使它们对上游层可见。一旦上游层面发现了这些问题，我们就可以讨论补救措施。

## `node-problem-detector`的问题检测类型

当前支持的问题检测类型：
* SystemLogMonitor
* SystemStatsMonitor
* CustomPluginMonitor
* HealthChecker  
不同的检测类型通过不同的goroutine来实现，配置例子参考: https://github.com/kubernetes/node-problem-detector/tree/master/config, 配置文件为json结尾。

## 检测问题上报api
`node-problem-detector`使用Event和NodeCondition将问题报告给apiserver。  
* NodeCondition：导致节点无法处理于Pod生命周期的的永久性问题应报告为NodeCondition。  
* Event：对pod影响有限的临时问题应作为event报告。

## 支持的选项
--version：显示当前版本。  
--hostname-override：用于node-problem-detector的自定义节点名称，用于更新condition并发出event。 node-problem-detector首先从hostname-override获取节点名称，然后从NODE_NAME环境变量获取节点名称，最后从os.Hostname返回。

* 对于系统日志监控器  
--config.system-log-monitor：系统日志监控器配置文件的路径列表，以逗号分隔，例如 config/kernel-monitor.json。node-problem-detector将为每个配置启动一个单独的日志监视器。 您可以使用不同的日志监视器来监视不同的系统日志。  

* 对于系统状态监控器  
--config.system-stats-monitor：系统状态监视配置文件的路径列表，以逗号分隔，例如 config / system-stats-monitor.json。 node-problem-detector将为每个配置启动一个单独的系统状态监视器。 您可以使用不同的系统状态监视器来监视与问题相关的不同系统状态。  

* 对于自定义插件监视器    
--config.custom-plugin-monitor：自定义插件监视器配置文件的路径列表，以逗号分隔，例如 config/custom-plugin-monitor.json。 node-problem-detector将为每个配置启动一个单独的自定义插件监视器。 您可以使用不同的自定义插件监视器来监视不同的节点问题。

* Kubernetes exporter   
--enable-k8s-exporter：启用向Kubernetes API服务器报告的功能，默认为true。  
--apiserver-override：一个URI参数，用于自定义node-problem-detector连接apiserver的地址。 如果--enable-k8s-exporter为false，则忽略此内容。 格式与Heapster的源标志相同。 例如，要在没有身份验证的情况下运行，请使用以下配置：
http://APISERVER_IP:APISERVER_PORT?inClusterConfig=false  
请参阅heapster文档以获取可用选项的完整列表。  
--address：绑定node-problem-detector服务器的地址。  
--port：绑定node-problem-detector服务器的端口。 使用0禁用。

* Prometheus exporter  
--prometheus-address：绑定Prometheus抓取端点的地址，默认为127.0.0.1。  
--prometheus-port：绑定Prometheus抓取端点的端口，默认为20257。使用0禁用。    

* Stackdriver exporter

--exporter.stackdriver：Stackdriver exporter程序配置文件的路径，例如 config/exporter/stackdriver-exporter.json，默认为空字符串。 设置为空字符串以禁用。

访问个人网站，获取更多内容: <https://www.aiopsclub.com/>

![](https://imgkr2.cn-bj.ufileos.com/22150615-0391-463a-8a2c-522467b1d774.jpg?UCloudPublicKey=TOKEN_8d8b72be-579a-4e83-bfd0-5f6ce1546f13&Signature=cajklDM9OAoRTndADXxJbaJh9dk%253D&Expires=1614344329)

