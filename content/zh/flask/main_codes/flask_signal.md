---
title : "flask特性之signal系统"
weight : 7 
---

# `flask`的信号系统
---
## 简介  
Flask从0.6版开始在内部支持信号，但该功能是可选的，其依赖于blinker库，也就是我们想要支持信号，就需要主动安装blinker库。

## 信号的含义
何为flask信号？可以想象一下，在现实生活中，处处都有信号的影子，比如地铁信号、航海信号等等，这些可以简单理解为某些事发生后，通知接收者。  
在flask中，同样存在很多信号，处在整个flask的处理的生命周期，在此记住，信号的使用目的是通知接受者，不应该鼓励接收者修改数据，这和flask中内建的装饰器有很多相似的地方。但是信号通知的接收者的执行是无序，并且不做任何数据修改，而装饰器则是以一定的顺序执行的，且可以在其中实现自己的逻辑。 信号的最大优势就是可以快速的安全的订阅，但同时要保证订阅者不触发异常，以免影响整个faflask程序的运行。  

## 信号的具体实现  
所有信号的定义都在signals.py中，我们看看来如何实现的：  

```python

try:
    # 依赖blinker库
    from blinker import Namespace

    signals_available = True
except ImportError:
    signals_available = False

    class Namespace(object):
        def signal(self, name, doc=None):
            return _FakeSignal(name, doc)

    class _FakeSignal(object):

        def __init__(self, name, doc=None):
            self.name = name
            self.__doc__ = doc

        def send(self, *args, **kwargs):
            pass

        def _fail(self, *args, **kwargs):
            raise RuntimeError(
                "Signalling support is unavailable because the blinker"
                " library is not installed."
            
                    )

        connect = connect_via = connected_to = temporarily_connected_to = _fail
        disconnect = _fail
        has_receivers_for = receivers_for = _fail
        del _fail

_signals = Namespace()

# 核心信号的定义
template_rendered = _signals.signal("template-rendered")
before_render_template = _signals.signal("before-render-template")
request_started = _signals.signal("request-started")
request_finished = _signals.signal("request-finished")
request_tearing_down = _signals.signal("request-tearing-down")
got_request_exception = _signals.signal("got-request-exception")
appcontext_tearing_down = _signals.signal("appcontext-tearing-down")
appcontext_pushed = _signals.signal("appcontext-pushed")
appcontext_popped = _signals.signal("appcontext-popped")
message_flashed = _signals.signal("message-flashed")
```  

从源码看到flask的信号主要依赖blinker库，导入blinker库的Namespace的时候，可以发现这里有个小技巧，通过捕获ImportError异常和自定义Namespace类，来解除对blinker库的强依赖，这样就把信号的使用的主动权放到用户端，很灵活。
信号的定义也很简单，`_signals`是Namespace类的实例化对象，调用`_signals`的signal方法即可生产信号，并在需要发出信号时，调用send方法即可，接下来看一下flask的具体的信号发送的例子：

以`template_rendered`为例：
```python
def _render(template, context, app):

    before_render_template.send(app, template=template, context=context)
    rv = template.render(context)
    # template_rendered信号的发送逻辑
    template_rendered.send(app, template=template, context=context)
    return rv
```
flask的信号系统通过blinker库的使用，整体非常简单和灵活，同样，在订阅信号时，也非常简单，实例如下：

```python
# 1. connect()方法
from flask import template_rendered
import logging


def log_template_renders(sender, template, context, **extra):
    logging.getLogger("werkzeug").debug('Rendering template "%s" with context %s',
                        template.name or 'string template',
                        context)

template_rendered.connect(log_template_renders, app)

#2. 基于信号订阅的装饰器
在Blinker 1.1中通过使用新的connect_via()装饰器你也能够轻易地订阅信号:
from flask import template_rendered, current_app
@template_rendered.connect_via(current_app._get_current_object())
def when_template_rendered(sender, template, context, **extra):
    print 'Template %s is rendered with %s' % (template.name, context)
```

## 自定义信号 
```python
from flask.signals import Namespace
_custom_signals = Namespace()
example_signal = _custom_signals.signal("example_signal")
```
自定义信号的发布和订阅与falsk的核心信号一致。


至此，flask的信号系统基本介绍完毕。  

参考资料：
* [flask signal](https://flask.palletsprojects.com/en/1.1.x/signals/) 
