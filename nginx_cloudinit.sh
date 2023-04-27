#!/bin/bash
sudo su
yum install nginx -y
systemctl enable --now nginx.service
firewall-cmd --add-service=http --permanent
firewall-cmd --reload
setsebool -P httpd_can_network_relay 1

mkdir /srv
mkdir /srv/website

cat << EOF | sudo tee /srv/website/index.html
<html>
<head>
<title>Hello</title>
</head>
<body><p>Hello World!</p></body>
</html>
EOF

sudo chown -R nginx:nginx /srv/website
sudo chcon -Rt httpd_sys_content_t /srv/website

cat <<EOF | sudo tee /etc/nginx/conf.d/default.conf
server {
  server_name    _;
  root           /srv/website;
  index          index.html;
location /orcl/ {
  proxy_buffer_size    256k;
  proxy_buffers     32 256k;
  
  proxy_pass https://www.oracle.com/;
  #proxy_redirect https://login.oracle.com/ http://_/;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header   X-Forwarded-Proto $scheme;
}
}
EOF

systemctl restart nginx


