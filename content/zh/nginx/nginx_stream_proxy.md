+++
title = "Nginx系列之nginx四层反向代理"
weight = 7 
+++

> 上集说到nginx的http七层代理，其实它工作在OSI七层模型的应用层。由于其可以解析http协议，我们可以根据URI进行请求的分发，具有很大的灵活性，但是协议的解析存在性能的消耗。为了能获取更高的代理性能，nginx支持了四层代理，即传输层，就是我们常说的TCP/UDP层，没有协议解析，就是简单的TCP/UDP转发，代理性能突飞猛进，该功能依赖于ngx_http_upstream_module和ngx_stream_upstream_module，互联网公司将其作为入口代理来工作。

## 1. nginx配置 

```shell
# nginx.conf

worker_processes auto;

error_log /var/log/nginx/error.log info;

events {
    worker_connections  1024;
}

stream {
    # 定义backend组
    upstream backend {
        # 指定负载均衡算法，这里是一致性hash算法，以$remote_addr作为hash的键.
        hash $remote_addr consistent;

        server backend1.example.com:12345 weight=5;
        server 127.0.0.1:12345            max_fails=3 fail_timeout=30s;
        server unix:/tmp/backend3;
    }

    # 定义dns组
    upstream dns {
       server 192.168.0.1:53535;
       server dns.example.com:53;
    }

    server {
        # 指定监听的端口，tcp/udp
        listen 12345;
        proxy_connect_timeout 1s;
        proxy_timeout 3s;
        # 代理至backend服务器组
        proxy_pass backend;
    }

    server {
        # 指定监听的端口，tcp/udp
        listen 127.0.0.1:53 udp reuseport;
        proxy_timeout 20s;
        # 代理至dns服务器组
        proxy_pass dns;
    }

    server {
        # 指定监听的端口，tcp/udp
        listen [::1]:12345;
        # 指定代理至本地socket文件
        proxy_pass unix:/tmp/stream.socket;
    }
}
```
经过以上简单的配置，nginx -s reload后，nginx即可作为四层反向代理服务器。这段配置的关键在于server配置端，指定监听的端口，`proxy_pass`来指定上游服务器或上游服务器组。与七层代理的配置区别主要在于http-->stream，没有localctation配置，直接监听端口，将端口的流量直接进行转发。

## 2. 上游服务器组的实现
在如今的流量为王的时代，单机以及远远不能满足性能要求，这就需要我们在上游服务中提供多台服务器，形成服务器组。共同来提供服务，并可以采用不同的负载均衡算法，更加灵活与可扩展。而做到这些需要依赖`ngx_stream_upstream_module`模块。
示例:
```shell
http {

    upstream backend {
        # 配置负载均衡算法
        hash $remote_addr consistent;
        server backend1.example.com       weight=5;
        server backend2.example.com:8080;
        server unix:/tmp/backend3;

        server backup1.example.com:8080   backup;
        server backup2.example.com:8080   backup;

    }

    server {
        listen 80;
        proxy_timeout 20s;
        # 代理至dns服务器组
        proxy_pass dns;
        proxy_pass http://backend;
    }
}

```
从配置我们可以看到使用upstream定义了backend组，并在后续的server配置中引用，放在`proxy_pass`指令后面。这样就快速实现多台服务器提供服务的效果，默认是轮询算法，权重默认都为1;   

代理过程属性超时控制:  
* proxy_connect_timeout: 指定与上游服务器建立连接的超时时间，默认为60s，配置上下文stream和server。
* proxy_timeout: 设置客户端或代理服务器连接上两次连续的读取或写入操作之间的超时。 如果在此时间内没有数据传输，则连接将关闭。默认10m，配置上下文stream和server。  

容错相关的配置:  
* proxy_next_upstream: 如果无法建立与代理服务器的连接，决定是否将客户端连接传递给下一个服务器。配置上下文stream和server；默认开启;   
* proxy_next_upstream_timeout: 限制允许将连接传递到下一台服务器的时间，配置上下文stream和server；默认关闭; 
* proxy_next_upstream_tries: 限制将连接传递到下一个服务器的可能尝试次数，配置上下文stream和server，默认关闭;   

限速相关的配置:    
* proxy_download_rate：限制从代理服务器读取数据的速度。单位为bytes/s。默认为0，即关闭速率限制。该限制是针对每个连接设置的，因此，如果nginx同时打开与代理服务器的两个连接，则总速率会是指定限制的两倍。从nginx1.17.0开始，该指令后可以包含变量, 配置上下文stream和server。 
* proxy_upload_rate：限制从代理服务器读取数据的速度。单位为bytes/s。默认为0，即关闭速率限制。该限制是针对每个连接设置的，因此，如果nginx同时打开与代理服务器的两个连接，则总速率会是指定限制的两倍。从nginx1.17.0开始，该指令后可以包含变量, 配置上下文stream和server。   

upstream中的server的属性，我们也可以灵活配置，包括轮询算法、server权重等属性。  

## 3. server的属性配置
* weight: 指定server的权重，默认为1
* max_fails: 容错处理，配置与服务器通信失败达到多少次后判断服务器异常，通信过程中的超时时间由fail_timeout指定，默认是1次，0为禁用。
* fail_timeout: 指定与服务器通信的超时时间。
* 更多配置参数请参考官方文档: http://nginx.org/en/docs/http/ngx_stream_upstream_module.html

## 4. 负载均衡算法
* hash: 配置格式为 hash key [consistent]; 配置上下文为upstream。  
该指定为服务器组指定基于hash的负载平衡方法，在服务器组中，客户端与服务器映射关系基于散列键key。key可以包含文本，变量及其两者组合。请注意，从组中添加或删除服务器可能会导致将大多数keys重新映射到其他服务器。  
但是如果指定了consistent参数，则会使用ketama一致性哈希算法。 该方法可确保在将服务器添加到组中或从组中删除服务器时，只有很少的key被重新映射到不同的服务器。 这有助于为缓存服务器实现更高的缓存命中率。
* least_conn: 配置格式为 least_conn; 配置上下文为upstream。   
指定组应使用least_conn负载平衡算法，该算法将请求传递到活动连接数最少的服务器，同时考虑服务器的权重。 如果有多个这样的服务器，则依次使用加权循环平衡方法进行尝试。  
* random: 配置格式为 random [two [method]]; 配置上下文为upstream。  
指定组应使用random负载平衡算法，该算法将请求传递到随机选择的服务器，同时考虑服务器的权重。  
可选的two参数指示nginx可以随机选择两个服务器，然后使用指定的method选择一个服务器。 默认方法是least_conn，它将请求传递给活动连接数最少的服务器。  

## 5. 模块的有用的内置变量
```shell
1. $status: 会话的处理状态码: 200、400、403、500、502、503。具体含义可参考http://nginx.org/en/docs/stream/ngx_stream_core_module.html;
2. $remote_addr：客户端地址;
3. $server_addr： 接受连接的服务器的地址;
```

## 6. 总结
依赖`ngx_stream_proxy_module`和`ngx_stream_upstream_module`等模块，nginx实现了强大的四层反向代理功能。相较于七层反向代理，性能更高。但是对于业务的请求分发，灵活性比较低，所以nginx的四层和七层代理我们要根据自己的要求灵活使用，让nginx发挥最大的作用。

