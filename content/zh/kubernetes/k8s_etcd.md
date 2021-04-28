---
title : "kubernetes存储大脑之etcd"
weight : 3 
---

> kubernetes存储大脑之etcd
## etcd简介
etcd 是兼具一致性和高可用性的键值数据库，可用于服务发现以及配置中心。ETCD采用raft一致性算法，基于 Go 语言实现。可以作为保存 Kubernetes 所有集群数据的后台数据库，在整个云原生中发挥极其重要的作用。  
ectd版本: v3.4
etcd文档地址: https://etcd.io/docs/v3.4/

## etcd特点
1. 扁平化二进制键值空间  
2. 保留事件历史记录，直到压缩为止  
   * 访问旧版本keys
   * 用户自定义key版本历史压缩
3. 支持范围查询 
   * 带limit参数的分页支持
   * 支持多个范围查询的一致性保证
4. 通过租约替换TTL键
   * 更高效以及低成本的keepalive
   * 为不同的TTL key配置配置相同逻辑的租约
5. 通过多对象Txn替换CAS/CAD
   * 更加强大和灵活   
6. 支持多范围高效watch  
7. RPC API支持完整的API集
    * 比JSON/HTTP更有效
    * 额外的TXN/租约支持
8. HTTP API支持API子集。
    * 用户更容易尝试etcd
    * 用户更易于编写简单的etcd应用程序
