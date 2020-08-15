---
title : "Nginx模块系列之核心模块(中)"
weight : 12 
---

> 在Nginx核心模块第一节中，我们介绍了包括静态目录配置、限速以及各种优化参数等各种配置，都是我们在日常业务配置中经常遇到的，今天我们来介绍一下最常出现也最重要的location指令，该指令在路由多服务分发方面起到举足轻重的作用，如今微服务大行其道，localtion的灵活运用也成为了精通nginx必须踏过的一道门槛，下面就让我们一起来学习并掌握它吧! 

## 1. location的作用   

配置语法: location [ = | ~ | ~* | ^~  ] uri { ...  } 或者  location @name { ...  }; 配置上下文: server, location。  
简单说，location就是匹配请求URI来进行不同处理，由语法可知，location支持4种不同的匹配方式，以及如何定义命名location。  
nginx的location匹配是针对规范化URI进行的。nginx将会对%XX表单中编码的文本进行解码，解除对相对路径组件的引用，即'.'和'..'的解引用，同时会对两个或多个相邻斜杠压缩为单个斜杠从而形成规范化URI，便于location指令的匹配处理。  

## 2. location配置规则之正则匹配
location的正则匹配主要分为两种配置格式，分别是区分大小写和不区分大小写匹配。
示例:  

```shell
# 1.不区分大小写
location ~* \.(gif|jpg|jpeg)$ {
    [ configuration E  ]
}
# 2.区分大小写
location ~ \.(gif|jpg|jpeg)$ {
    [ configuration E  ]
}
```
`~`和`~*`都为正则匹配，`~*`主要功能为不区分大小写，在实际使用过程中，我们可以根据自己的需求选择即可，在正则匹配中，同样可以使用正则捕获，捕获的值可以在后续配置过程中使用。


## 3. location配置规则之前缀匹配
前缀匹配同样也有两种格式，主要区别在于是否有`^~`修饰符的存在。
示例: 
```shell
# 无^~修饰符
location /documents/ {
    [ configuration C  ]
}

# 有^~修饰符

location ^~ /documents/ {
    [ configuration C  ]
}
```
这两种写法在作用都是匹配/documents/开头的请求URI，区别在于匹配优先级规则方面，当`^~`修饰符存在时，nginx检查所有前缀匹配, 最长前缀匹配即为匹配终点，不再进行正则匹配的检查。如果不存在`^~`，nginx将会暂存最长的前缀匹配，然后进行正则匹配检查，如果正则匹配有命中，则返回正则匹配，否则返回已记录的最长前缀匹配。

## 4. location匹配之精确匹配
location精确匹配: 修饰符为`=`，顾名思义就是当请求URI完全匹配时，精确匹配规则立即返回，不再进行其他匹配规则的检查。  
示例: 
```shell
location = / {
    [ configuration A  ]
}
```
## 5. location配置规则的优先级
1. 精确匹配
2. 前缀匹配  
3. 正则匹配
nginx的基本的搜索规则如上所示，但在前缀匹配中，`^~`修饰符可影响最终结果，故总结如下：  

nginx在匹配中优先进行精确匹配，一旦匹配成功，立即返回。如果精确匹配未命中则进行前缀匹配，在所有匹配的前缀匹配中暂存最长的前缀匹配，如果前缀匹配有`^~`修饰符，则立即将最长匹配返回，如果没有`^~`修饰符，则继续进行正则匹配，如果正则匹配有命中，则直接返回匹配的正则匹配，否则返回暂存的最长前缀匹配。如果以上匹配规则都未命中，则返回404响应。   

## 6. location前缀匹配的隐藏逻辑
如果location是以斜杠字符结尾的前缀匹配，并且请求由proxy_pass, fastcgi_pass, uwsgi_pass, scgi_pass, memcached_pa或grpc_pass中的一个处理，则将执行特殊处理逻辑。 对于请求URI等于前缀字符串但不带斜杠的请求，重定向至前缀字符串并带有斜杠的301响应将返回至客户端。 如果不希望这样，则可以这样定义URI和location的完全匹配：
```shell
location /user/ {
    proxy_pass http://user.example.com;
}

# 精确匹配/user, 避免隐藏逻辑的处理
location = /user {
    proxy_pass http://login.example.com;
}
```

## 7. location的嵌套
nginx的location其实支持嵌套逻辑的，但是在精确匹配和命名localtion中是不允许的，在location的嵌套中，规则未变，但是不推荐使用。

## 8. location配置优化
1. 配置location时坚持最窄优先的原则，即最常用的匹配尽量放在优先级高的匹配规则中，尤其是在正则匹配中，可以减少uri匹配的次数，提高nginx的处理效率;
2. 由于正则匹配的灵活性，其出现频率很高，但是额外的正则处理将会消耗cpu资源，此时我们可以在main配置段中开启pcre_jit on; 1.1.12版本开始支持，其可以显著加快正则表达式的处理速度。

## 9. 总结 
location的配置是nginx的重中之重，我们需要认真学习，仔细消化。不做location配置的奴隶，加油!
