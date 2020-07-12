---
title : "ansible系列之filter插件开发"
weight : 1
---
> ansible是流行的自动化运维工具，他不仅仅有丰富且强大的功能，同时还支持灵活的扩展。我们可以自定义module和plugin来支持我们业务系统个性化的需求。只有想不到，没有做不到。今天我们先来学习一下filter插件是如何开发的。

## filter插件官方示例

```python
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import datetime


def to_datetime(string, format="%Y-%m-%d %H:%M:%S"):
    return datetime.datetime.strptime(string, format)


class FilterModule(object):
    ''' Ansible core jinja2 filters '''

    def filters(self):
        return {
            'to_datetime': to_datetime,
        }
```

以上代码是`lib/ansible/plugins/filter/core.py`简化版，去除其他filter函数，分析一下to_datetime函数，该函数好理解，同时又是多参数，函数的作用是将日期格式的字符串转为datetime类型，在使用时需要注意format参数，需要和日期格式的字符串的格式对应，默认值为`%Y-%m-%d %H:%M:%S`。

## filter插件使用方法

接下来看一下在ansible-playbook中的具体用法：

```yaml
---
- name: filter examples
  hosts: test
  vars:
  gather_facts: false
  tasks:
    - name: datetime filter example
      debug:
        # 我们将时间字符串转为datetime对象后又重新字符串化并只获取年月日相关信息
        msg: "{{ ('20200606 06:06:06' | to_datetime('%Y%m%d %H:%M:%S')).strftime('%Y-%m-%d') }}" 
```



## filter插件用法解析

在ansible-playbook中，filter用法为`{{ 第一个参数 | filter插件函数 }}`。
具体分析有一下两种情况：

1. filter插件函数只有一个参数，用法为`{{ 第一个参数 | filter插件函数 }}`即可；
2. filter插件函数有一个以上函数，用法为`{{ 第一个参数 | filter插件函数(除第一个参数外的其他参数) }}`，如果除第一个参数外，都有默认值，那也可以简写成`{{ 第一个参数 | filter插件函数 }}`。

## filter插件代码结构

```python
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type


# 具体的filter函数，可以有很多
def filter_example(a):
    """
    代码具体的逻辑
    """
    return a


# 创建FilterModule类，ansible框架要求
class FilterModule(object):
    # 创建filters方法，ansible框架要求
    def filters(self):
        # 返回插件字典，key为filter名称，value为filter的具体实现，可以是任意多个；
        return {
            
            'filter_example': filter_example,
        }
```

可以看到，ansible的filter插件是有着固定的结构的，我们在实际开发中，可以按照此结构实现自己的逻辑并将该文件放在正确的位置即可，ansible会帮我们自动加载，这样我们就可以在ansible的playbook中灵活使用。

## filter插件存放位置

1. 要想ansible自动加载本地filter插件，必须在下面位置创建或添加插件：

- ANSIBLE_FILTER_PLUGINS环境变量中的任何目录，ANSIBLE_FILTER_PLUGINS是以冒号分隔的列表。

- ~/.ansible/plugins/filter

- /usr/share/ansible/plugins/filter

​      插件文件位于以上任意位置后，Ansible将会自动加载插件，同时可以在本地任何module，task，playbook或role中使用它。 或者你也可以再在ansible.cfg配置相关目录，配置项为filter_plugins，格式与ANSIBLE_FILTER_PLUGINS环境变量一致。

2. 要在playbook中保存filter插件，可通过下面的方式：

​      将插件文件放在playbook下filter_plugins目录下即可。

3. 要仅在单个role中使用filter插件：

​       将插件文件放在role下filter_plugins目录下即可。

4. 要确认plugins/filter/my_custom_plugin可用：

- 输入`ansible-doc -t filter my_custom_filter_plugin`，这将会展示对应filter插件的文档，这对所有的插件类型都有效。

## 总结

总体来看，filter的开发还是很简单的，只要把握正确的结构，放到正确的位置即可。相信同学们已经学会了，那就赶快在自己的业务中定制自己的filter插件吧！
