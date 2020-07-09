+++
title = "Nginx系列之nginx七层反向代理"
weight = 6 
+++

> nginx不仅仅是静态服务器，它依赖`ngx_http_proxy_module`和`ngx_http_upstream_module`等模块，实现了http七层代理， 支持缓存、自定义头部、上游服务器容错等特性，现在很多公司拿它当做网关，做请求分发。接下来就看一下nginx是如何来配置从而成为反向代理服务器。

## 1. nginx配置 

```shell
# nginx.conf

user nginx;
error_log /var/log/nginx/error.log;

http {

    server {
		listen 80;
        location / {
            proxy_pass       http://localhost:8000;
            proxy_set_header Host      $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}

```
经过以上简单的配置，nginx -s reload后，nginx即可作为反向代理服务器。这段配置的关键在于server配置端，nginx中使用localtion匹配uri，`proxy_pass`来指定上游服务器，`proxy_set_header`设置发送到上游服务器的请求头部。当我们请求本机的80端口，nginx将会把请求转发到8000端口，然后将响应返回给客户端。

## 2. proxy_pass代理规则
```shell
# 配置格式
1. 代理服务器的协议和地址以及可选的uri，协议可以是http或者https，地址可以是ip或者域名以及可选的端口。示例：
proxy_pass http://localhost:8000/uri/;
2. unix套接字格式。示例:
proxy_pass http://unix:/tmp/backend.socket:/uri/;  

# proxy_pass的代理地址是否携带uri的不同处理方式 

1. 携带URI
location /name/ {
    proxy_pass http://127.0.0.1/remote;
}

访问示例:
http://192.168.1.1/name/test ---> http://127.0.0.1/remotetest 
当proxy_pass的后面的代理地址携带URI时，nginx会将localtion匹配的部分[例子中为/name/]替换为/remote，然后和请求的URI除/name/的部分拼接，最后形成的上游服务器访问的地址为http://127.0.0.1/remotetest。

2. 不携带URI
location /some/path/ {
    proxy_pass http://127.0.0.1;
}
访问示例:
http://192.168.1.1/some/path/res ---> http://127.0.0.1/some/path/res 
当proxy_pass的后面的代理地址不携带URI时，nginx会将客户端请求的URI直接放在上游服务器后面，最后形成的上游服务器访问的地址为http://127.0.0.1/some/path/res。

3. location的匹配方式为正则表达式 
localtion *~ \.jpg$ {
    proxy_pass http://127.0.0.1
}
在这种情况下，proxy_pass指令后的上游服务器不能带有URI，否则nginx会报错!


4. 命名localtion 

location / {
    error_page 404 = @fallback;

}

location @fallback {
    proxy_pass http://backend;

}
在使用命名localtion匹配时，proxy_pass指令后的上游服务器不能带有URI。
```

## 3. 上游服务器组的实现
在如今的流量为王的时代，单机以及远远不能满足性能要求，这就需要我们在上游服务中提供多台服务器，形成服务器组。共同来提供服务，并可以采用不同的负载均衡算法，更加灵活与可扩展。而做到这些需要依赖`ngx_http_upstream_module`模块。
示例:
```shell
http {

    upstream backend {
    # 配置负载均衡算法
    ip_hash;
    server backend1.example.com       weight=5;
    server backend2.example.com:8080;
    server unix:/tmp/backend3;

    server backup1.example.com:8080   backup;
    server backup2.example.com:8080   backup;

    }

    server {
        location / {
        proxy_pass http://backend;
    
        }
    }
}

```
从配置我们可以看到使用upstream定义了backend组，并在后续的server配置中引用，放在`proxy_pass`指令后面并添加对应的协议，注意在定义upstream时，其中server的地址不需要指明协议。这样就快速实现多台服务器提供服务的效果，默认是轮询算法，权重默认都为1。
upstream中的server的属性，我们也可以灵活配置，包括轮询算法、server权重等属性。

