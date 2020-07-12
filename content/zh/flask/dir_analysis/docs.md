---
title : "flask源码之doc目录"
weight : 3 
---
# `docs`目录  
从目录名中就可以知道，此目录是存放flask文档的位置，flask是利用rst格式进行书写的，可以利用sphinx生成清晰而且优美的文档，新版的python3
的文档就是有sphinx工具生成，同时，它已经以成为python项目中首选的文档工具，具体可参考sphink官方网站[sphink](https://www.sphinx-doc.org/en/master/)  

可以看到docs目录中都是rst结尾的文件，我们称之为reStructuredText, 含义是”重新构建的文本”，也被称为RST或者是reST。reStructuredText是Python编程语言的Docutils项目的一部分，Python Doc-SIG(Documentation Special Interest Group)。该项目类似于Java的JavaDoc或者Perl的POD项目。Docutils能够从Python程序中提取注释和信息，格式化成程序文档。  

.rst文件是轻量级标记语言的一种，被设计为容易阅读和编写的纯文本，并且可以借助Docutils这样的程序进行文档处理，也可以转换为HTML或者PDF等多种格式，或者由Sphinx-Doc这样的程序转换为LaTex、man等更多格式。  

参考文档：  
* [docutils](https://docutils.sourceforge.io/docs/user/rst/quickref.html)
* [flask官方文档](https://flask.palletsprojects.com/en/1.1.x/)
