#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#拔号上网脚本
poff dsl-provider
sleep 3
echo $?
pon dsl-provider
sleep 3
echo $?
ip route add default dev ppp0
sleep 1
echo $?
echo plog