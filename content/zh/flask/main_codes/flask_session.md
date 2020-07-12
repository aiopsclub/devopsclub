---
title : "全局对象session解析"
weight : 6 
---

# `flask`全局对象之`session`

接下来我们来看看`flask`的session对象，`session`对象也来自与`globals.py`文件，现贴出`session`对象的产生逻辑的源码：
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

session = LocalProxy(partial(_lookup_req_object, "session"))
```

由`LocalProxy(partial(_lookup_req_object, "session"))`可知，`session`来自request上下文的session属性，接下来看一下`session`的具体处理逻辑和生命周期：  

```python
class Flask(_PackageBoundObject):
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
我们回忆下`reqeust`上下文的实例化逻辑，来找寻`session`的踪迹：  

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

        # session具体处理过程
        if self.session is None:
            session_interface = self.app.session_interface
            self.session = session_interface.open_session(self.app, self.request)

            if self.session is None:
                self.session = session_interface.make_null_session(self.app)

        if self.url_adapter is not None:
            self.match_request()
```
由代码可知`RequestContext`实例化时，对session进行初始化，默认为None，而后在push方法中，针对不同的session值，进行不同的处理。接下来具体的分析一下：  
如果session为None时，将其值赋为`session_interface.open_session`的返回值，`session_interface`为`self.app.session_interface`， 即Flask类的`session_interface`，默认为`flask.sessions.SecureCookieSessionInterface`的实例化对象，那`flask.sessions.SecureCookieSessionInterface`的实现原理如何，我们从源码中发现秘密：  
```python
class SecureCookieSessionInterface(SessionInterface):

    salt = "cookie-session"
    digest_method = staticmethod(hashlib.sha1)
    key_derivation = "hmac"
    serializer = session_json_serializer
    session_class = SecureCookieSession

    def get_signing_serializer(self, app):
        if not app.secret_key:
            return None
        signer_kwargs = dict(
            key_derivation=self.key_derivation, digest_method=self.digest_method
        )
        return URLSafeTimedSerializer(
            app.secret_key,
            salt=self.salt,
            serializer=self.serializer,
            signer_kwargs=signer_kwargs,
        )

    def open_session(self, app, request):
        s = self.get_signing_serializer(app)
        if s is None:
            return None
        val = request.cookies.get(app.session_cookie_name)
        if not val:
            return self.session_class()
        max_age = total_seconds(app.permanent_session_lifetime)
        try:
            data = s.loads(val, max_age=max_age)
            return self.session_class(data)
        except BadSignature:
            return self.session_class()
```
`SecureCookieSessionInterface.open_session`方法中，首先获取序列化实例`s`，由`get_signing_serializer`可知，当Flask的`SECRET_KEY`为None, `s`值也为None，`open_session`直接返回None，否则继续获取`request`的cookies，cookies的key为`app.session_cookie_name`, 默认值为session，翻看Flask的源码，发现这里使用的是python的数据描述符类，关于此概念可以自行百度，才能具体理解此处的妙用。最后返回`self.session_class`实例化对象，`self.session_class`默认为session.py中的SecureCookieSession类。  
继续看当`self.session`为None时，将会重新赋值为`session_interface.make_null_session(self.app)`，我们看一下`make_null_session`的具体实现：
需要注意的是SecureCookieSessionInterface中并未发现`make_null_session`方法，但是在父类SessionInterface中实现了此方法，下面看一下具体的代码:

```python
class SessionInterface(object):

    null_session_class = NullSession
    pickle_based = False

    def make_null_session(self, app):
        """Creates a null session which acts as a replacement object if the
        real session support could not be loaded due to a configuration
        error.  This mainly aids the user experience because the job of the
        null session is to still support lookup without complaining but
        modifications are answered with a helpful error message of what
        failed.

        This creates an instance of :attr:`null_session_class` by default.
        """
        return self.null_session_class()

class NullSession(SecureCookieSession):
    def _fail(self, *args, **kwargs):
        raise RuntimeError(
            "The session is unavailable because no secret "
            "key was set.  Set the secret_key on the "
            "application to something unique and secret."
        )

    __setitem__ = __delitem__ = clear = pop = popitem = update = setdefault = _fail
    del _fail
```
看代码的实现方式，当Flask的配置`SECRET_KEY`为None，session将会是不可用。默认为`NullSession`的实例，此对象将不能进行任何操作。当我们启用session时，即`SECRET_KEY`不为None，此时我们的session将在response返回给客户端是进行`save_session`操作，即下面的逻辑：  

```python
class Flask(_PackageBoundObject):
    def process_response(self, response):
        ctx = _request_ctx_stack.top
        bp = ctx.request.blueprint
        funcs = ctx._after_request_functions
        if bp is not None and bp in self.after_request_funcs:
            funcs = chain(funcs, reversed(self.after_request_funcs[bp]))
        if None in self.after_request_funcs:
            funcs = chain(funcs, reversed(self.after_request_funcs[None]))
        for handler in funcs:
            response = handler(response)
        if not self.session_interface.is_null_session(ctx.session):
            self.session_interface.save_session(self, ctx.session, response)
        return response
```

可以看到我们对cookie的修改将会在cookie未过期之前一直保留，并通过itsdangerous库进行序列化和反序列化。至此session的基本逻辑已介绍完毕，具体的代码还需要我仔细去读才能理解。
