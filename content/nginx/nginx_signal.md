+++
title = "Nginx系列之nginx信号控制"
weight = 4 
+++

> 我们已经学会了nginx的简单配置，并且nginx已正常运行，但是在业务中，配置文件不会是一成不变的，我们经常会根据不同的业务需求来对nginx进行修改，修改之后如何才能生效呢？其实可以通过以下两种方式进行控制，接下来就让我来帮你解答一下吧： 

## 1. nginx命令控制 

注意: 此种方式依赖nginx的pid文件。如果你另外配置了nginx的pid的文件的位置，则会导致命令执行失败。报错信息为：
```shell
nginx: [error] open() "/run/nginx.pid" failed (2: No such file or directory)
由报错信息可知，默认是从/run/nginx.pid来读取的。
```
nginx的行为控制是通过-s参数来制定的，支持的值列表：
1. stop 快速停止
2. quit 优雅停止
3. reload 重载配置文件
4. reopen 滚动日志文件
我们可以看到有两种停止nginx的方式，stop和quit，这两种的区别在于stop不关心请求是否处理完成，直接退出，而quit就会等请求处理完毕后才退出，所以推荐使用quit。体验更好。

命令实操:
```shell
nginx -s quit
优雅停止nginx，nginx会等待所有请求处理完毕后才停止;

nginx -s stop
快速停止nginx，不等待请求是否处理完毕;

nginx -s reload
配置文件修改后，需要reload后，nginx才会加载新的配置。当执行此命令时，nginx会检查配置文件的语法并尝试使用新的配置，如果成功，nginx将会以新的配置启动新的工作进程，并向旧的工作进程发送关闭信号，否则的话，主进程回滚更改并继续使用旧的配置和旧的工作进程。当旧进程收到关闭信号后，它将会停止接受新的请求，并在处理完旧请求的自行退出。

nginx -s reopen
滚动日志，这在我们的日志文件过大时，我们将日志文件mv后，发现日志文件仍在写入，这是由于mv后的文件inode相关信息不变，进行还会将日志写入到该文件中。这时我们就可以执行reopen操作，nginx就会关闭原来的句柄，在配置的日志目录下重新创建新的日志文件来进行日志记录。
```

## kill命令控制 
说到kill命令，它是在linux系统中，通过进程pid向进程发送信号的。我们可以通过kill向nginx的master进程发送特定的信号来进行对nginx的控制。至于nginx的master的pid，我们可以通过pid文件获取，也可以用ps和grep命令过滤即可。

nginx主进程支持的信号:

1. TERM, INT      作用和nginx -s stop一致; 
2. QUIT           作用和nginx -s quit一致; 
3. HUP            作用和nginx -s reload一致 
4. USR1           作用和nginx -s reopen一致; 
5. USR2           平滑升级nginx，这个我们以后有文章专门介绍; 
6. WINCH          平滑关闭工作进程; 

nginx工作进程支持的信号:

1. TERM, INT      快速停止	
2. QUIT           优雅停止	
3. USR1           重新开启新的日志文件	
4. WINCH	      异常终止调试(需要启用debug_points选项)

命令实践:
```shell
kill命令的使用格式： kill -信号名称  pid
# 获取nginx master进程的pid
pid=`ps auxf | grep "nginx: master"|grep -v grep|awk '{print $2}'`
# 优雅停止
kill -QUIT $pid
```

## nginx配置文件检查
```shell
# 在重启或者重载配置文件前需要检查nginx配置的正确性
nginx -c /path/to/nginx.conf -t

# 正常输出示例
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

# 异常输出示例
nginx: [emerg] unknown directive "eerror_log" in /etc/nginx/nginx.conf:3
nginx: configuration file /etc/nginx/nginx.conf test failed
```

## 总结
nginx的程序控制是在工作中经常执行的操作，这就需要我们灵活使用。在配置文件修改后，都需要进行配置文件检查，来保证nginx程序的正常运行，希望同学们多加练习，熟练掌握。
