---
title : "Nginx之Http模块系列之brower模块"
weight : 19 
---

> `brower`模块主要作用是根据http请求头中"User-Agent"的值，以浏览器的特征字符来判断新旧浏览器，并生成对应的变量，以供后续的请求处理逻辑来使用。 

## 1. 简介  
`ngx_http_browser_module`模块，通过判断"User-Agent"请求头的值，来生成变量，以供后续的请求逻辑处理。  


## 2.内置变量列表
* $modern_browser  
如果浏览器被标识为现代浏览器，则等于`modern_browser_value`指令设置的值；

* $ancient_browser  
如果浏览器被识别为古老浏览器，则等于`Ancient_browser_value`指令设置的值；

* $msie  
如果浏览器被识别为MSIE，不区分任何版本，则等于1；  

## 3.配置示例

现代浏览器的识别逻辑配置:   
```shell
modern_browser_value "modern.";

# modern_brower指定何种浏览器以及对应的版本被视为现代浏览器, 配置格式后续介绍

modern_browser msie      5.5;
modern_browser gecko     1.0.0;
modern_browser opera     9.0;
modern_browser safari    413;
modern_browser konqueror 3.0;

当浏览器被判断为现代浏览器时，modern_browser变量等于"modern."，即modern_browser_value配置的变量。
index index.${modern_browser}html index.html;
```

古老浏览器的兼容判断:
```shell
modern_browser msie      5.0;
modern_browser gecko     0.9.1;
modern_browser opera     8.0;
modern_browser safari    413;
modern_browser konqueror 3.0;

modern_browser unlisted;

# ancient_browser配置何种子串被识别为古老浏览器
ancient_browser Links Lynx netscape4;

# 当浏览器被识别为古老浏览器，ancient_browser为1; 在此处可以做兼容处理或者给用户直接以提示，提示更新或者更换现代浏览器;

if ($ancient_browser) {
    rewrite ^ /ancient.html;
}

```

## 4.配置格式
```shell
Syntax: ancient_browser string ...;
Default:    —
Context:    http, server, location
```
配置"User-Agent"头有何种子串时，被判断为古老浏览器，特殊子串"netscape4"等价于正则表达式: ^Mozilla/[1-4]

```shell
Syntax: ancient_browser_value string;
Default:    
ancient_browser_value 1;
Context:    http, server, location
```
当识别为古老浏览器时，$ancient_browser变量的值，即默认为1;


```shell
Syntax: modern_browser browser version;
modern_browser unlisted;
Default:    —
Context:    http, server, location
```
配置何种浏览器何种版本时，判定为现代浏览器。browser取值：msie, gecko, opera, safari, konqueror. 版本定义格式为X, X.X, X.X.X, 或者X.X.X.X. ,每个格式的最大值分别为: 4000, 4000.99, 4000.99.99, and 4000.99.99.99。  
unlisted为特殊字符串，配置当浏览器都未出现在来modern_browser和ancient_browser匹配范围里，则被视为现代浏览器。否则被视为古老浏览器。如果请求头中未提供"User-Agent"头，则被视为未出现匹配列表中。  


```shell
Syntax: modern_browser_value string;
Default:    
modern_browser_value 1;
Context:    http, server, location
```
当识别为现代浏览器时，$modern_browser变量的值，默认为1;

## 4.总结
`ngx_http_browser_module`提供了浏览器兼容的判断机制，使我们在做新旧浏览器兼容处理时更为优雅与高效，同学们可以在实际需求中多加运用，将业务逻辑中的浏览器版本抽离出来，使得业务更像业务，无需考虑其他。  
