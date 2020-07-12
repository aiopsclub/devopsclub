---
title : "路由匹配探秘"
weight : 2
---

# `flask`路由匹配的奥秘
先上源码：
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
从上面的代码中，并没有直接发现路由匹配相关的逻辑，那问题来了，路由匹配到底藏在哪里？其实关键在于ctx.push()操作，ctx为全局变量request上下文的实例，ctx.push()将其进行入栈操作，放在栈顶。现贴出ctx.push()的相关逻辑：
```python
# self.request_context 为RequestContext类的实例化对象。 

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

    def push(self):
        """
           去除枝叶代码 
           保留主要逻辑
        """
        if self.url_adapter is not None:
            self.match_request()

    def match_request(self):

        try:
            result = self.url_adapter.match(return_rule=True)
            self.request.url_rule, self.request.view_args = result
        except HTTPException as e:
            self.request.routing_exception = e
```
通过调用链可知，`self.url_adapter`其实就是werkzeug.routing的MapAdapter类的实例化对象，我们来看看MapAdapter的match方法是如何实现的：  

```python
class MapAdapter(object):

    def match(self, path_info=None, method=None, return_rule=False, query_args=None, websocket=None):
        """
           去除枝叶 保留主干
        """
        for rule in self.map._rules:
            try:
                rv = rule.match(path, method)
            except RequestPath as e:
                raise RequestRedirect(
                    self.make_redirect_url(
                        url_quote(e.path_info, self.map.charset, safe="/:|+"),
                        query_args,
                    )
                )
            except RequestAliasRedirect as e:
                raise RequestRedirect(
                    self.make_alias_redirect_url(
                        path, rule.endpoint, e.matched_values, method, query_args
                    )
                )
            if rv is None:
                continue
            if rule.methods is not None and method not in rule.methods:
                have_match_for.update(rule.methods)
                continue

            if rule.websocket != websocket:
                websocket_mismatch = True
                continue

            if self.map.redirect_defaults:
                redirect_url = self.get_default_redirect(rule, method, rv, query_args)
                if redirect_url is not None:
                    raise RequestRedirect(redirect_url)

            if rule.redirect_to is not None:
                if isinstance(rule.redirect_to, string_types):

                    def _handle_match(match):
                        value = rv[match.group(1)]
                        return rule._converters[match.group(1)].to_url(value)

                    redirect_url = _simple_rule_re.sub(_handle_match, rule.redirect_to)
                else:
                    redirect_url = rule.redirect_to(self, **rv)
                raise RequestRedirect(
                    str(
                        url_join(
                            "%s://%s%s%s"
                            % (
                                self.url_scheme or "http",
                                self.subdomain + "." if self.subdomain else "",
                                self.server_name,
                                self.script_name,
                            ),
                            redirect_url,
                        )
                    )
                )

            if require_redirect:
                raise RequestRedirect(
                    self.make_redirect_url(
                        url_quote(path_info, self.map.charset, safe="/:|+"), query_args
                    )
                )

            if return_rule:
                return rule, rv
            else:
                return rule.endpoint, rv

        if have_match_for:
            raise MethodNotAllowed(valid_methods=list(have_match_for))

        if websocket_mismatch:
            raise WebsocketMismatch()

        raise NotFound()
```
由代码可见，路由匹配发生在werkzeug的routing模块中，通过对map对象中的_rules的迭代，来匹配url以及methods，并通过不同的异常，来通知上层，即app模块中Flask类的wsgi_app函数，如果发生异常，则生成对应的response，返回给客户端，如果未发生异常，则通过Flask类的full_dispatch_request函数和request的endpoint属性来分发请求的views函数，而endpoint和view_func的对应关系保存在Flask类的view_functions中。