## 4. server的属性配置
* weight: 指定server的权重，默认为1
* max_fails: 容错处理，配置与服务器通信失败达到多少次后判断服务器异常，通信过程中的超时时间由fail_timeout指定，默认是1次，0为禁用，配合proxy_next_upstream, fastcgi_next_upstream, uwsgi_next_upstream, scgi_next_upstream, memcached_next_upstream, 和grpc_next_upstream等指令来达到容错尝试。
* fail_timeout: 指定与服务器通信的超时时间。
* 更多配置参数请参考官方文档: http://nginx.org/en/docs/http/ngx_http_upstream_module.html

## 5. 负载均衡算法
* hash: 配置格式为 hash key [consistent]; 配置上下文为upstream。  
该指定为服务器组指定基于hash的负载平衡方法，在服务器组中，客户端与服务器映射关系基于散列键key。key可以包含文本，变量及其两者组合。请注意，从组中添加或删除服务器可能会导致将大多数keys重新映射到其他服务器。  
但是如果指定了consistent参数，则会使用ketama一致性哈希算法。 该方法可确保在将服务器添加到组中或从组中删除服务器时，只有很少的key被重新映射到不同的服务器。 这有助于为缓存服务器实现更高的缓存命中率。
* ip_hash: 配置格式为 ip_hash; 配置上下文为upstream。   
ip_hash负载均衡算法，在该算法中，请求将基于客户端IP地址在服务器之间分配。客户端IPv4地址的前三个八位位组或整个IPv6地址用作哈希密钥。 除非对应服务器不可用，该算法确保了来自同一客户端的请求将始终传递到同一服务器。 在对应的服务器不可用时，客户端请求将传递到另一台服务器。一般情况下，同一客户端的请求将永远是同一台服务器。 
ipv6在1.3.2和1.2.2开始支持。  
如果想将server标识为不可用，需要在server后加down参数。  
在1.3.1和1.2.2版本之前，无法使用ip_hash负载平衡方法为服务器指定权重。   
* least_conn: 配置格式为 least_conn; 配置上下文为upstream。   
该指令出现在版本1.3.1和1.2.2中。  
指定组应使用least_conn负载平衡算法，该算法将请求传递到活动连接数最少的服务器，同时考虑服务器的权重。 如果有多个这样的服务器，则依次使用加权循环平衡方法进行尝试。  
* random: 配置格式为 random [two [method]]; 配置上下文为upstream。  
指定组应使用random负载平衡算法，该算法将请求传递到随机选择的服务器，同时考虑服务器的权重。  
可选的two参数指示nginx可以随机选择两个服务器，然后使用指定的method选择一个服务器。 默认方法是least_conn，它将请求传递给活动连接数最少的服务器。  

## 6. 模块的有用的内置变量
```shell
# ngx_http_upstream_module模块
1. $upstream_cache_status: 保存访问响应缓存（0.8.3）的命中状态。 状态可以是"MISS", "BYPASS", "EXPIRED", "STALE", "UPDATING", "REVALIDATED", "HIT"。
2. $upstream_connect_time: 保存与上游服务器建立连接（1.9.1）时间； 时间以毫秒为分辨率的秒为单位。 对于SSL，包括握手所花费的时间。 几个连接的时间之间用逗号和冒号分隔，例如$upstream_addr变量中的地址。  
3. $upstream_response_time: 保存从上游服务器接收响应的时间；时间以毫秒为分辨率的秒为单位。 多个响应的时间由逗号和冒号分隔，例如$upstream_addr变量中的地址。

# ngx_http_proxy_module模块
1. $proxy_add_x_forwarded_for: 该变量保存"X-Forwarded-For"和$remote_addr变量的值，以逗号分隔。如果客户端请求标头中不存在"X-Forwarded-For"字段，则$proxy_add_x_forwarded_for变量值等于$remote_addr变量的值。


```

## 7. 总结
依赖`ngx_http_proxy_module`和`ngx_http_upstream_module`等模块，nginx实现了强大的反向代理功能，利用此特性，我们可以实现服务的水平扩展，从而更从容的应对大流量。所以应该好好学习nginx的反向代理功能，更好的服务于我们的业务。
