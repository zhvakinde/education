


#### вывод nginx -V с lb1 / lb2
```
user@lb1:/opt$ nginx -V
nginx version: nginx/1.18.0 (Ubuntu)
built with OpenSSL 1.1.1f  31 Mar 2020
TLS SNI support enabled
configure arguments: --with-cc-opt='-g -O2 -fdebug-prefix-map=/opt/nginx-1.18.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-compat --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --add-module=/opt/nginx_upstream_check_module/ --with-http_addition_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_xslt_module=dynamic --with-stream=dynamic --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module

user@lb2:/opt$ nginx -V
nginx version: nginx/1.18.0 (Ubuntu)
built with OpenSSL 1.1.1f  31 Mar 2020
TLS SNI support enabled
configure arguments: --with-cc-opt='-g -O2 -fdebug-prefix-map=/opt/nginx-1.18.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-compat --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --add-module=/opt/nginx_upstream_check_module/ --with-http_addition_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_xslt_module=dynamic --with-stream=dynamic --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module
```

#### Kонфигурация nginx lb1
```
upstream backend {
server app1.e20e5182391bea02c50f4552250057a2.kis.im;
server app2.e20e5182391bea02c50f4552250057a2.kis.im;
  check interval=3000 rise=2 fall=5 timeout=1000 type=http;
  check_http_send "GET /index.html HTTP/1.0\r\n\r\n";
  check_http_expect_alive http_2xx http_3xx;
}
server {
  listen 80;
  server_name app.e20e5182391bea02c50f4552250057a2.kis.im;

  location /.well-known {
    root /opt/www/acme;
  }

  location / {
  return 301 https://app.e20e5182391bea02c50f4552250057a2.kis.im$request_uri;
  }
}

server { 
listen 443 ssl;
server_name  app.e20e5182391bea02c50f4552250057a2.kis.im;
  ssl_certificate /etc/letsencrypt/live/app.e20e5182391bea02c50f4552250057a2.kis.im/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/app.e20e5182391bea02c50f4552250057a2.kis.im/privkey.pem;

location / {
 proxy_pass http://backend;
 proxy_set_header X-Forwarded-For $remote_addr;
}

}
```
#### Kонфигурация nginx lb2
```
upstream backend {
server app1.e20e5182391bea02c50f4552250057a2.kis.im;
server app2.e20e5182391bea02c50f4552250057a2.kis.im;
  check interval=3000 rise=2 fall=5 timeout=1000 type=http;
  check_http_send "GET /index.html HTTP/1.0\r\n\r\n";
  check_http_expect_alive http_2xx http_3xx;
}


server {
  listen 80;
  server_name app.e20e5182391bea02c50f4552250057a2.kis.im;

  location /.well-known {
    proxy_pass http://lb1.e20e5182391bea02c50f4552250057a2.kis.im/.well-known;
  }

    location / {
  return 301 https://app.e20e5182391bea02c50f4552250057a2.kis.im$request_uri;
  }
}

server { 
listen 443 ssl;
server_name  app.e20e5182391bea02c50f4552250057a2.kis.im;
  ssl_certificate /etc/letsencrypt/live/app.e20e5182391bea02c50f4552250057a2.kis.im/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/app.e20e5182391bea02c50f4552250057a2.kis.im/privkey.pem;

location / {
 proxy_pass http://backend;
 proxy_set_header X-Forwarded-For $remote_addr;
}

}
```
#### nginx.conf с lb1 / lb2
```
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;

}

http {

        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        
        log_format exporter '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent "$http_referer" '
                       '"$http_user_agent" "$http_x_forwarded_for" '
                       '$upstream_response_time $request_time';

        access_log /var/log/nginx/access.log;
        access_log /var/log/nginx/access.log exporter ;
        error_log /var/log/nginx/error.log;

        gzip on;

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}
```
#### Kонфигурация nginx c app1 / app2
```
server {
  listen 80;
  server_name app.e20e5182391bea02c50f4552250057a2.kis.im;



  location / {
  proxy_pass http://127.0.0.1:8080;
  set_real_ip_from 164.92.228.134;
  set_real_ip_from 167.71.63.103;
  real_ip_header    X-Forwarded-For;
 
  }
}
```
#### nginx.conf с app1 / app2
```
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;

}

http {

        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        log_format time "$request $request_time $upstream_response_time";

        access_log /var/log/nginx/access.log;
        access_log /var/log/nginx/access.log time;
        error_log /var/log/nginx/error.log;

        gzip on;

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}
```
#### конфигурацию nginxlog-exporter с lb1 / lb2
```
listen {
  port = 4040
}

namespace "nginx" {
  source = {
    files = [
      "/var/log/nginx/access.log"
    ]
  }

 format = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" \"$http_x_forwarded_for\" $upstream_response_time $request_time"

  labels {
    app = "default"
  }
}
```
#### Пояснение о том, как получил SSL сертификат на два балансировщика
на сервере lb1 установлен letsencrypt  и настроен нжинкс для полунеия сертификата
на сервере lb2 настроенно проксирование на lb 1
```
  location /.well-known {
    proxy_pass http://lb1.e20e5182391bea02c50f4552250057a2.kis.im/.well-known;
  }
 ```
 на сервере lb1 настроенна утилита Lsyncd для синхронизации содержимого каталога /etc/letsencrypt на сервер lb2 через ssh с использованием аутификации через ключи ( Lsyncd позволяет отслеживать состояние каталога с помощью подсистемы ядра inotify, и при помощи утилиты синхронизации rsync, менять содержимое другого каталога, таким образом, приводя оба каталога к единому виду.)
 
