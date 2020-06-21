+++
title = "flask特性之配置系统"
weight = 11
+++


# `flask`之配置系统
---
我们在使用flask的时候，可以通过`app.config`来去取或者更新flask的配置，此外，flask的作者还针对配置的加载在Config类中提供多种方法，例如：`from_envvar`、`from_pyfile`、`from_object`等多种形式，那么其背后到底是如何实现的呢？今天我们就来看看flask的配置的神秘面纱。  
源码奉上：
```python
from .config import Config
from .config import ConfigAttribute

class Flask(_PackageBoundObject):

    config_class = Config

    # 以下的配置可由Flask的实例对象直接访问与修改，此处的精妙之处就是通过ConfigAttribute描述符类实现的

    testing = ConfigAttribute("TESTING")
    secret_key = ConfigAttribute("SECRET_KEY")
    session_cookie_name = ConfigAttribute("SESSION_COOKIE_NAME")
    permanent_session_lifetime = ConfigAttribute(
        "PERMANENT_SESSION_LIFETIME", get_converter=_make_timedelta
    )
    send_file_max_age_default = ConfigAttribute(
        "SEND_FILE_MAX_AGE_DEFAULT", get_converter=_make_timedelta
    )
    use_x_sendfile = ConfigAttribute("USE_X_SENDFILE")



    default_config = ImmutableDict(
        {
            "ENV": None,
            "DEBUG": None,
            "TESTING": False,
            "PROPAGATE_EXCEPTIONS": None,
            "PRESERVE_CONTEXT_ON_EXCEPTION": None,
            "SECRET_KEY": None,
            "PERMANENT_SESSION_LIFETIME": timedelta(days=31),
            "USE_X_SENDFILE": False,
            "SERVER_NAME": None,
            "APPLICATION_ROOT": "/",
            "SESSION_COOKIE_NAME": "session",
            "SESSION_COOKIE_DOMAIN": None,
            "SESSION_COOKIE_PATH": None,
            "SESSION_COOKIE_HTTPONLY": True,
            "SESSION_COOKIE_SECURE": False,
            "SESSION_COOKIE_SAMESITE": None,
            "SESSION_REFRESH_EACH_REQUEST": True,
            "MAX_CONTENT_LENGTH": None,
            "SEND_FILE_MAX_AGE_DEFAULT": timedelta(hours=12),
            "TRAP_BAD_REQUEST_ERRORS": None,
            "TRAP_HTTP_EXCEPTIONS": False,
            "EXPLAIN_TEMPLATE_LOADING": False,
            "PREFERRED_URL_SCHEME": "http",
            "JSON_AS_ASCII": True,
            "JSON_SORT_KEYS": True,
            "JSONIFY_PRETTYPRINT_REGULAR": False,
            "JSONIFY_MIMETYPE": "application/json",
            "TEMPLATES_AUTO_RELOAD": None,
            "MAX_COOKIE_SIZE": 4093,
        }
    )

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
        # 省略其他逻辑 保留配置相关的代码
        # 初始化配置cofnig

        self.config = self.make_config(instance_relative_config)

    def make_config(self, instance_relative=False):

        root_path = self.root_path
        if instance_relative:
            root_path = self.instance_path
        defaults = dict(self.default_config)
        defaults["ENV"] = get_env()
        defaults["DEBUG"] = get_debug_flag()
        return self.config_class(root_path, defaults)

```
由代码可知，Flask类在初始化时就进行配置的初始化，即`self.config = self.make_config(instance_relative_config)`，此处调用`make_config`方法，返回`self.config_class`所对应的类Config的实例化对象，在Config的实例化的时候，将默认配置`self.default_config`一起加载，并最终将生产的Config实例化对象赋予`self.config`，到此flask的配置的加载逻辑就结束，在开发时，直接可以操作`app.config`来进行读取和修改。  
在代码中可以看到，flask通过描述符类ConfigAttribute将某些配置直接绑定在Flask类上，这样我们就可以直接修改Flask类实例对象的属性来达到修改配置的目的，比如`app.testting=True`，此处值得我们来学习，描述符类虽然比较抽象，但威力很大，后续将专门说说python的描述符类。  

