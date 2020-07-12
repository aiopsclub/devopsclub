---
title : "全局对象current_app解析"
weight : 5 
---

# `flask`全局对象之`current_app`

`current_app`，这算得上flask中最容易理解的全局对象了。由名字可知，`current_app`为当前的app对象，我们可以通过`current_app`来获取当前flask的配置等信息，也可以动态修改当前flask的属性等等。  
贴源码：  
```python
from werkzeug.local import LocalProxy
from werkzeug.local import LocalStack
def _find_app():
    top = _app_ctx_stack.top
    if top is None:
        raise RuntimeError(_app_ctx_err_msg)
    return top.app

_app_ctx_stack = LocalStack()
current_app = LocalProxy(_find_app)
```
由`_find_app`函数可知，`current_app`始终是`_app_ctx_stack`的栈顶元素，也就是指向当前的Flask类的实例。 
