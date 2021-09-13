#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#输出当前脚本所在目录
echo $(dirname $0)

#Linux pwd（英文全拼：print work directory） 命令用于显示工作目录。
#执行 pwd 指令可立刻得知您目前所在的工作目录的绝对路径名称。
echo  $(pwd)

#home是用户地主目录，登录后缺省进入的目录
echo $HOME

#输出当前文件夹容量信息
echo $(df /)


#“|”将两个命令隔开，管道符左边命令的输出就会作为管道符右边命令的输入。连续使用管道意味着第一个命令的输出会作为 第二个命令的输入，第二个命令的输出又会作为第三个命令的输入，依此类推。
#取磁盘根分区剩余空间

# awk  输出包含 "/" 的行，中的第4项
echo $(df / | awk '/\//{print $4}')

#检测文件是否是普通文件（既不是目录，也不是设备文件），如果是，则返回 true。	[ -f $file ] 返回 true。
if [ -f 'test2.sh' ]
then
    echo "test2.sh是普通文件"
else
     echo "test2.sh不是是普通文件"
fi

#如果/v2man/1.txt 文件存在，则 将 v2man/1.txt 文件 移动到  /v2man/test/1.txt
[ -f "/root/go_demo/v2man/1.txt" ] && mv /root/go_demo/v2man/1.txt /root/go_demo/v2man/test/1.txt

random_num=$((RANDOM%12+4))
num2=$[RANDOM%100+1]
echo "取随机数1:"$random_num
echo "取随机数2:"$num2
#$[] 和 $(())  执行效果一样
#它们是一样的，都是进行数学运算的。支持+ - * / %：分别为 “加、减、乘、除、取模”。但是注意，bash只能作整数运算，对于浮点数是当作字符串处理的。

#head 命令可用于查看文件的开头部分的内容，有一个常用的参数 -n 用于显示行数，默认为 10，即显示 10 行的内容。
# -q 隐藏文件名
# -v 显示文件名
# -c <数目> 显示的字节数。
# -n <行数> 显示的行数。
echo $(head -n 3 $(dirname $0)/1.txt)

#/dev/random和/dev/urandom是Linux系统中提供的随机伪设备，这两个设备的任务，是提供永不为空的随机字节数据流。很多解密程序与安全应用程序（如SSH Keys,SSL Keys等）需要它们提供的随机数据流。

#md5sum命令用于生成和校验文件的md5值


echo $random_num

#从伪随机数据流 读前10行 用于 生成MD5 ，并读取md5 的前 random_num 位字符
echo 生成随机路径： "/$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})/"

#在当前目录中1.txt 文件中包含 test 字符串的所在行，并打印出该字符串的行。此时，可以使用如下命令：
echo 查找文件中包含test字符的所在行内容： $(grep test $(dirname $0)/1.txt) 

#查看CPU型号、个数、核心数、逻辑CPU个数
#查看逻辑CPU个数processor  | wc -l 计算输入的行数
#grep 'processor' /proc/cpuinfo | wc -l

#sort 可针对文本文件的内容，以行为单位来排序。(默认的方式将文本文件的第一列以 ASCII 码的次序排列)
#   -u 意味着是唯一的(unique)，输出的结果是去完重了的。


#输出CPU 逻辑核心数
echo CPU逻辑核心数$(grep 'processor' /proc/cpuinfo | sort -u |wc -l ) 


#/etc/os-release 与 /usr/lib/os-release 文件包含了 操作系统识别数据。http://www.jinbuguo.com/systemd/os-release.html
#os-release 文件的基本格式是 一系列换行符分隔的 VAR=VALUE 行(每行一个变量)， 可以直接嵌入到 shell 脚本中使用。

#加载 操作系统识别数据 脚本后，可直接 使用以下变量
source '/etc/os-release'

#-----------cat /etc/os-release------
#PRETTY_NAME="Debian GNU/Linux 10 (buster)"
#NAME="Debian GNU/Linux"
#VERSION_ID="10"
#VERSION="10 (buster)"
#VERSION_CODENAME=buster
#ID=debian
#HOME_URL="https://www.debian.org/"
#SUPPORT_URL="https://www.debian.org/support"
#BUG_REPORT_URL="https://bugs.debian.org/"
#----------------

#系统发行版名称
echo 系统发行版名称：$PRETTY_NAME

#操作系统版本号
echo 操作系统版本号: $VERSION_ID

 #使用多个分隔符 先使用 ( 分割，然后对分割结果再使用 ) 分割
 # awk -F '[()]'  '{print $1,$2,$5}'   log.txt

#从VERSION中提取发行版系统的英文名称，为了在debian/ubuntu下添加相对应的Nginx apt源
echo ${VERSION}
VERSION=$(echo "${VERSION}" | awk -F "[()]" '{print $2}')
echo 发行版系统的英文名称:$VERSION

echo AWK命令演示： "adgfbbag(dd,f)bbb" | awk -F "[(),]" '{print $1 , $2 , $3 ,$4}'



#从脚本文件中 读取 版本号
echo   $( head -100  $(pwd)/install.sh  | grep "shell_version=" | head -1 | awk -F '=|"' '{print $3}' ) 

