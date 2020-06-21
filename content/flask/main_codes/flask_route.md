+++
title = "路由系统 为何如此简洁高效"
weight = 2 
+++

# `flask`路由系统
先来看一下falsk是如何定义路由：
```python
from flask import Flask, escape, request

app = Flask(__name__)

@app.route('/')
def hello():
    name = request.args.get("name", "World")
    return f'Hello, {escape(name)}!'
```

通过代码可知，app.route是定义路由的装饰器，其源码实现为：

```python
class Flask(_PackageBoundObject):

    @setupmethod
    def add_url_rule(self, rule, endpoint=None, view_func=None, provide_automatic_options=None, **options):
        """
        删除枝叶代码，保留主干
        """
        if endpoint is None:
            endpoint = _endpoint_from_view_func(view_func)

        options["endpoint"] = endpoint
        methods = options.pop("methods", None)

        if methods is None:
            methods = getattr(view_func, "methods", None) or ("GET",)

        methods = set(item.upper() for item in methods)

        required_methods = set(getattr(view_func, "required_methods", ()))

        methods |= required_methods

        rule = self.url_rule_class(rule, methods=methods, **options)
        rule.provide_automatic_options = provide_automatic_options

        self.url_map.add(rule)
        if view_func is not None:
            old_func = self.view_functions.get(endpoint)
            if old_func is not None and old_func != view_func:
                raise AssertionError(
                    "View function mapping is overwriting an "
                    "existing endpoint function: %s" % endpoint
                )
            self.view_functions[endpoint] = view_func


    def route(self, rule, **options):

        def decorator(f):
            endpoint = options.pop("endpoint", None)
            self.add_url_rule(rule, endpoint, f, **options)
            return f

        return decorator
```
由代码可知，`route`函数其实调用`add_url_rule`函数。基本参数为：`rule methods enpoint`等；  
`add_url_rule`的作用主要构造路由相关逻辑，包含`werkzeug`的`routing`模块的`Map`类和`Rule`类。  
`url_map`就是`Map`类的实例化对象，`rule`是`Rule`的实例化对象，实例化的同时将rule和endpint的关系绑定，同时将`rule`对象传递给`self.url_map`的add函数，同时更新`view_functions`字典，将`enpoint`和`view_func`的对应关系更新进去。  

`rule[本质是url]`和`view_func`的对应关系由`endpoint`进行匹配的，此时endpoint如果用户未定义的话，默认是`view_func`的`__name__`属性，即`view_func`的名称； 

简单的两个函数，就把整个路由逻辑处理的很完美，这又体现出flask微框架的简单高效。  

到此，路由相关的处理逻辑就结束了；  
