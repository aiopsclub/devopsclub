---
title : "kubernetes之pod拓扑分布约束"
weight : 4 
---
> 在日常使用 kubernetes 的过程中中，很多时候我们并没有过多的关心 pod 的到底调度在哪里，只是通过多副本的测试，来提高的我们的业务的可用性，但是当多个相同业务 pod 在分布在相同节点时，一旦节点意外宕机，将会严重影响我们的业务的可用性，鉴于此，kubernetes 中引入了新的 pod 调度策略-topologySpreadConstraints，翻译为拓扑分布约束，今天就让我们揭开其神秘面纱，原来 pod 还可以这么玩。

关键字：topologySpreadConstraints  pod拓扑分布约束 kubernetes
## pod 拓扑分布约束简介

拓扑分布约束（Topology Spread Constraints）可以控制 Pods 在集群内故障域 之间的分布，例如区域（Region）、可用区（Zone）、节点和其他用户自定义拓扑域。 这样做有助于实现高可用并提升资源利用率。  
此项功能在 1.18中将其提升为Beta，1.19 中为 stable 状态，可以在生产环境中使用。

## 节点的故障域标识

拓扑分布约束依赖于节点标签来标识每个节点所在的拓扑域。 例如，某节点可能具有标签：node=node1,zone=us-east-1a,region=us-east-1

假设你拥有具有以下标签的一个 4 节点集群：

```shell
NAME    STATUS   ROLES    AGE     VERSION   LABELS
node1   Ready    <none>   4m26s   v1.16.0   node=node1,zone=zoneA
node2   Ready    <none>   3m58s   v1.16.0   node=node2,zone=zoneA
node3   Ready    <none>   3m17s   v1.16.0   node=node3,zone=zoneB
node4   Ready    <none>   2m43s   v1.16.0   node=node4,zone=zoneB
```

