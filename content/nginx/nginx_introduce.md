+++
title = "Nginx系列之nginx自我介绍"
weight = 1
+++

> Nginx作为日趋流行的Web服务，已无处不在，相信做技术的同学不知道它的人很少。作为高性能web服务，无论是大厂bat、又或者是创业公司，都早已离不开它。那么它到底为何如此神秘，就让我一步步来探索吧！

Nginx[engine x]，是一种http和反向代理服务，同时也支持mail代理以及TCP/UDP代理，最初是由lgor Sysoev编写。在很长的一段时间中，它已经支持全世界很多大型网站的稳定运行，这其中就包括bat等诸多大公司。根据Netcraft网站统计显示，截止到2020年五月，nginx已经服务全世界25.62%的繁忙网站。并且其占有率逐年攀升。

接下来就从一下几个方面介绍nginx强大之处：

## http服务特性

* 静态文件服务和配置默认首页自动索引；支持文件描述符缓存；
* 利用缓存加速反向代理；支持负载均衡以及容错；
* 加速支持FastCGI、uwsgi、SCGI和memcached服务器的缓存;负载平衡和容错;
* 针对FastCGI，uwsgi，SCGI以及memcached服务的缓存加速支持以及对负载均衡和容错；
* 模块化架构。过滤器包括gzipping，byte ranges，分块响应，XSLT，SSI和图像转换过滤器。 如果由代理服务器或FastCGI / uwsgi / SCGI服务器处理单个页面中的包含多个SSI，则可以并行处理；
* SSL以及TLS SNI支持；
* 通过加权和基于依赖关系的优先级支持HTTP/2；
* 基于域名和基于ip的虚拟主机；
* 支持keep-alive和http流水线；
* 自定义日志格式、日志写缓冲、快速日志滚动以及syslog日志支持；
* 3xx-5xx错误重定向；
* 强大的url重写功能；
* 逻辑化配置，if支持；
* 可根据客户端ip、密码和子请求结果进行访问控制；
* http referer验证；
* 支持webDAV协议；
* FLV和MP4流支持；
* 限流；
* 根据地址对连接数和请求数目进行限制；
* ip地理位置支持；
* A/B测试支持；
* 请求镜像支持；
* Perl嵌入式；
* njs脚本语言；

##  邮件代理服务特性
* 使用外部http认证服务将用户重定向至IMAP和POP3服务；
* 使用外部HTTP身份验证服务器的用户身份验证以及到内部SMTP服务器的连接重定向；
* 认证方式：
   * POP3:  USER/PASS, APOP, AUTH LOGIN/PLAIN/CRAM-MD5;
   * IMAP: LOGIN, AUTH LOGIN/PLAIN/CRAM-MD5;
   * SMTP: AUTH LOGIN/PLAIN/CRAM-MD5;
* SSL支持；
* STARTTLS 和STLS支持；

## TCP/UDP代理特性
* TCP和UDP通用代理支持；
* SSL和TLS SNI对TCP支持；
* 负载均衡以及容错；
* 基于客户端地址进行访问控制；
* 根据客户端IP地址创建变量；
* 同一客户端地址的并发连接数限制；
* 自定义日志格式、日志写缓冲、快速日志滚动以及syslog日志支持；
* ip地理位置支持；
* A/B测试支持；
* njs脚本语言；

## 体系架构和拓展性
* 主master和多worker进程模式；worker进程可运行在非特权模式下；
* 灵活且强大的配置；
* 无服务中断的配置重载以及二进制升级；
* 支持kqueue (FreeBSD 4.1+), epoll (Linux 2.6+), /dev/poll (Solaris 7 11/99+), event ports (Solaris 10), select,  和poll;
* 支持各种kqueue特性，包括EV_CLEAR, EV_DISABLE(临时禁用事件)、LOWAT、EV EOF、可用数据数量、错误代码;
* 支持各种epoll功能，包括EPOLLRDHUP（Linux 2.6.17 +，glibc 2.8+）和EPOLLEXCLUSIVE（Linux 4.5 +，glibc 2.24+）；
* sendfile（FreeBSD 3.1 +，Linux 2.2 +，macOS 10.5 +），sendfile64（Linux 2.4.21+）和sendfilev（Solaris 8 7/01 +）支持;
* File AIO (FreeBSD 4.3+, Linux 2.6.22+);
* DIRECTIO (FreeBSD 4.4+, Linux 2.4+, Solaris 2.6+, macOS);
* Accept-filters (FreeBSD 4.1+, NetBSD 5.0+) and TCP_DEFER_ACCEPT (Linux 2.4+)支持；
* 10,000个不活动的HTTP保持活动的连接仅需约2.5m内存；
* 最低限度的数据集复制；

## 总结
基于以上丰富的特性以及极高的性能，Nginx的流行才是当之无愧的；今天我们知道nginx的用途，那我们如何才能用好nginx以及它的每个特性具体使用方式是什么，待我们下回分解。
