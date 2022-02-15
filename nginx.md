


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
