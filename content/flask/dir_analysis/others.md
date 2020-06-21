+++
title = "flask源码之其他目录"
weight = 5 
+++
# 其他文件  
除了artwork、docs、examples和tests目录，其余的普通文件和隐藏文件都为开发、开源协议和打包相关文件。  

详细说明：
* .azure-pipelines.yml: 此为微软发布的Azure Pipelines，新的CI/CD服务，是微软DEVOPS产品的一部分，可用于构建、测试和部署工作服务，并可让各种语言和项目类型和平台协同工作。对开源项目来说，可无限制使用。
* .gitignore：定义在git开发时，忽略指定的未跟踪的文件。  
* .pre-commit-config.yaml：结合git的hooks机制，该文件可以指定commit之前执行预定于的动作，比如代码格式化、pep8规范检查等等，自动化除代码逻辑外的工作，使我们专注于代码开发。
* CHANGES.rst: 此文件为rst文件，文件内容为flask的版本release记录，比如何时release以及版本的变化的内容，同样可以通过sphinx生产版本变化文档。
* CODE_OF_CONDUCT.md：开源代码的行为准则 
* CONTRIBUTING.rst：flask贡献指南，里面说明如何为flask做贡献，成为falsk开源项目贡献者的一员。
* LICENSE.rst: 开源协议  
* MANIFEST.in：python打包时，非py资源清单文件。 
* README.rst：falsk的readme文档，介绍flask项目的用法，以及相关的链接。
* setup.cfg: python打包发布配置文件。
* setup.py：python的打包发布相关文件。
* tox.ini：tox的配置文件，tox是通用的虚拟环境管理和测试命令行工具。tox能够让我们在同一个Host上自定义出多套相互独立且隔离的python环境（tox是openstack社区最基本的测试工具，比如python程序的兼容性、UT等）。它的目标是提供最先进的自动化打包、测试和发布功能。



参考文档：  
* [azure-pipelines](https://azure.microsoft.com/zh-cn/services/devops/pipelines/)  
* [gitignore](https://git-scm.com/docs/gitignore)  
* [pre-commit](https://pre-commit.com/)  
* [contributor-covenant](https://www.contributor-covenant.org/)
* [tox](https://tox.readthedocs.io/en/latest/)