shell_version="shell_version=\"1.1.8.4\""
ol_version=$( echo $shell_version | awk -F '=|"' '{print $3}')
shell_version="1.1.8.3"

version_cmp="/tmp/version_cmp.tmp"

#command > file	将输出重定向到 file, file原内容会被清空
echo $ol_version >$version_cmp

#command >> file	将输出以追加的方式重定向到 file。
echo $shell_version >>$version_cmp


#输出内容 显示换行符 需要 使用 -e 开启转义，并使用 “”包围命令
echo -e "version_cmp:\n$(cat $version_cmp)"

echo "-----------"

#-r 以相反的顺序来排序。 -V, 在文本内进行自然版本排序 ,即 版本号 从大到小排序
echo -e  "$(sort -Vr $version_cmp | head -1 )"

if [[ $shell_version  <  "$(sort -Vr $version_cmp | head -1 )" ]]
then
    echo "发现最新版本："$ol_version
else
    echo "当前版本为最新版本:"$shell_version 
fi

#read -r  update_confirm
#case $update_confirm in 
#[yY][eE][sS] |[yY])
#    echo "输入yes"
#    ;;
#    *)
#    echo "输入no"
#    ;;
#esac

#wget
# -no-check-certificate  “不检查HTTPS证书”
# wget -N --no-check-certificate https://raw.githubusercontent.com/wulabing/V2Ray_ws-tls_bash_onekey/${github_branch}/install.sh
#用于从网络上下载资源，没有指定目录，下载资源回默认为当前目录。wget 虽然功能强大，但是使用起来还是比较简单


# fonts colos  字体颜色

readColor="\033[31m"
GreenColor="\033[32m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"

Font="\033[0m"
echo -e "a${readColor}bb${Font}dddd"
echo -e "a${GreenColor}ddddddddddd${Font}dddd"

#grep -q  用于if逻辑判断
#安静模式，不打印任何标准输出。如果有匹配的内容则立即返回状态值0。

v2ray_qr_config_file="/usr/local/vmess_qr.json"
v2ray_bin_dir="/usr/local/bin/v2ray"

#判断是否已安装V2ray
if [ -f $v2ray_bin_dir ]
    then
    if grep -q "ws" $v2ray_qr_config_file; then
            shell_mode="ws"
        elif grep -q "h2" $v2ray_qr_config_file; then
            shell_mode="h2"
    fi
    else
        echo "未安装v2ray"
fi    

#内置变量
#内置的环境变量，如HOME， PATH， SHELL， UID，USER，HOSTNAME 等，都是在用户登陆之前就已经被/bin/login程序设置好了。

# $UID  用户ID 数字，0==ROOT
# $USER 当前用户名 

#输出当前内置的环境变量
# env | cat
# 调试时 输出以下内容
#    SHELL=/bin/bash
#    LANGUAGE=zh_CN:zh
#    PWD=/root/go_demo/v2man/test
#    LOGNAME=root
#    XDG_SESSION_TYPE=tty
#    HOME=/root
#    LANG=zh_CN.UTF-8
#    SSH_CONNECTION=192.168.1.3 57892 192.168.1.4 22
#    XDG_SESSION_CLASS=user
#    TERM=xterm
#    USER=root
#    SHLVL=0
#    XDG_SESSION_ID=23
#    XDG_RUNTIME_DIR=/run/user/0
#    SSH_CLIENT=192.168.1.3 57892 22
#    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin
#    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/0/bus
#    MAIL=/var/mail/root
#    SSH_TTY=/dev/pts/0
#    OLDPWD=/root/go_demo/v2man
#    _=/usr/bin/env

#sleep命令可以用来将目前动作延迟一段时间。
#sleep  number  ，number时间长度，后面可接 s(默认可省略)、m、h 或 d
#延时5S执行
#sleep 5s
#sleep 5

chronyc sourcestats -v
chronyc tracking -v
date
read -rp "请确认时间是否准确,误差范围±3分钟(Y/N): " chrony_install

[[ -z ${chrony_install} ]] && chrony_install="Y"
case $chrony_install in
[yY][eE][sS] | [yY])
    echo -e "${GreenBG} 继续安装 ${Font}"
    ;;
*)
    echo -e "${RedBG} 安装终止 ${Font}"
    #exit 2
    ;;
esac

read -a arr -p "输入数组测试,用空格分隔: "
echo "$arr"
echo "${#arr[*]}"
echo "${arr[3]}"

echo $(uname)

version_number() {
    case "$1" in
        'v'*)
            echo "$1"
            ;;
        *)
            echo "v$1"
            ;;
    esac
}

TMP_FILE="$(mktemp)"
        # DO NOT QUOTE THESE `${PROXY}` VARIABLES!
if ! curl -o "$TMP_FILE" 'https://api.github.com/repos/v2fly/v2ray-core/releases/latest'; then
    rm "$TMP_FILE"
    echo 'error: Failed to get release list, please check your network.'
    exit 1
fi
RELEASE_LATEST="$(sed 'y/,/\n/' "$TMP_FILE" | grep 'tag_name' | awk -F '"' '{print $4}')"
echo $RELEASE_LATEST
RELEASE_VERSION="$(version_number "$RELEASE_LATEST")"
echo ${RELEASE_VERSION#v}