接下来看一下Config类的实现：

```python 
class Config(dict):

    def __init__(self, root_path, defaults=None):
        dict.__init__(self, defaults or {})
        self.root_path = root_path

    def from_envvar(self, variable_name, silent=False):

        if not rv:
            if silent:
                return False
            raise RuntimeError(
                "The environment variable %r is not set "
                "and as such configuration could not be "
                "loaded.  Set this variable and make it "
                "point to a configuration file" % variable_name
            )
        return self.from_pyfile(rv, silent=silent)

    def from_pyfile(self, filename, silent=False):

        filename = os.path.join(self.root_path, filename)
        d = types.ModuleType("config")
        d.__file__ = filename
        try:
            with open(filename, mode="rb") as config_file:
                exec(compile(config_file.read(), filename, "exec"), d.__dict__)
        except IOError as e:
            if silent and e.errno in (errno.ENOENT, errno.EISDIR, errno.ENOTDIR):
                return False
            e.strerror = "Unable to load configuration file (%s)" % e.strerror
            raise
        self.from_object(d)
        return True

    def from_object(self, obj):

        if isinstance(obj, string_types):
            obj = import_string(obj)
        for key in dir(obj):
            if key.isupper():
                self[key] = getattr(obj, key)

    def from_json(self, filename, silent=False):
        filename = os.path.join(self.root_path, filename)

        try:
            with open(filename) as json_file:
                obj = json.loads(json_file.read())
        except IOError as e:
            if silent and e.errno in (errno.ENOENT, errno.EISDIR):
                return False
            e.strerror = "Unable to load configuration file (%s)" % e.strerror
            raise
        return self.from_mapping(obj)

    def from_mapping(self, *mapping, **kwargs):

        mappings = []
        if len(mapping) == 1:
            if hasattr(mapping[0], "items"):
                mappings.append(mapping[0].items())
            else:
                mappings.append(mapping[0])
        elif len(mapping) > 1:
            raise TypeError(
                "expected at most 1 positional argument, got %d" % len(mapping)
            )
        mappings.append(kwargs.items())
        for mapping in mappings:
            for (key, value) in mapping:
                if key.isupper():
                    self[key] = value
        return True

    def get_namespace(self, namespace, lowercase=True, trim_namespace=True):

        rv = {}
        for k, v in iteritems(self):
            if not k.startswith(namespace):
                continue
            if trim_namespace:
                key = k[len(namespace) :]
            else:
                key = k
            if lowercase:
                key = key.lower()
            rv[key] = v
        return rv

    def __repr__(self):
        return "<%s %s>" % (self.__class__.__name__, dict.__repr__(self))

```
从Config的源码中可以看到， Config类本质上是dict的子类，所以dict的原生的各种方法，Config同样支持。另外Config类中定义了多种加载配置的方法，包括`from_envvar`、`from_pyfile`、`from_object`、`from_json`、`from_mapping`、`get_namespace`。 from_开头的方法实现起来简单，我们可以根据自己的需求来选择使用何种加载配置的方法。在此，我们说说`get_namespace`方法，由实现可知，改方法是匹配所有以参数namespace开头的配置项，让我们看一个例子：  

```python
app.config['IMAGE_STORE_TYPE'] = 'fs'
app.config['IMAGE_STORE_PATH'] = '/var/app/images'
app.config['IMAGE_STORE_BASE_URL'] = 'http://img.website.com'
image_store_config = app.config.get_namespace('IMAGE_STORE_')

`image_store_config`:
{
    'type': 'fs',
    'path': '/var/app/images',
    'base_url': 'http://img.website.com'
}
```

通过`get_namespace`方法，可以方便的寻找同一类配置。  

配置的相关操作：  
修改：  
* app.config["example"] =  "example"
* app.testting = False 这种方式默认只提供有限的配置项
* app.config.update(TESTING=True)  

删除：  
* del app.config["example"]


参考文档：  
* [flask config文档](https://flask.palletsprojects.com/en/1.1.x/config/#configuration-basics)

