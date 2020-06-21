+++
title = "flask特性之blueprint"
weight = 9 
+++

# flask之`blueprint`
---
flask的强大在于不仅可以快速实现小型api服务的开发，也能在大型项目中发挥巨大的作用。由于在大型项目中，我们所有的程序不可能在一个文件中，必须有一定的组织结构，这时候flask的blueprint将会帮上我们的大忙。  
blueprint蓝图，可以使具有相同url前缀的view函数组织在一起，进行程序解耦，方便开发调试和维护。下面来看一下简单的实例：  

```python
# 定义蓝图
example = Blueprint('example', __name__, url_prefix="/example")

# 绑定视图函数
# 在此处，完整的url是和蓝图的url_prefix组合在一起，为/example/auth
@example.route('/auth')
def auth(auth):
    return "auth is ok"

# 注册路由
app = Flask(__name__)
app.register_blueprint(example_api)
```
我们来详细看看这背后到底发生了什么？先看看Flask类的`register_blueprint`函数：

```python
class Flask(_PackageBoundObject):

    @setupmethod
    def register_blueprint(self, blueprint, **options):

        first_registration = False

        if blueprint.name in self.blueprints:
            assert self.blueprints[blueprint.name] is blueprint, (
                "A name collision occurred between blueprints %r and %r. Both"
                ' share the same name "%s". Blueprints that are created on the'
                " fly need unique names."
                % (blueprint, self.blueprints[blueprint.name], blueprint.name)
            )
        else:
            self.blueprints[blueprint.name] = blueprint
            self._blueprint_order.append(blueprint)
            first_registration = True

        blueprint.register(self, options, first_registration)
```

在代码中可知，Flask将blueprint的相关信息写入到`blueprints`和`_blueprint_order`中，并在首次注册时，`first_registration`的值为True。最后调用blueprint的register函数进行后续操作，那么blueprint的register函数又是如何实现的呢？让我继续刨根问底，先看blueprint的register函数的源码：

```python
class BlueprintSetupState(object):

    def __init__(self, blueprint, app, options, first_registration):
        self.app = app
        self.blueprint = blueprint
        self.options = options
        self.first_registration = first_registration
        subdomain = self.options.get("subdomain")
        if subdomain is None:
            subdomain = self.blueprint.subdomain
        self.subdomain = subdomain
        url_prefix = self.options.get("url_prefix")
        if url_prefix is None:
            url_prefix = self.blueprint.url_prefix
        self.url_prefix = url_prefix
        self.url_defaults = dict(self.blueprint.url_values_defaults)
        self.url_defaults.update(self.options.get("url_defaults", ()))

    def add_url_rule(self, rule, endpoint=None, view_func=None, **options):

        if self.url_prefix is not None:
            if rule:
                rule = "/".join((self.url_prefix.rstrip("/"), rule.lstrip("/")))
            else:
                rule = self.url_prefix
        options.setdefault("subdomain", self.subdomain)
        if endpoint is None:
            endpoint = _endpoint_from_view_func(view_func)
        defaults = self.url_defaults

        if "defaults" in options:
            defaults = dict(defaults, **options.pop("defaults"))

        self.app.add_url_rule(rule, "%s.%s" % (self.blueprint.name, endpoint), view_func, defaults=defaults, **options)

class Blueprint(_PackageBoundObject):
    def route(self, rule, **options):
        def decorator(f):
            endpoint = options.pop("endpoint", f.__name__)
            self.add_url_rule(rule, endpoint, f, **options)
            return f

        return decorator

    def add_url_rule(self, rule, endpoint=None, view_func=None, **options):
        if endpoint:
            assert "." not in endpoint, "Blueprint endpoints should not contain dots"
        if view_func and hasattr(view_func, "__name__"):
            assert (
                "." not in view_func.__name__
            ), "Blueprint view function name should not contain dots"
        self.record(lambda s: s.add_url_rule(rule, endpoint, view_func, **options))

    def record(self, func):
        """
        删除次要的逻辑代码，保留主干
        """
        self.deferred_functions.append(func)

    def make_setup_state(self, app, options, first_registration=False):
        return BlueprintSetupState(self, app, options, first_registration)

    def register(self, app, options, first_registration=False):
        """
        删除次要的逻辑代码，保留主干
        """

        self._got_registered_once = True
        state = self.make_setup_state(app, options, first_registration)

        for deferred in self.deferred_functions:
            deferred(state)
```
由buleprint的实例可知，example为Blueprint的实例化对象，和原始的添加路由的方式一致，都是利用route装饰器完成操作，那么和原始的路由添加方式到底不同在哪里呢？让我从代码中探寻答案：在代码中`Blueprint`的route方法本质是调用`add_url_rule`方法，而`add_url_rule`的方法最终调用的是record方法，最终的目的是`self.deferred_functions`的追加func。那是如何和app上下文对应起来的呢？关键就在register的方法，在register方法中，首先通过`make_setup_state`方法，获取BlueprintSetupState的实例化对象state，然后遍历`deferred_functions`，调用`deferred_functions`内部的每个匿名函数，即deferred， 参数为state。我们来看匿名函数的具体的格式：`lambda s: s.add_url_rule(rule, endpoint, view_func, **options)`，s形参即state，也就是`BlueprintSetupState`的实例化对象，最终调用`BlueprintSetupState.add_url_rule`函数，后续的逻辑和原始的路由系统一致。
