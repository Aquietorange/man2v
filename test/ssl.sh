#!/bin/bash
#输出当前脚本所在目录
openssl genrsa -out v2ray.key 2048
openssl req -new -key v2ray.key -out v2ray.csr -subj "/C=US/ST=NEYO/L=NEYO/O=LTC/OU=LTC/CN=googlegame.xyz/emailAddress="
openssl x509 -req -sha256 -days 3650 -in v2ray.csr -signkey v2ray.key -out v2ray.crt