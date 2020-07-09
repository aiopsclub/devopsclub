+++
title = "flask特性之methodview"
weight = 10 
+++

# flask之`methodview`
---
大型项目中，代码不仅仅是功能的实现，更主要在于代码的可维护性、可读性以及良好的代码组织结构。为了实现这些特性，methodview和blueprint就是flask的两大利器。blueprint在之前的文章为们已经分析完毕，接下来看看methodview的魅力。  

methodview使用示例：  

```python
from flask.views import MethodView

class CounterAPI(MethodView):
    def get(self):
        return session.get('counter', 0)

    def post(self):
        session['counter'] = session.get('counter', 0) + 1
        return 'OK'

app.add_url_rule('/counter', view_func=CounterAPI.as_view('counter'))
```
methodview在使用时，路由的逻辑和app.route是一致的，关键在于MethodView类的`as_view`方法，那它是如何实现的呢？

MethodView的实现：

```python
class View(object):

    methods = None

    provide_automatic_options = None

    decorators = ()

    def dispatch_request(self):
        """Subclasses have to override this method to implement the
        actual view function code.  This method is called with all
        the arguments from the URL rule.
        """
        raise NotImplementedError()

    @classmethod
    def as_view(cls, name, *class_args, **class_kwargs):

        def view(*args, **kwargs):
            self = view.view_class(*class_args, **class_kwargs)
            return self.dispatch_request(*args, **kwargs)

        if cls.decorators:
            view.__name__ = name
            view.__module__ = cls.__module__
            for decorator in cls.decorators:
                view = decorator(view)

        # 对view函数的属性修改
        view.view_class = cls
        view.__name__ = name
        view.__doc__ = cls.__doc__
        view.__module__ = cls.__module__
        view.methods = cls.methods
        view.provide_automatic_options = cls.provide_automatic_options
        return view

class MethodView(with_metaclass(MethodViewType, View)):

    def dispatch_request(self, *args, **kwargs):
        meth = getattr(self, request.method.lower(), None)

        # If the request method is HEAD and we don't have a handler for it
        # retry with GET.
        if meth is None and request.method == "HEAD":
            meth = getattr(self, "get", None)

        assert meth is not None, "Unimplemented method %r" % request.method
        return meth(*args, **kwargs)
```
可以看到MethodView类的`as_view`是集成自父类View，可以看到`as_view`被装饰成classmethod，`as_view`内部定义view函数，并将其返回来充当url对应的`view_func`，我们详细看一下view函数本身处理的逻辑，也就是当请求到达时，view函数的处理过程。简单来看就是`self`是`view.view_class`的实例化对象，而后把请求相关参数传递给`self.dispatch_request`，处理请求，最后返回。在View类中`as_view`函数中，我们可以看到在内部函数view返回时，对view函数的本身的属性进行了修改，包括`view_class`、`__doc__`、`__module__`、`methods.provide_automatic_options`。这都是在添加路由映射时`app.add_url_rule`所需的关键信息。  

在View类中，我们可以看到一个decorators属性，从名称上看，这是装饰器列表，我们可以提供自己的装饰器，在修改view函数的运行时行为，做到程序高内聚，低耦合。


