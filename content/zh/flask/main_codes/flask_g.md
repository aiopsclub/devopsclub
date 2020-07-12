---
title : "全局对象g解析"
weight : 4 
---

# `flask`全局对象之`g`

接下来我们来看看`flask`的g对象，`g`对象也来自与`globals.py`文件，现贴出`g`对象的产生逻辑的源码：

```python

from functools import partial

from werkzeug.local import LocalProxy
from werkzeug.local import LocalStack

def _lookup_app_object(name):
    top = _app_ctx_stack.top
    if top is None:
        raise RuntimeError(_app_ctx_err_msg)
    return getattr(top, name)

_app_ctx_stack = LocalStack()
g = LocalProxy(partial(_lookup_app_object, "g"))
```

由以上逻辑可知，`g`来自`_app_ctx_stack`，且为`_app_ctx_stack`栈顶元素的g属性，接下来看看`_app_ctx_stack`栈对象的入栈和出栈操作的逻辑和时机，就可以知道`g`对象的生命周期和工作原理。  

通过查阅`Flask`类的实现，可知`_app_ctx_stack`的出入栈和`_request_ctx_stack`的出入栈时机基本一致，贴出代码可知：
```python
class RequestContext(object):

    def push(self):
        top = _request_ctx_stack.top
        if top is not None and top.preserved:
            top.pop(top._preserved_exc)

        app_ctx = _app_ctx_stack.top
        if app_ctx is None or app_ctx.app != self.app:
            # app上下文的实例化以及入栈
            app_ctx = self.app.app_context()
            app_ctx.push()

            self._implicit_app_ctx_stack.append(app_ctx)
        else:
            self._implicit_app_ctx_stack.append(None)

        if hasattr(sys, "exc_clear"):
            sys.exc_clear()

        _request_ctx_stack.push(self)

        if self.session is None:
            session_interface = self.app.session_interface
            self.session = session_interface.open_session(self.app, self.request)

            if self.session is None:
                self.session = session_interface.make_null_session(self.app)

        if self.url_adapter is not None:
            self.match_request()


    def pop(self, exc=_sentinel):

        app_ctx = self._implicit_app_ctx_stack.pop()

        try:
            clear_request = False
            if not self._implicit_app_ctx_stack:
                self.preserved = False
                self._preserved_exc = None
                if exc is _sentinel:
                    exc = sys.exc_info()[1]
                self.app.do_teardown_request(exc)

                if hasattr(sys, "exc_clear"):
                    sys.exc_clear()

                request_close = getattr(self.request, "close", None)
                if request_close is not None:
                    request_close()
                clear_request = True
        finally:
            rv = _request_ctx_stack.pop()

            if clear_request:
                rv.request.environ["werkzeug.request"] = None

            if app_ctx is not None:
                # app上下文的出栈
                app_ctx.pop(exc)

            assert rv is self, "Popped wrong request context. (%r instead of %r)" % (
                rv,
                self,
            )

    def auto_pop(self, exc):
        if self.request.environ.get("flask._preserve_context") or (
            exc is not None and self.app.preserve_context_on_exception
        ):
            self.preserved = True
            self._preserved_exc = exc
        else:
            self.pop(exc)

```
`app`上下文的进出栈已在代码中标注，可以清晰看到整个逻辑，由代码`self.app.app_context()`可知，`self.app`其实就是Flask类实例化对象的`app_context`所返回的`AppContext`类的实例化对象，而`AppContext`类来自于`ctx.py`，我们看一下`AppContext`类的构造函数：  

```python
class AppContext(object):

    def __init__(self, app):
        self.app = app
        self.url_adapter = app.create_url_adapter(None)
        # 哈哈 终于找到g对象
        self.g = app.app_ctx_globals_class()

        self._refcnt = 0
```

由代码可知，`self.g`来自于`Flask`类的`app_ctx_globals_class`属性所指向的`_AppCtxGlobals`类，看一下`_AppCtxGlobals`的源码：  

```python
class _AppCtxGlobals(object):

    def get(self, name, default=None):

        return self.__dict__.get(name, default)

    def pop(self, name, default=_sentinel):
        if default is _sentinel:
            return self.__dict__.pop(name)
        else:
            return self.__dict__.pop(name, default)

    def setdefault(self, name, default=None):
        return self.__dict__.setdefault(name, default)

    def __contains__(self, item):
        return item in self.__dict__

    def __iter__(self):
        return iter(self.__dict__)
```
至此，终于揭开g的真正面纱，本质上就是一个简单新式类，可以对其的实例化对象进行赋值、取值、迭代以及in操作。  

由以上分析可知，g对象的生命周期和request对象一致，都是针对当前的请求，不同的是request提供http请求信息的封装，而g对象可以进行临时数据的存放，并在本次请求可以多次取值与赋值。  
