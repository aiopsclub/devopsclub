---
title : "短短几行 flask到底做了啥"
weight : 1 
---

# `flask`流程分析
首先我们先来看一个简单的flask应用:  

```python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello, World!"
if __name__ == "__main__":
    app.run()
```

从flask src/flask/__init__.py可知，Flask类来自app.py，我摘取关键的逻辑代码看一下：
```python
class Flask(_PackageBoundObject):
    def __init__(
        self,
        import_name,
        static_url_path=None,
        static_folder="static",
        static_host=None,
        host_matching=False,
        subdomain_matching=False,
        template_folder="templates",
        instance_path=None,
        instance_relative_config=False,
        root_path=None,
    ): 
        self.view_functions = {}
        """
        此处省略若干行，主要是一些初始化的操作
        """

    def run(self, host=None, port=None, debug=None, load_dotenv=True, **options):
         """
         省略其他干扰逻辑，看主要的逻辑
         """

        _host = "127.0.0.1"
        _port = 5000
        server_name = self.config.get("SERVER_NAME")
        sn_host, sn_port = None, None

        if server_name:
            sn_host, _, sn_port = server_name.partition(":")

        host = host or sn_host or _host
        port = int(next((p for p in (port, sn_port) if p is not None), _port))

        from werkzeug.serving import run_simple

        try:
            run_simple(host, port, self, **options)
        finally:
            self._got_first_request = False

    def route(self, rule, **options):

        def decorator(f):
            endpoint = options.pop("endpoint", None)
            self.add_url_rule(rule, endpoint, f, **options)
            return f

        return decorator

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

    def __call__(self, environ, start_response):

        return self.wsgi_app(environ, start_response)

```
从代码可知，app.run调用werkzeug.serving的run_simple，并把host、port、self(app的实例)等参数传递给run_sample。后续的wsgi逻辑都在werkzeug里处理，说起werkzeug，不得不说这是flask作者的又一大基础库，是wsgi应用程序的各种实用工具的集合，现在已经成为最先进的wsgi实用库之一。  

Flask封装Werkzeug，用它来处理WSGI的细节，同时通过提供更多的结构和模式来定义强大的web应用。  

下面就用流程图，简单看一下werkzeug内部的调用逻辑：  

![flask_base](../__img/flask_base.jpg)


werkzeug内部的调用逻辑:  
1. `make_server`返回`BaseWSGIServer`的实例, 实际调用`BaseWSGIServer`实例的`serve_forever`方法;  
2. `BaseWSGIServer`的`__init__`方法中，将`WSGIRequestHandler`赋予给`handler`变量，以及进行父类的初始化，即`HTTPServer.__init__(self, server_address, handler)`，此处比较重要，暂时埋个伏笔，现在`BaseWSGIServer`的`serve_forever`方法, 可以看到其实是调用父类`HTTPServer的serve_forever`，并将实例本身`self`传递进去。
3. 在看HTTPServer类中，并没有发现`serve_forever`方法，执行继续在父类`TCPServer`中寻找，但是`TCPServer`也没有`serve_forever`方法，继续寻找`TCPServer`的父类`BaseServer`。  
4. 在`BaseServer`中，终于找到`serve_forever`方法的实现，具体看一下：  

```python
class BaseServer:
  
    def serve_forever(self, poll_interval=0.5):
        """
        省略其他逻辑，关键代码就一行
        """
                         self._handle_request_noblock()

    def _handle_request_noblock(self):
        """
        省略其他逻辑，关键代码就一行
        """
                 self.process_request(request, client_address)

    def process_request(self, request, client_address):
        """
        省略其他逻辑，关键代码就一行
        """
        self.finish_request(request, client_address)

    def finish_request(self, request, client_address):
        """Finish one request by instantiating RequestHandlerClass."""
        self.RequestHandlerClass(request, client_address, self)
```

由源码可知，调用链为`serve_forever -->   _handle_request_noblock --> process_request --> finish_request`。  
最后进行`RequestHandlerClass`的实例化，还记得我们前面的提到的伏笔，此处的`RequestHandlerClass`就是`WSGIRequestHandler`类。  

接下来我们看`WSGIRequestHandler`的源码，发现并没有`__init__`方法，继续向上查看`BaseHTTPRequestHandler`类，发现仍旧没有，但是我们不能放弃，继续加油，来看`socketserver.StreamRequestHandler`父类，发现也没有，苍天呐，藏这么深，自己的路，跪着也得走完，继续看`BaseRequestHandler`，终于找到`__init__`方法：  

```python
class BaseRequestHandler:

    def __init__(self, request, client_address, server):
        """
        关键代码就是self.handle()的调用
        """
        try:
            self.handle()
        finally:
            self.finish()
```

由源码可知，self.handle()是调用实例的handle方法，于是我们又来看WSGIRequestHandler类，发现确实存在handle方法，贴代码：  

```python
class WSGIRequestHandler(BaseHTTPRequestHandler, object):

    def handle(self):
        """Handles a request ignoring dropped connections."""
        try:
            BaseHTTPRequestHandler.handle(self)
        except (_ConnectionError, socket.timeout) as e:
            self.connection_dropped(e)
        except Exception as e:
            if self.server.ssl_context is None or not is_ssl_error(e):
                raise
        if self.server.shutdown_signal:
            self.initiate_shutdown()
```

看WSGIRequestHandler的handle方法，发现竟然调用的是父类BaseHTTPRequestHandler的handle方法，贴父类BaseHTTPRequestHandler的handle方法的实现：  

```python
class BaseHTTPRequestHandler(socketserver.StreamRequestHandler):
    def handle(self):
        """Handle multiple requests if necessary."""
        self.close_connection = True

        self.handle_one_request()
        while not self.close_connection:
            self.handle_one_request()

```
由源码可知，调用实例`self`的`handle_one_request`方法，然后再看`WSGIRequestHandler`的`handle_one_request`方法，

```python
class WSGIRequestHandler(BaseHTTPRequestHandler, object):

    def handle_one_request(self):
        """关键逻辑就一行"""
            return self.run_wsgi()

    def run_wsgi(self):
        """去除枝叶
        """保留主干

        self.environ = environ = self.make_environ()

        """函数体内定义方法"""
        def write(data):
            """避免干扰 省略其实现"""

        def start_response(status, response_headers, exc_info=None):
            """避免干扰 省略其实现"""

        def execute(app):
            """app参数为wsgi的应用对象"""
            application_iter = app(environ, start_response)
            try:
                for data in application_iter:
                    write(data)
                if not headers_sent:
                    write(b"")
            finally:
                if hasattr(application_iter, "close"):
                    application_iter.close()

        """去除异常处理
           关键逻辑就就一行
        """
            execute(self.server.app)
```

由以上源码可知调用逻辑: `WSGIRequestHandler.handle_one_request --> WSGIRequestHandler.run_wsgi --> WSGIRequestHandler.run_wsgi内部的execute函数`。
我们可以看到`execute`运行`app`的`__call__`方法时，传递`environ`和`start_response`参数；其中  

* environ: 一个包含全部HTTP请求信息的字典，由WSGI Server解包HTTP请求生成；
* start_response: 一个WSGI Server提供的函数，调用可以发送响应的状态码和HTTP报文头， 函数在返回前必须调用一次start_response()。  


到此，终于看到werkzeug处理wsgi对象的所有逻辑;







参考文档：  
* [werkzeug](https://palletsprojects.com/p/werkzeug/)