## etcd运行建议
* 运行的 etcd 集群个数成员为奇数。
* etcd 是一个 leader-based 分布式系统。确保主节点定期向所有从节点发送心跳，以保持集群稳定。
* 确保资源充足。  
集群的性能和稳定性对网络和磁盘 IO 非常敏感。任何资源匮乏都会导致心跳超时，从而导致集群的不稳定。不稳定的情况表明没有选出任何主节点。在这种情况下，集群不能对其当前状态进行任何更改，这意味着不能调度新的 pod。
* 保持稳定的 etcd 集群对 Kubernetes 集群的稳定性至关重要。因此，请在专用机器或隔离环境上运行 etcd 集群，以满足所需资源需求。
* 在生产中运行的 etcd 的最低推荐版本是 3.2.10+
* 硬件建议：https://etcd.io/docs/v3.4/op-guide/hardware/
## etcd架构实践
为了性能和高可用性，在生产中将以多节点集群的方式运行 etcd，并且定期备份。建议在生产中使用五个成员的集群。有关该内容的更多信息，请参阅[容错文档](https://etcd.io/docs/v3.4/faq/#what-is-failure-tolerance)。  
可以通过静态成员信息或动态发现的方式配置 etcd 集群。有关集群的详细信息，请参阅[etcd 集群文档](https://etcd.io/docs/v3.4/op-guide/clustering/)。
## etcd调优指南
本次调优针对于etcd本身的参数调优:
1. 时间相关参数  
在大型etcd集群中，由于网络的复杂性，etcd本身的分布式共识协议将受到影响，其主要依赖于两个时间参数：  
第一个参数称为Heartbeat Interval。领导者将以此频率通知关注者它仍然是领导者。为了获得最佳实践，应围绕成员之间的往返时间设置参数。默认情况下，etcd使用100ms心跳间隔。  
第二个参数是Election Timeout。此超时时间是指跟随者节点在尝试成为领导者之前要等待多长时间而不会听到心跳信号。默认情况下，etcd使用1000ms选举超时。  
调整这些值是一个权衡。建议心跳间隔的值应介于成员之间的平均往返时间（RTT）的最大值附近，通常约为往返时间的0.5-1.5倍。如果心跳间隔太短，etcd将发送不必要的消息，从而增加CPU和网络资源的使用。另一方面，过高的心跳间隔会导致较高的选举超时时间。较高的选举超时时间需要更长的时间才能检测到领导者失败。测量往返时间（RTT）的最简单方法是使用PING实用程序。  
应该根据心跳间隔和成员之间的平均往返时间来设置选举超时。选举超时时间必须至少是往返时间的10倍，这样才能解决网络中的差异。例如，如果成员之间的往返时间为10毫秒，则选举超时应至少为100毫秒。  
选举超时上限为50000ms（50s），仅在部署全球分布的etcd集群时才应使用。  
一个集群中所有成员的心跳间隔和选举超时值应相同。为etcd成员设置不同的值可能会破坏集群的稳定性。  
以上参数可以通过命令进行调整：  
```shell
# Command line arguments:
$ etcd --heartbeat-interval=100 --election-timeout=500

# Environment variables:
$ ETCD_HEARTBEAT_INTERVAL=100 ETCD_ELECTION_TIMEOUT=500 etcd
```
2. 快照  
etcd将所有关键更改附加到日志文件。此日志将永远增长，并且是对键所做的每次更改的完整线性历史记录。完整的历史记录适用于轻度使用的集群，但是频繁使用的集群将携带大量日志。  
为了避免有大量日志，etcd会进行定期快照。这些快照为etcd提供了一种通过保存系统当前状态并删除旧日志来压缩日志的方法。    
使用V2后端创建快照可能会很昂贵，因此仅在对etcd进行给定数量的更改后才能创建快照。默认情况下，每10,000次更改后将创建快照。如果etcd的内存使用量和磁盘使用量过高，请尝试通过在命令行上设置以下内容来降低快照阈值：
```shell
# Command line arguments:
$ etcd --snapshot-count=5000

# Environment variables:
$ ETCD_SNAPSHOT_COUNT=5000 etcd
```
3. 磁盘  
etcd集群对磁盘延迟非常敏感。由于etcd必须将建议持久保存到其日志中，因此其他进程的磁盘活动可能会导致较长的fsync延迟。etcd可能会错过心跳，从而导致请求超时和临时领导者丢失。当给予较高的磁盘优先级时，etcd服务器有时可以与这些进程一起稳定运行。  
在Linux上，可以使用以下命令配置etcd的磁盘优先级ionice:
```shell
# best effort, highest priority
$ sudo ionice -c2 -n0 -p `pgrep etcd`
```
4. 网络
如果etcd领导者处理大量并发的客户端请求，由于网络拥塞，可能会延迟处理跟随者对等体请求。这表现为在跟随者节点上的发送缓冲区错误消息:
```shell
dropped MsgProp to 247ae21ff9436b2d since streamMsg's sending buffer is full
dropped MsgAppResp to 247ae21ff9436b2d since streamMsg's sending buffer is full
```
通过将etcd的对等流量优先于其客户端流量，可以解决这些错误。在Linux上，可以使用流量控制机制来确定对等流量的优先级：
```shell
tc qdisc add dev eth0 root handle 1: prio bands 3
tc filter add dev eth0 parent 1: protocol ip prio 1 u32 match ip sport 2380 0xffff flowid 1:1
tc filter add dev eth0 parent 1: protocol ip prio 1 u32 match ip dport 2380 0xffff flowid 1:1
tc filter add dev eth0 parent 1: protocol ip prio 2 u32 match ip sport 2379 0xffff flowid 1:1
tc filter add dev eth0 parent 1: protocol ip prio 2 u32 match ip dport 2379 0xffff flowid 1:1
```
5. 内存  
etcd默认的存储大小限制为2GB，可使用--quota-backend-bytes标志进行配置。建议在正常环境下使用8GB的最大大小，如果配置的值超过该值，etcd会在启动时发出警告。
6. 请求体    
etcd被设计用于元数据的小键值对的处理。较大的请求将工作的同时，可能会增加其他请求的延迟。默认情况下，任何请求的最大大小为1.5 MiB。这个限制可以通过--max-request-bytesetcd服务器的标志来配置。
7. key的历史记录压缩
ETCD 会存储多版本数据，随着写入的主键增加，历史版本将会越来越多，并且 ETCD 默认不会自动清理历史数据。数据达到 --quota-backend-bytes 设置的配额值时就无法写入数据，必须要压缩并清理历史数据才能继续写入。
```shell
--auto-compaction-mode
--auto-compaction-retention
```
所以，为了避免配额空间耗尽的问题，在创建集群时候建议默认开启历史版本清理 功能。  
3.3.0 之前的版本，只能按周期 periodic 来压缩。比如设置 --auto-compaction-retention=72h，那么就会每 72 小时进行一次数据压缩。  
3.3.0 之后的版本，可以通过 --auto-compaction-mode 设置压缩模式，可以选择 revision 或者 periodic 来压缩数据，默认为 periodic。  

## etcd备份
所有 Kubernetes 对象都存储在 etcd 上。定期备份 etcd 集群数据对于在灾难场景（例如丢失所有主节点）下恢复 Kubernetes 集群非常重要。快照文件包含所有 Kubernetes 状态和关键信息。为了保证敏感的 Kubernetes 数据的安全，可以对快照文件进行加密。
备份 etcd 集群可以通过两种方式完成: etcd 内置快照和卷快照。  
1. 内置快照  
etcd 支持内置快照，因此备份 etcd 集群很容易。快照可以从使用 etcdctl snapshot save 命令的活动成员中获取，也可以通过从 etcd 数据目录复制 member/snap/db 文件，该 etcd 数据目录目前没有被 etcd 进程使用。获取快照通常不会影响成员的性能。  
下面是一个示例，用于获取 $ENDPOINT 所提供的键空间的快照到文件 snapshotdb：
```shell
ETCDCTL_API=3 etcdctl --endpoints $ENDPOINT snapshot save snapshotdb
# exit 0

# verify the snapshot
ETCDCTL_API=3 etcdctl --write-out=table snapshot status snapshotdb
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| fe01cf57 |       10 |          7 | 2.1 MB     |
+----------+----------+------------+------------+
```
2. 卷快照  
如果 etcd 运行在支持备份的存储卷（如 Amazon Elastic Block 存储）上，则可以通过获取存储卷的快照来备份 etcd 数据。

## etcd恢复
etcd 支持从 major.minor 或其他不同 patch 版本的 etcd 进程中获取的快照进行恢复。还原操作用于恢复失败的集群的数据。  
在启动还原操作之前，必须有一个快照文件。它可以是来自以前备份操作的快照文件，也可以是来自剩余数据目录的快照文件。 有关从快照文件还原集群的详细信息和示例，请参阅 etcd 灾难恢复文档。  
如果还原的集群的访问URL与前一个集群不同，则必须相应地重新配置Kubernetes API 服务器。在本例中，使用参数 --etcd-servers=`$NEW_ETCD_CLUSTER` 而不是参数--etcd-servers=`$OLD_ETCD_CLUSTER` 重新启动 Kubernetes API 服务器。用相应的 IP 地址替换 `$NEW_ETCD_CLUSTER` 和 `$OLD_ETCD_CLUSTER`。如果在etcd集群前面使用负载平衡，则可能需要更新负载均衡器。   
如果大多数etcd成员永久失败，则认为etcd集群失败。在这种情况下，Kubernetes不能对其当前状态进行任何更改。虽然已调度的 pod 可能继续运行，但新的pod无法调度。在这种情况下，恢复etcd 集群并可能需要重新配置Kubernetes API服务器以修复问题。  
注意:  
如果集群中正在运行任何 API 服务器，则不应尝试还原 etcd 的实例。相反，请按照以下步骤还原 etcd：  
* 停止 所有 kube-apiserver 实例
* 在所有 etcd 实例中恢复状态
* 重启所有 kube-apiserver 实例  

我们还建议重启所有组件（例如 kube-scheduler、kube-controller-manager、kubelet），以确保它们不会 依赖一些过时的数据。请注意，实际中还原会花费一些时间。 在还原过程中，关键组件将丢失领导锁并自行重启。

## 总结  
etcd为kubernetes的存储基石，想用好k8s，必须熟悉etcd，我们才更有信心。以及更好的服务业务。提供更稳定的技术服务。

## 参考文档
* https://etcd.io/docs/
* https://kubernetes.io/zh/docs/tasks/administer-cluster/configure-upgrade-etcd/

