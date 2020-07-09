+++
title = "全局对象request解析"
weight = 3 
+++

# `flask`全局对象之`request`

由源代码布局可知，`globals.py`保存`flask`的全局对象，包括  
1. `current_app`  
2. `request`  
3. `g`   

我们首先来讲讲`request`对象:  
源码：

```python
from functools import partial
from werkzeug.local import LocalProxy
from werkzeug.local import LocalStack

def _lookup_req_object(name):
    top = _request_ctx_stack.top
    if top is None:
        raise RuntimeError(_request_ctx_err_msg)
    return getattr(top, name)

_request_ctx_stack = LocalStack()
request = LocalProxy(partial(_lookup_req_object, "request"))
```

由代码可知，request的实现主要依赖于`LocalProxy`和`LocalStack`，简单说一说`LocalProxy`和`LocalStack`：
* `LocalProxy`：werkzeug实现的一种代理对象，可知实现被代理对象的动态更新。
* `LocalStack`：LocalStack是werkzeug库实现的栈，对象压入的规则简单总结为先入后出，并且可以方便的访问栈顶对象以及各种常用操作，比如push、pop等。

werkzeug实现的具体细节，感兴趣的同学可以翻看源码，后续我们也会一起来看。  

接下来，看一下request的对象的具体的工作原理和生命周期：
* 生命周期：`request`的对象的进栈和出栈的逻辑都在`Flask`类的wsgi_app方法中进行的，我们来看一下：

```python
class Flask(_PackageBoundObject):

    def request_context(self, environ):

        return RequestContext(self, environ)


    def wsgi_app(self, environ, start_response):

        ctx = self.request_context(environ)
        error = None
        try:
            try:
                ctx.push()
                response = self.full_dispatch_request()
            except Exception as e:
                error = e
                response = self.handle_exception(e)
            except:  # noqa: B001
                error = sys.exc_info()[1]
                raise
            return response(environ, start_response)
        finally:
            if self.should_ignore_error(error):
                error = None
            ctx.auto_pop(error)
```
由代码可知，当http请求到达时，flask先通过environ参数构造`RequestContext`对象`ctx`，然后调用`ctx.push()`，在请求处理完毕后调用`ctx.auto_pop(error)`，整个请求流程就结束了，request的进栈和出栈也同时完成。

接下来看看`RequestContext`的`push`方法，到底做了什么操作：
```python
class RequestContext(object):

    def __init__(self, app, environ, request=None, session=None):
        self.app = app
        if request is None:
            request = app.request_class(environ)
        self.request = request
        self.url_adapter = None
        try:
            self.url_adapter = app.create_url_adapter(self.request)
        except HTTPException as e:
            self.request.routing_exception = e
        self.flashes = None
        self.session = session

        self._implicit_app_ctx_stack = []

        self.preserved = False

        self._preserved_exc = None

        self._after_request_functions = []

    def push(self):

        top = _request_ctx_stack.top
        if top is not None and top.preserved:
            top.pop(top._preserved_exc)

        app_ctx = _app_ctx_stack.top
        if app_ctx is None or app_ctx.app != self.app:
            app_ctx = self.app.app_context()
            app_ctx.push()
            self._implicit_app_ctx_stack.append(app_ctx)
        else:
            self._implicit_app_ctx_stack.append(None)

        if hasattr(sys, "exc_clear"):
            sys.exc_clear()

        _request_ctx_stack.push(self)

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
由`push`方法可知，此时不仅进行`reqeuest`的入栈操作，同时进行`app`对象的入栈操作，这样我导入`from flask import request`，就可以保障`_request_ctx_stack`的栈顶是当前请求信息构造的request对象，方便我们对请求信息的读取，并在处理完毕后，进行`pop`操作，清理`_request_ctx_stack`，等待下次请求的到达。  


* 工作原理  

```python
request = LocalProxy(partial(_lookup_req_object, "request"))  
```

由全局变量的逻辑可知，`request`本质是`RequestContext`实例的`request`属性，而`RequestContext`实例的`request`属性是`Flask`类的`request_class`属性，即`Request`类，综合而看`request`就是`Request`类实例化对象。而Request有多个父类，包含以下种类：  
* JSONMinxin  
* AcceptMixin
* ETagRequestMixin
* UserAgentMixin
* AuthorizationMixin
* CORSRequestMixin
* CommonRequestDescriptorsMixin

这样`request`实例就被赋予多种属性与方法，方便在调用时访问当前http请求的各种信息。
