---
title : "flask主程序剖析"
chapter : true
weight : 2
---
# `src/flask`目录
主要文件：
* json：涉及到flask的json的序列化和反序列化函数和类
* `__init__.py`：里面涉及flask自身提高的函数和方法，可有flask模块直接导入。
* `__main__.py`：这是可执行python文件，功能和命令行flask run一致。
* `_compat.py`：主要处理python2和python3兼容性的问题，这样就可以在使用时不必关心python的版本。  
* app.py：实现核心WSGI应用对象。 
* blueprints.py：实现蓝图处理的相关函数和类，推荐在大型项目中使用。
* cli.py：运行flask的应用的简单命令行实现。
* config.py：实现flask配置逻辑的相关函数。
* ctx.py：实现flask上下文管理的相关对象。
* debughelpers.py：实现不同的帮助函数，以便在开发过程中更好的调试。
* globals.py：定义全部的全局对象，比如request、session、g、current_app等。
* helpers.py：定义帮助函数。
* logging.py：定义日志相关函数。
* sessions.py：定义基于sessions的cookie。
* signals.py：定义flask不同的阶段的信号。
* templating.py：实现与jinja2的集成。
* testing.py：实现测试过程中的帮助函数。
* views.py：实现基于类的视图。
* wrappers.py：实现对WSGI的request和response的封装。
