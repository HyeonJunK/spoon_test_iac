#!/bin/bash

yum update

yum install docker -y

service docker start

usermod -a -G docker ec2-user
chkconfig docker on
pip3 install docker-compose

cat <<EOF >/home/ec2-user/docker-compose.yml
nginx:
  image: nginx
  ports:
    - "80:80"
EOF

chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml
/usr/local/bin/docker-compose -f /home/ec2-user/docker-compose.yml up -d