在逻辑上看，我们的节点的结构图如下：
![微信截图_20210427214133](https://www.aiopsclub.com/images/kubernetes/1.png)

由上图可知，逻辑域有两个层次，一是 node 层面，二是 zone 层面，我们可以灵活配置自己的故障域，使我们的业务有更高的可用性。

## pod 拓扑分布约束实践

正如我们日常写 yaml 一样，配置 topologySpreadConstraints，同样只需要在 yaml 中定义即可，路径为: pod.spec.topologySpreadConstraints 
![api](https://www.aiopsclub.com/images/kubernetes/api.png)

示例:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  topologySpreadConstraints:
    - maxSkew: <integer>
      topologyKey: <string>
      whenUnsatisfiable: <string>
      labelSelector: <object>
```

你可以定义一个或多个 topologySpreadConstraint 来指示 kube-scheduler 如何根据与现有的 Pod 的关联关系将每个传入的 Pod 部署到集群中。  
字段包括：

- maxSkew 描述 Pod 分布不均的程度。  
  这是给定拓扑类型中任意两个拓扑域中 匹配的 pod 之间的最大允许差值。它必须大于零。取决于 whenUnsatisfiable 的 取值，其语义会有不同。

  - 当 whenUnsatisfiable 等于 "DoNotSchedule" 时，maxSkew 是目标拓扑域 中匹配的 Pod 数与全局最小值之间可存在的差异。
  - 当 whenUnsatisfiable 等于 "ScheduleAnyway" 时，调度器会更为偏向能够降低 偏差值的拓扑域。

- topologyKey 是节点标签的键。  
  如果两个节点使用此键标记并且具有相同的标签值， 则调度器会将这两个节点视为处于同一拓扑域中。调度器试图在每个拓扑域中放置数量 均衡的 Pod。
- whenUnsatisfiable 指示如果 Pod 不满足分布约束时如何处理：
  - DoNotSchedule（默认）告诉调度器不要调度。
  - ScheduleAnyway 告诉调度器仍然继续调度，只是根据如何能将偏差最小化来对 节点进行排序。
- labelSelector 用于查找匹配的 pod。
  匹配此标签的 Pod 将被统计，以确定相应 拓扑域中 Pod 的数量。 有关详细信息，请参考标签选择算符。

你可以执行 `kubectl explain Pod.spec.topologySpreadConstraints` 命令以了解关于 topologySpreadConstraints 的更多信息。

## 业务应用实践

1. 单个 TopologySpreadConstraint  
   假设你拥有一个 4 节点集群，其中标记为 foo:bar 的 3 个 Pod 分别位于 node1、node2 和 node3 中：  
   示意图:
   ![2](https://www.aiopsclub.com/images/kubernetes/2.png)

如果希望新来的 Pod 均匀分布在现有的可用区域，可进行如下配置：  
   
```yaml
##  示例1-yaml
kind: Pod
apiVersion: v1
metadata:
  name: mypod
  labels:
    foo: bar
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        foo: bar
  containers:
  - name: pause
    image: k8s.gcr.io/pause:3.1
```
* topologyKey: zone 意味着均匀分布将只应用于存在标签键值对为 "zone:<any value>" 的节点。 
* whenUnsatisfiable: DoNotSchedule 告诉调度器如果新的 Pod 不满足约束，则让它保持悬决状态
  
如果调度器将新的 Pod 放入 "zoneA"，Pods 分布将变为 [3, 1]，因此实际的偏差 为（3 - 1）= 2 。这违反了 maxSkew: 1 的约定。此示例中，新 Pod 只能放置在 "zoneB" 上：
![3](https://www.aiopsclub.com/images/kubernetes/3.png)

或者

![4](https://www.aiopsclub.com/images/kubernetes/4.png)
  
你可以调整 Pod 的配置以满足各种要求：  
* 将 maxSkew 更改为更大的值，比如 "2"，这样新的 Pod 也可以放在 "zoneA" 上。
* 将 topologyKey 更改为 "node"，以便将 Pod 均匀分布在节点上而不是区域中。 在上面的例子中，如果 maxSkew 保持为 "1"，那么传入的 Pod 只能放在 "node4" 上。
* 将 whenUnsatisfiable: DoNotSchedule 更改为 whenUnsatisfiable: ScheduleAnyway， 以确保新的 Pod 始终可以被调度（假设满足其他的调度 API）。 但是，最好将其放置在匹配 Pod 数量较少的拓扑域中。 （请注意，这一优先判定会与其他内部调度优先级（如资源使用率等）排序准则一起进行标准化。）

2. 多个 TopologySpreadConstraints  
下面的例子建立在前面例子的基础上。假设你拥有一个 4 节点集群，其中 3 个标记为 foo:bar 的 Pod 分别位于 node1、node2 和 node3 上：  
示意图:  
![5](https://www.aiopsclub.com/images/kubernetes/5.png)

可以使用 2 个 TopologySpreadConstraint 来控制 Pod 在 区域和节点两个维度上的分布：  
```yaml
## 示例2-yaml
kind: Pod
apiVersion: v1
metadata:
  name: mypod
  labels:
    foo: bar
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        foo: bar
  - maxSkew: 1
    topologyKey: node
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        foo: bar
  containers:
  - name: pause
    image: k8s.gcr.io/pause:3.1
```
在这种情况下，为了匹配第一个约束，新的 Pod 只能放置在 "zoneB" 中；而在第二个约束中， 新的 Pod 只能放置在 "node4" 上。最后两个约束的结果加在一起，唯一可行的选择是放置 在 "node4" 上。  

多个约束之间可能存在冲突。假设有一个跨越 2 个区域的 3 节点集群：
![6](https://www.aiopsclub.com/images/kubernetes/6.png)
如果对集群应用示例2-yaml配置，会发现 "mypod" 处于 Pending 状态。 这是因为：为了满足第一个约束，"mypod" 只能放在 "zoneB" 中，而第二个约束要求 "mypod" 只能放在 "node2" 上。Pod 调度无法满足两种约束。

为了克服这种情况，你可以增加 maxSkew 或修改其中一个约束，让其使用 whenUnsatisfiable: ScheduleAnyway

## 约定
* 只有与新的 Pod 具有相同命名空间的 Pod 才能作为匹配候选者。
* 没有 topologySpreadConstraints[*].topologyKey 的节点将被忽略。这意味着：  
  1. 位于这些节点上的 Pod 不影响 maxSkew 的计算。 在上面的例子中，假设 "node1" 没有标签 "zone"，那么 2 个 Pod 将被忽略， 因此传入的 Pod 将被调度到 "zoneA" 中。
  2.新的 Pod 没有机会被调度到这类节点上。 在上面的例子中，假设一个带有标签 {zone-typo: zoneC} 的 "node5" 加入到集群， 它将由于没有标签键 "zone" 而被忽略。
* 注意，如果新 Pod 的 topologySpreadConstraints[*].labelSelector 与自身的 标签不匹配，将会发生什么。 在上面的例子中，如果移除新 Pod 上的标签，Pod 仍然可以调度到 "zoneB"，因为约束仍然满足。 然而，在调度之后，集群的不平衡程度保持不变。zoneA 仍然有 2 个带有 {foo:bar} 标签的 Pod， zoneB 有 1 个带有 {foo:bar} 标签的 Pod。 因此，如果这不是你所期望的，建议工作负载的 topologySpreadConstraints[*].labelSelector 与其自身的标签匹配。
* 如果新 Pod 定义了 spec.nodeSelector 或 spec.affinity.nodeAffinity，则 不匹配的节点会被忽略。  
  
假设你有一个跨越 zoneA 到 zoneC 的 5 节点集群
![7](https://www.aiopsclub.com/images/kubernetes/7.png)
而且你知道 "zoneC" 必须被排除在外。在这种情况下，可以按如下方式编写 yaml， 以便将 "mypod" 放置在 "zoneB" 上，而不是 "zoneC" 上。同样，spec.nodeSelector 也要一样处理。
```yaml
kind: Pod
apiVersion: v1
metadata:
  name: mypod
  labels:
    foo: bar
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        foo: bar
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: zone
            operator: NotIn
            values:
            - zoneC
  containers:
  - name: pause
    image: k8s.gcr.io/pause:3.1
```

## 集群基本的Pod 拓扑分布约束
为集群设置默认的拓扑分布约束也是可能的。默认拓扑分布约束在且仅在以下条件满足 时才会应用到 Pod 上：  
* Pod 没有在其 .spec.topologySpreadConstraints 设置任何约束；
* Pod 隶属于某个服务、副本控制器、ReplicaSet 或 StatefulSet;

你可以在 调度方案（Schedulingg Profile） 中将默认约束作为 PodTopologySpread 插件参数的一部分来设置。 约束的设置采用如前所述的 API，只是 labelSelector 必须为空。 选择算符是根据 Pod 所属的服务、副本控制器、ReplicaSet 或 StatefulSet 来设置的。  
示例配置：  
```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration

profiles:
  - pluginConfig:
      - name: PodTopologySpread
        args:
          defaultConstraints:
            - maxSkew: 1
              topologyKey: topology.kubernetes.io/zone
              whenUnsatisfiable: ScheduleAnyway
          defaultingType: List
```

## 与 PodAffinity/PodAntiAffinity 相比较
在 Kubernetes 中，与“亲和性”相关的指令控制 Pod 的调度方式（更密集或更分散）。

* 对于 PodAffinity，你可以尝试将任意数量的 Pod 集中到符合条件的拓扑域中。
* 对于 PodAntiAffinity，只能将一个 Pod 调度到某个拓扑域中。

要实现更细粒度的控制，你可以设置拓扑分布约束来将 Pod 分布到不同的拓扑域下， 从而实现高可用性或节省成本。这也有助于工作负载的滚动更新和平稳地扩展副本规模。  

## 高阶用法
1. `结合NodeSelector/NodeAffinity一起使用`  
  
在pod的拓扑分布约束配置中，可以看到我们只有topologyKey的配置选项，并没有任何关于topologyValues的配置字段，也就是并没有规定pod具体安排在哪些拓扑域，默认情况下，它将搜索所有节点并按"topologyKey"对它们进行分组。有时这可能不是我们想要的结果。例如，假设有一个集群，其节点分别用"env = prod"，"env = staging"和"env = qa"标记，现在您想将Pod均匀地跨区域放置到"qa"环境中，能办到么?  
 
答案是肯定的。您可以利用NodeSelector或NodeAffinity API规范。在幕后，PodTopologySpread功能将兑现这一点，并计算满足选择器的节点之间的传播约束。
示意图:  
![advanced-usage-1](https://www.aiopsclub.com/images/kubernetes/advanced-usage-1.png)

如上所示，您可以指定spec.affinity.nodeAffinity将搜索范围限制为qa环境，并且在该范围内，会将Pod调度到一个满足topologySpreadConstraints的区域。在这种情况下，它是"zone2"。  

2. `高阶多拓扑分布约束`  

了解一个TopologySpreadConstraint的工作原理很直观。多个TopologySpreadConstraints是什么情况？在内部，每个TopologySpreadConstraint都是独立计算的，结果集将合并以生成最终的结果集-即合适的节点。 
  
在以下示例中，我们希望同时将Pod调度到具有2个需求的集群中：
* Pod跨区域均匀放置
* Pod跨节点均匀放置  

示意图:
![advanced-usage-2](https://www.aiopsclub.com/images/kubernetes/advanced-usage-2.png)

对于第一个约束，zone1中有3个Pod，zone2中有2个Pod，因此只能将传入的Pod放入zone2中，以满足"maxSkew = 1"约束。换句话说，结果集是nodeX和nodeY。

对于第二个约束，nodeB和nodeX中的Pod过多，因此只能将传入的Pod放入nodeA和nodeY。

现在我们可以得出结论，唯一合格的节点是nodeY-从集合{nodeX，nodeY}（来自第一个约束）和{nodeA，nodeY}（来自第二个约束）的交集中得出。

多个TopologySpreadConstraints功能强大，但是一定要了解与前面的"NodeSelector/NodeAffinity"示例的区别：一个是独立计算结果集，然后将其互连；另一种是根据节点约束的过滤结果来计算topologySpreadConstraints。

`注意`：如果将两个TopologySpreadConstraints应用于同一{topologyKey，whenUnsatisfiable}元组，则Pod的创建将被阻止，并返回验证错误。