lsyncd.conf.lua
 ```
  sync {
    default.rsyncssh,
    source = "/etc/letsencrypt",
    host = "user@167.71.63.103",
    targetdir = "/etc/letsencrypt",
    rsync = {
        _extra = { "-a" }
    }
}
 ```
 #### ответ от сервера
 ```
 [root@cnt 22.DNS]# curl -D - -s https://app.e20e5182391bea02c50f4552250057a2.kis.im
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Sun, 13 Feb 2022 12:51:52 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 299
Connection: keep-alive

Hostname: app1
IP: 127.0.0.1
IP: ::1
IP: 167.71.43.213
IP: 10.19.0.8
IP: fe80::9c65:7ff:fe71:b1a1
IP: 10.114.0.5
IP: fe80::dcee:59ff:fede:f6d2
RemoteAddr: 127.0.0.1:58886
GET / HTTP/1.1
Host: 127.0.0.1:8080
User-Agent: curl/7.29.0
Accept: */*
Connection: close
X-Forwarded-For: 5.142.119.54
 ```
 #####  access логи lb1
 ```
 5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.004 0.003
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.004 0.004
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.003
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.002
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.002
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.001
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.002
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.002
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.003
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.002
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.003
 ```
  #####  access логи lb2
   ```
   5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.004
5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.004 0.003
5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.003
5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.002
5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:27 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.003
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.002
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.003
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.003
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.004 0.003
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET / HTTP/1.1" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.003
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET /favicon.ico HTTP/1.1" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50" "-" 0.000 0.002
45.146.165.37 - - [13/Feb/2022:12:03:12 +0000] "GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 200 551 "http://164.92.228.134:80/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36"
45.146.165.37 - - [13/Feb/2022:12:03:12 +0000] "GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 200 551 "http://164.92.228.134:80/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36" "-" 0.000 0.005
88.249.232.123 - - [13/Feb/2022:12:04:53 +0000] "GET / HTTP/1.0" 301 178 "-" "-"
88.249.232.123 - - [13/Feb/2022:12:04:53 +0000] "GET / HTTP/1.0" 301 178 "-" "-" "-" - 0.000
133.242.174.119 - - [13/Feb/2022:12:16:02 +0000] "GET / HTTP/1.1" 200 497 "-" "Mozilla/5.0 (Linux; U; Android 2.2; ja-jp; SC-02B Build/FROYO) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
133.242.174.119 - - [13/Feb/2022:12:16:02 +0000] "GET / HTTP/1.1" 200 497 "-" "Mozilla/5.0 (Linux; U; Android 2.2; ja-jp; SC-02B Build/FROYO) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1" "-" 0.004 0.005
45.146.165.37 - - [13/Feb/2022:12:17:23 +0000] "GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 301 178 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36"
45.146.165.37 - - [13/Feb/2022:12:17:23 +0000] "GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 301 178 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36" "-" - 0.033
34.244.75.140 - - [13/Feb/2022:12:31:10 +0000] "GET /favicon.ico HTTP/1.1" 200 458 "yahoo.com" "Mozilla/5.0 (X11; Linux x86_64; rv:83.0) Gecko/20100101 Firefox/83.0"
34.244.75.140 - - [13/Feb/2022:12:31:10 +0000] "GET /favicon.ico HTTP/1.1" 200 458 "yahoo.com" "Mozilla/5.0 (X11; Linux x86_64; rv:83.0) Gecko/20100101 Firefox/83.0" "-" 0.000 0.004
 ```
   #####  access логи app1
 ```
5.142.119.54 - - [13/Feb/2022:12:37:50 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.004
5.142.119.54 - - [13/Feb/2022:12:37:50 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:51 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:53 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:53 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:53 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:55 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.000 0.000
5.142.119.54 - - [13/Feb/2022:12:37:55 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.004
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET /favicon.ico HTTP/1.0" 200 841 "https://app.e20e5182391bea02c50f4552250057a2.kis.im/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET /favicon.ico HTTP/1.0 0.001 0.000
 ```
   #####  access логи app1
 ```
 5.142.119.54 - - [13/Feb/2022:11:56:28 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
170.210.45.163 - - [13/Feb/2022:11:57:04 +0000] "GET /currentsetting.htm HTTP/1.0" 200 437 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36"
GET /currentsetting.htm HTTP/1.0 0.001 0.000
31.210.20.202 - - [13/Feb/2022:11:57:23 +0000] "GET / HTTP/1.1" 200 263 "-" "-"
GET / HTTP/1.1 0.001 0.000
45.146.165.37 - - [13/Feb/2022:12:03:12 +0000] "GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.0" 200 551 "http://164.92.228.134:80/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36"
GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.0 0.000 0.004
5.32.176.105 - - [13/Feb/2022:12:07:20 +0000] "GET / HTTP/1.1" 200 355 "-" "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"
GET / HTTP/1.1 0.001 0.000
133.242.140.127 - - [13/Feb/2022:12:16:02 +0000] "GET / HTTP/1.0" 200 498 "-" "Mozilla/5.0 (Linux; U; Android 2.2; ja-jp; SC-02B Build/FROYO) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
GET / HTTP/1.0 0.001 0.000
45.146.165.37 - - [13/Feb/2022:12:17:33 +0000] "GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.0" 200 550 "http://167.71.63.103:80/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36"
GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.0 0.001 0.000
45.146.165.37 - - [13/Feb/2022:12:27:25 +0000] "GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 200 472 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36"
GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1 0.032 0.000
34.244.75.140 - - [13/Feb/2022:12:31:10 +0000] "GET / HTTP/1.0" 200 452 "www.google.com" "Mozilla/5.0 (X11; Linux x86_64; rv:83.0) Gecko/20100101 Firefox/83.0"
GET / HTTP/1.0 0.001 0.000
34.244.75.140 - - [13/Feb/2022:12:31:10 +0000] "GET /favicon.ico HTTP/1.0" 200 458 "yahoo.com" "Mozilla/5.0 (X11; Linux x86_64; rv:83.0) Gecko/20100101 Firefox/83.0"
GET /favicon.ico HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:50 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:50 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.000 0.000
5.142.119.54 - - [13/Feb/2022:12:37:50 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:51 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.000 0.000
5.142.119.54 - - [13/Feb/2022:12:37:53 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:53 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:53 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.000 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.000 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:54 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.000 0.000
5.142.119.54 - - [13/Feb/2022:12:37:55 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:37:55 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.000 0.000
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:28 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
5.142.119.54 - - [13/Feb/2022:12:38:29 +0000] "GET / HTTP/1.0" 200 912 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36 Edg/98.0.1108.50"
GET / HTTP/1.0 0.001 0.000
  ```
