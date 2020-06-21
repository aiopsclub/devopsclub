+++
title = "flask特性之模板系统"
weight = 12
+++


# flask之模板系统
flask以jinja2为引擎提供强大的模板能力，在flask中使用模板非常简单，只需使用两个关键的函数：`render_template()`、`render_template_string()`。  
模板使用示例：

```python
from flask import Flask
from flask.templating import render_template_string

app = Flask(__name__)


@app.route("/")
def index():
    return render_template_string("Hello {{ name  }}!", name="world")


if __name__ == "__main__":
    app.run(host="0.0.0.0")
```
由代码可知，`render_template_string`函数渲染模板字符串，并用变量进行替换，生成预设的内容。  

`render_template_string`的具体实现(来自于templating.py)：  

```python
def _render(template, context, app):
    before_render_template.send(app, template=template, context=context)
    rv = template.render(context)
    template_rendered.send(app, template=template, context=context)
    return rv

def render_template(template_name_or_list, **context):
    ctx = _app_ctx_stack.top
    ctx.app.update_template_context(context)
    return _render(
        ctx.app.jinja_env.get_or_select_template(template_name_or_list),
        context,
        ctx.app,
    )

def render_template_string(source, **context):
    ctx = _app_ctx_stack.top
    ctx.app.update_template_context(context)
    return _render(ctx.app.jinja_env.from_string(source), context, ctx.app)

```
在flask进行处理时，依赖于jinja2模板，在`_render`函数中清楚的体现出来，`render_template`、`render_template_string`实际最后都会调用_render函数，两者最主要的区别在于在于文件加载和字符串加载。具体的模板语法可参考jinja2的官方文档。


参考文档：  
* [flask模板文档](https://flask.palletsprojects.com/en/1.1.x/templating/)
