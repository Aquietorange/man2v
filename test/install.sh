#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#fonts color
Green="\033[32m"
Red="\033[31m"
# Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"

shell_mode="None"
shell_version="1.0.0"

#CPU结构
MACHINE=""

#包安装命令
PACKAGE_MANAGEMENT_INSTALL=""

#包移除命令
PACKAGE_MANAGEMENT_REMOVE=""

v2man_path="/usr/local/v2man"
v2man_systemd_file="/etc/systemd/system/v2man.service"
v2ray_systemd_file="/etc/systemd/system/v2ray.service"
nginx_systemd_file="/lib/systemd/system/nginx.service"


v2ray_bin_dir="/usr/local/bin/v2ray"
v2ctl_bin_dir="/usr/local/bin/v2ctl"

v2ray_conf_dir="/etc/v2ray"
nginx_conf_dir="/etc/nginx/conf.d"

v2ray_conf="${v2ray_conf_dir}/config.json"
nginx_conf="${nginx_conf_dir}/v2ray.conf"
nginx_conf_cf="${nginx_conf_dir}/v2ray_cf.conf"
nginx_dir="/etc/nginx"
web_dir="/home/v2wwwroot"

v2ray_qr_config_file="/usr/local/vmess_qr.json"
v2ray_info_file="$HOME/v2ray_info.inf"

#简易随机数
random_num=$((RANDOM%12+4))
#生成伪装路径
camouflage="/$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})/"
THREAD=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)

ssl_update_file="/usr/bin/ssl_update.sh"
amce_sh_file="/root/.acme.sh/acme.sh"


#加载其它脚本
source '/etc/os-release'

#初始化安装命令
identify_the_operating_system_and_architecture() {
    if [[ "$(uname)" == 'Linux' ]]; then
        case "$(uname -m)" in
            'i386' | 'i686')
                MACHINE='32'
                ;;
            'amd64' | 'x86_64')
                MACHINE='64'
                ;;
            'armv5tel')
                MACHINE='arm32-v5'
                ;;
            'armv6l')
                MACHINE='arm32-v6'
                ;;
            'armv7' | 'armv7l' )
                MACHINE='arm32-v7a'
                ;;
            'armv8' | 'aarch64')
                MACHINE='arm64-v8a'
                ;;
            'mips')
                MACHINE='mips32'
                ;;
            'mipsle')
                MACHINE='mips32le'
                ;;
            'mips64')
                MACHINE='mips64'
                ;;
            'mips64le')
                MACHINE='mips64le'
                ;;
            'ppc64')
                MACHINE='ppc64'
                ;;
            'ppc64le')
                MACHINE='ppc64le'
                ;;
            'riscv64')
                MACHINE='riscv64'
                ;;
            's390x')
                MACHINE='s390x'
                ;;
            *)
                echo "error: The architecture is not supported."
                exit 1
                ;;
        esac
        if [[ ! -f '/etc/os-release' ]]; then
            echo "error: Don't use outdated Linux distributions."
            exit 1
        fi
        if [[ -z "$(ls -l /sbin/init | grep systemd)" ]]; then
            echo "error: Only Linux distributions using systemd are supported."
            exit 1
        fi
        #command命令调用指定的指令并执行，命令执行时不查询shell函数。command命令只能够执行shell内部的命令。
        #当系统内定义了与linux命令相同的函数时，使用command命令忽略shell函数，而执行相应的linux命令。
        #判断 系统 存在 apt 命令
        if [[ "$(command -v apt)" ]]; then
            PACKAGE_MANAGEMENT_INSTALL='apt install -y'
            PACKAGE_MANAGEMENT_REMOVE='apt remove'
        elif [[ "$(command -v yum)" ]]; then
            PACKAGE_MANAGEMENT_INSTALL='yum install'
            PACKAGE_MANAGEMENT_REMOVE='yum remove'
            if [[ "$(command -v dnf)" ]]; then
                PACKAGE_MANAGEMENT_INSTALL='dnf install'
                PACKAGE_MANAGEMENT_REMOVE='dnf remove'
            fi
        elif [[ "$(command -v zypper)" ]]; then
            PACKAGE_MANAGEMENT_INSTALL='zypper install'
            PACKAGE_MANAGEMENT_REMOVE='zypper remove'
        else
            echo "error: The script does not support the package manager in this operating system."
            exit 1
        fi
    else
        echo "error: This operating system is not supported."
        exit 1
    fi
}

install_software() {
    COMPONENT="$1"
    if [[ -n "$(command -v "$COMPONENT")" ]]; then
        return
    fi
    ${PACKAGE_MANAGEMENT_INSTALL} "$COMPONENT"
    if [[ "$?" -ne '0' ]]; then
        echo "error: Installation of $COMPONENT failed, please check your network."
        exit 1
    fi
    echo "info: $COMPONENT is installed."
}

install_v2man(){
    if [ -f "${v2man_path}/v2man" ];then 
        read -p "v2man已安装,选择 卸载并继续安装(Y),跳过并继续安装(N)"  insy
        case $insy in 
        [Yy])
         remove_v2man
            ;;
         *)
         echo "退出安装"
         return
            ;;
        esac
    fi

     echo "install_v2man"
     TMP_FILE="$(mktemp)"
     install_software wget
     echo "创建临时文件："$TMP_FILE
     if ! wget -O $TMP_FILE --no-check-certificate https://api.github.com/repos/Aquietorange/man2v/releases/latest ; then 
        echo "下载v2man失败"
        rm "$TMP_FILE"
        exit 1
     fi
    RELEASE_LATEST="$(sed 'y/,/\n/' "$TMP_FILE" | grep 'tag_name' | awk -F '"' '{print $4}')"
    rm "$TMP_FILE"
    echo "v2man最新版本："$RELEASE_LATEST
     
    mkdir -p $v2man_path &&   cd "/usr/local/v2man" || exit
    V2man_FILE="${v2man_path}/v2man_$RELEASE_LATEST.tar.gz"
    if [ ! -f $V2man_FILE ] 
    then
        if ! wget -O $V2man_FILE --no-check-certificate "https://github.com/Aquietorange/man2v/releases/download/$RELEASE_LATEST/linux_amd64.tar.gz"; then 
                echo "下载v2man失败"
                exit 1
        fi
    fi
    tar -zxvf $V2man_FILE 
    chmod +x ./v2man
    #安装为服务 和开机启动
    v2man_systemd

}

v2man_systemd(){
    cat >$v2man_systemd_file <<EOF
[Unit]
Description=v2man

[Service]
Type=simple
WorkingDirectory=/usr/local/v2man
ExecStart=/usr/local/v2man/v2man
Restart=always
RestartSec=5
StartLimitInterval=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable v2man
    systemctl start v2man
    echo "设置v2man 开机启动 完成"
}


remove_v2man(){
     echo "开始卸载v2man"
        systemctl stop v2man
        rm  -rf "$v2man_systemd_file"
        rm  -rf "${v2man_path}"
}

nginx_exist_check() {
    if [[ -f "/usr/sbin/nginx" ]]; then
        echo -e "${OK} ${GreenBG} Nginx已存在，跳过编译安装过程 ${Font}"
        sleep 2
    elif [[ -d "/usr/local/nginx/" ]]; then
        echo -e "${OK} ${GreenBG} 检测到其他套件安装的Nginx，继续安装会造成冲突，请处理后安装${Font}"
        exit 1
    else
        nginx_install
    fi
}

nginx_install() {
    install_software nginx
    judge "安装 nginx"
       # 修改基本配置
    sed -i 's/#user  www-data;/user  root;/' ${nginx_dir}/nginx.conf
    #sed -i 's/worker_processes  1;/worker_processes  3;/' ${nginx_dir}/conf/nginx.conf
    #sed -i 's/    worker_connections  1024;/    worker_connections  4096;/' ${nginx_dir}/conf/nginx.conf
    #sed -i '$i include conf.d/*.conf;' ${nginx_dir}/nginx.conf
}
#下载 v2 config.json 到 /etc/v2ray/
v2ray_conf_add_tls() {
    cd /etc/v2ray || exit
    wget --no-check-certificate https://raw.githubusercontent.com/wulabing/V2Ray_ws-tls_bash_onekey/master/tls/config.json -O config.json
    modify_path
    modify_alterid
    modify_inbound_port
    modify_UUID
}

#下载 v2 config.json 到 /etc/v2ray/
v2ray_conf_add() {
    cd /etc/v2ray || exit
  if wget --no-check-certificate "https://raw.githubusercontent.com/wulabing/V2Ray_ws-tls_bash_onekey/master/tls/config.json" -O config_temp.json;then
    #install -m 655 "./config_temp.json" "./config.json"
    mv -f "./config_temp.json" "./config.json"
    else
        echo "下载v2 config.json失败"
  fi
  modify_path
  modify_UUID
}

modify_path() {
    sed -i "/\"path\"/c \\\t  \"path\":\"${camouflage}\"" ${v2ray_conf}
    judge "V2ray 伪装路径 修改"
}
modify_alterid() {
    sed -i "/\"alterId\"/c \\\t  \"alterId\":${alterID}" ${v2ray_conf}
    judge "V2ray alterid 修改"
    [ -f ${v2ray_qr_config_file} ] && sed -i "/\"aid\"/c \\  \"aid\": \"${alterID}\"," ${v2ray_qr_config_file}
    echo -e "${OK} ${GreenBG} alterID:${alterID} ${Font}"
}
modify_inbound_port() {

    if [[ "$shell_mode" != "h2" ]]; then
        PORT=$((RANDOM + 10000))
        sed -i "/\"port\"/c  \    \"port\":${PORT}," ${v2ray_conf}
    else
        sed -i "/\"port\"/c  \    \"port\":${port}," ${v2ray_conf}
    fi
    judge "V2ray inbound_port 修改"
}
modify_UUID() {
    UUID=$(cat /proc/sys/kernel/random/uuid)
    sed -i "/\"id\"/c \\\t  \"id\":\"${UUID}\"," ${v2ray_conf}
    judge "V2ray UUID 修改"
    [ -f ${v2ray_qr_config_file} ] && sed -i "/\"id\"/c \\  \"id\": \"${UUID}\"," ${v2ray_qr_config_file}
    echo -e "${OK} ${GreenBG} UUID:${UUID} ${Font}"
}

nginx_conf_add() {
    touch ${nginx_conf} 
    cat >${nginx_conf} <<EOF
    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        ssl_certificate       /data/v2ray.crt;
        ssl_certificate_key   /data/v2ray.key;
        ssl_protocols         TLSv1.3;
        ssl_ciphers           TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
        server_name           serveraddr.com;
        index index.html index.htm;
        root  /home/v2wwwroot/grammarly;
        error_page 400 = /400.html;

        # Config for 0-RTT in TLSv1.3
        # ssl_early_data on;
        # ssl_stapling on;
        # ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";

        location /ray/
        {
        proxy_redirect off;
        proxy_read_timeout 1200s;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;

        # Config for 0-RTT in TLSv1.3
        # proxy_set_header Early-Data \$ssl_early_data;
        }
}
    server {
        listen 80;
        listen [::]:80;
        server_name serveraddr.com;
        return 301 https://use.shadowsocksr.win\$request_uri;
    }
EOF

    modify_nginx_port
    modify_nginx_other
    judge "Nginx 配置修改"

}

nginx_conf_add_cf() {
    touch ${nginx_conf_cf} 
    cat >${nginx_conf_cf} <<EOF
    server {
        listen 80;
        server_name           serveraddr.com;
        index index.html index.htm;
        root  /home/v2wwwroot/grammarly;
        error_page 400 = /400.html;

        location /ray/
        {
        proxy_redirect off;
        proxy_read_timeout 1200s;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        }
}
EOF

    #modify_nginx_port
    modify_nginx_other_cf
    judge "Nginx cf配置修改"

}
modify_nginx_port() {
    # 找到 ssl http2; 所在行，替换为 tlisten ${port} ssl http2; 并保存
    sed -i "/ssl http2;$/c \\\tlisten ${port} ssl http2;" ${nginx_conf}
   
   # 将第3行，替换为 tlisten [::]:${port} http2;  并保存
    sed -i "3c \\\tlisten [::]:${port} http2;" ${nginx_conf}
    judge "V2ray port 修改"
    [ -f ${v2ray_qr_config_file} ] && sed -i "/\"port\"/c \\  \"port\": \"${port}\"," ${v2ray_qr_config_file}
    echo -e "${OK} ${GreenBG} 端口号:${port} ${Font}"
}
modify_nginx_other() {
    sed -i "/server_name/c \\\tserver_name ${domain};" ${nginx_conf}
    sed -i "/location/c \\\tlocation ${camouflage}" ${nginx_conf}
    sed -i "/proxy_pass/c \\\tproxy_pass http://127.0.0.1:${PORT};" ${nginx_conf}
    sed -i "/return/c \\\treturn 301 https://${domain}\$request_uri;" ${nginx_conf}
    #sed -i "27i \\\tproxy_intercept_errors on;"  ${nginx_dir}/conf/nginx.conf
}
modify_nginx_other_cf() {
    sed -i "/server_name/c \\\tserver_name ${domain};" ${nginx_conf_cf}
    sed -i "/location/c \\\tlocation ${camouflage}" ${nginx_conf_cf}
    sed -i "/proxy_pass/c \\\tproxy_pass http://127.0.0.1:${PORT};" ${nginx_conf_cf}
    #sed -i "27i \\\tproxy_intercept_errors on;"  ${nginx_dir}/conf/nginx.conf
}

#下载一个静态站
web_camouflage() {
    V2man_FILE="/home/v2wwwroot/html.zip"
    if [  -f $V2man_FILE ] 
    then
        echo "站点已安装"
        return
    fi
    rm -rf /home/v2wwwroot
    mkdir -p /home/v2wwwroot
    cd /home/v2wwwroot || exit
    #git clone https://github.com/wulabing/grammarly.git
    if ! wget -O "html.zip" --no-check-certificate "https://github.com/Aquietorange/man2v/releases/download/v1/html.zip"; then 
            echo "html.zip"
            exit 1
    fi
    unzip html.zip
    judge "web 站点伪装"
}

ssl_judge_and_install() {
    if [[ -f "/data/v2ray.key" || -f "/data/v2ray.crt" ]]; then
        echo "/data 目录下证书文件已存在"
        echo -e "${OK} ${GreenBG} 是否删除 [Y/N]? ${Font}"
        read -r ssl_delete
        case $ssl_delete in
        [yY][eE][sS] | [yY])
            rm -rf /data/*
            echo -e "${OK} ${GreenBG} 已删除 ${Font}"
            ;;
        *) ;;

        esac
    fi

    if [[ -f "/data/v2ray.key" || -f "/data/v2ray.crt" ]]; then
        echo "证书文件已存在"
    elif [[ -f "$HOME/.acme.sh/${domain}_ecc/${domain}.key" && -f "$HOME/.acme.sh/${domain}_ecc/${domain}.cer" ]]; then
        echo "证书文件已存在"
        "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /data/v2ray.crt --keypath /data/v2ray.key --ecc
        judge "证书应用"
    else
        echo  "当前目录：$(pwd)"
        ssl_install
        acme
    fi
}

acme() {
    "$HOME"/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force --test; then
        echo -e "${OK} ${GreenBG} SSL 证书测试签发成功，开始正式签发 ${Font}"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        sleep 2
    else
        echo -e "${Error} ${RedBG} SSL 证书测试签发失败 ${Font}"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi

    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
        echo -e "${OK} ${GreenBG} SSL 证书生成成功 ${Font}"
        sleep 2
        mkdir /data
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /data/v2ray.crt --keypath /data/v2ray.key --ecc --force; then
            echo -e "${OK} ${GreenBG} 证书配置成功 ${Font}"
            sleep 2
        fi
    else
        echo -e "${Error} ${RedBG} SSL 证书生成失败 ${Font}"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi
}

ssl_install() {
    if [[ "${ID}" == "centos" ]]; then
        ${INS} install socat nc -y
    else
        install_software socat
        install_software netcat
    fi
    judge "安装 SSL 证书生成脚本依赖"

     if ! wget --no-check-certificate -O acmet.sh "https://get.acme.sh" ;then
        echo "下载get.acme.sh 失败"
        exit
     fi
    sh < acmet.sh
    judge "安装 SSL 证书生成脚本"
}

nginx_systemd() {
    cat >$nginx_systemd_file <<EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx -c ${nginx_dir}/nginx.conf
ExecReload=/usr/sbin/nginx -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

    judge "Nginx systemd ServerFile 添加"
    systemctl daemon-reload
}
vmess_qr_config_tls_ws() {
    cat >$v2ray_qr_config_file <<-EOF
{
  "v": "2",
  "ps": "wulabing_${domain}",
  "add": "${domain}",
  "port": "${port}",
  "id": "${UUID}",
  "aid": "${alterID}",
  "net": "ws",
  "type": "none",
  "host": "${domain}",
  "path": "${camouflage}",
  "tls": "tls"
}
EOF
}
vmess_qr_config_cf_ws() {
    cat >$v2ray_qr_config_file <<-EOF
{
  "v": "2",
  "ps": "wulabing_${domain}",
  "add": "${domain}",
  "port": "443",
  "id": "${UUID}",
  "aid": "${alterID}",
  "net": "ws",
  "type": "none",
  "host": "${domain}",
  "path": "${camouflage}",
  "tls": "tls"
}
EOF
}

info_extraction() {
    #查找 $v2ray_qr_config_file 中 包含 $1 参数的 行， 使用 " 分隔，取出第4个
    grep "$1" $v2ray_qr_config_file | awk -F '"' '{print $4}'
}
basic_information() {
    {
        echo -e "${OK} ${GreenBG} V2ray+ws+tls 安装成功"
        echo -e "${Red} V2ray 配置信息 ${Font}"
        echo -e "${Red} 地址（address）:${Font} $(info_extraction '\"add\"') "
        echo -e "${Red} 端口（port）：${Font} $(info_extraction '\"port\"') "
        echo -e "${Red} 用户id（UUID）：${Font} $(info_extraction '\"id\"')"
        echo -e "${Red} 额外id（alterId）：${Font} $(info_extraction '\"aid\"')"
        echo -e "${Red} 加密方式（security）：${Font} 自适应 "
        echo -e "${Red} 传输协议（network）：${Font} $(info_extraction '\"net\"') "
        echo -e "${Red} 伪装类型（type）：${Font} none "
        echo -e "${Red} 路径（不要落下/）：${Font} $(info_extraction '\"path\"') "
        echo -e "${Red} 底层传输安全：${Font} tls "
    } >"${v2ray_info_file}"
}
show_information() {
    cat "${v2ray_info_file}"
}
vmess_qr_link_image() {
    vmess_link="vmess://$(base64 -w 0 $v2ray_qr_config_file)"
    {
        echo -e "$Red 二维码: $Font"
        echo -n "${vmess_link}" | qrencode -o - -t utf8
        echo -e "${Red} URL导入链接:${vmess_link} ${Font}"
    } >>"${v2ray_info_file}"
}

vmess_quan_link_image() {
    echo "$(info_extraction '\"ps\"') = vmess, $(info_extraction '\"add\"'), \
    $(info_extraction '\"port\"'), chacha20-ietf-poly1305, "\"$(info_extraction '\"id\"')\"", over-tls=true, \
    certificate=1, obfs=ws, obfs-path="\"$(info_extraction '\"path\"')\"", " > /tmp/vmess_quan.tmp
    vmess_link="vmess://$(base64 -w 0 /tmp/vmess_quan.tmp)"
    {
        echo -e "$Red 二维码: $Font"
        echo -n "${vmess_link}" | qrencode -o - -t utf8
        echo -e "${Red} URL导入链接:${vmess_link} ${Font}"
    } >>"${v2ray_info_file}"
}

vmess_link_image_choice() {
        echo "请选择生成的链接种类"
        echo "1: V2RayNG/V2RayN"
        echo "2: quantumult"
        read -rp "请输入：" link_version
        [[ -z ${link_version} ]] && link_version=1
        if [[ $link_version == 1 ]]; then
            vmess_qr_link_image
        elif [[ $link_version == 2 ]]; then
            vmess_quan_link_image
        else
            vmess_qr_link_image
        fi
}

tls_type() {
    if [[ -f "/usr/sbin/nginx" ]] && [[ -f "$nginx_conf" ]] ; then
        echo "请选择支持的 TLS 版本（default:3）:"
        echo "请注意,如果你使用 Quantaumlt X / 路由器 / 旧版 Shadowrocket / 低于 4.18.1 版本的 V2ray core 请选择 兼容模式"
        echo "1: TLS1.1 TLS1.2 and TLS1.3（兼容模式）"
        echo "2: TLS1.2 and TLS1.3 (兼容模式)"
        echo "3: TLS1.3 only"
        read -rp "请输入：" tls_version
        [[ -z ${tls_version} ]] && tls_version=3
        if [[ $tls_version == 3 ]]; then
            sed -i 's/ssl_protocols.*/ssl_protocols         TLSv1.3;/' $nginx_conf
            echo -e "${OK} ${GreenBG} 已切换至 TLS1.3 only ${Font}"
        elif [[ $tls_version == 1 ]]; then
            sed -i 's/ssl_protocols.*/ssl_protocols         TLSv1.1 TLSv1.2 TLSv1.3;/' $nginx_conf
            echo -e "${OK} ${GreenBG} 已切换至 TLS1.1 TLS1.2 and TLS1.3 ${Font}"
        else
            sed -i 's/ssl_protocols.*/ssl_protocols         TLSv1.2 TLSv1.3;/' $nginx_conf
            echo -e "${OK} ${GreenBG} 已切换至 TLS1.2 and TLS1.3 ${Font}"
        fi
        systemctl restart nginx
        judge "Nginx 重启"
    else
        echo -e "${Error} ${RedBG} Nginx 或 配置文件不存在 或当前安装版本为 h2 ，请正确安装脚本后执行${Font}"
    fi
}
show_information() {
    cat "${v2ray_info_file}"
}

start_process_systemd() {
    systemctl daemon-reload
    chown -R root.root /var/log/v2ray/

    systemctl restart nginx
    judge "Nginx 启动"
    systemctl restart v2ray
    judge "V2ray 启动"
}

enable_process_systemd() {
    systemctl enable v2ray
    judge "设置 v2ray 开机自启"
    #systemctl enable nginx
    #judge "设置 Nginx 开机自启"
}

#debian 系 9 10 适配
#rc_local_initialization(){
#    if [[ -f /etc/rc.local ]];then
#        chmod +x /etc/rc.local
#    else
#        touch /etc/rc.local && chmod +x /etc/rc.local
#        echo "#!/bin/bash" >> /etc/rc.local
#        systemctl start rc-local
#    fi
#
#    judge "rc.local 配置"
#}
acme_cron_update() {
    wget -N -P /usr/bin --no-check-certificate "https://raw.githubusercontent.com/wulabing/V2Ray_ws-tls_bash_onekey/dev/ssl_update.sh"
    if [[ $(crontab -l | grep -c "ssl_update.sh") -lt 1 ]]; then
      if [[ "${ID}" == "centos" ]]; then
          #        sed -i "/acme.sh/c 0 3 * * 0 \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" \
          #        &> /dev/null" /var/spool/cron/root
          sed -i "/acme.sh/c 0 3 * * 0 bash ${ssl_update_file}" /var/spool/cron/root
      else
          #        sed -i "/acme.sh/c 0 3 * * 0 \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" \
          #        &> /dev/null" /var/spool/cron/crontabs/root
          sed -i "/acme.sh/c 0 3 * * 0 bash ${ssl_update_file}" /var/spool/cron/crontabs/root
      fi
    fi
    judge "cron 计划任务更新"
}

stop_process_systemd() {
    systemctl stop nginx
    systemctl stop v2ray
}

install_V2manAndV2ray_wstls(){
    install_v2man
    check_system
    chrony_install
    dependency_install
    basic_optimization
    domain_check
    port_alterid_set
    install_v2ray
    port_exist_check 80
    port_exist_check "${port}"

    #自带服务 和开机启动
    nginx_exist_check
    v2ray_conf_add_tls
    nginx_conf_add
    web_camouflage
    ssl_judge_and_install
    # nginx_systemd
    vmess_qr_config_tls_ws
    basic_information
    tls_type
    vmess_link_image_choice
    show_information
    start_process_systemd
    systemctl restart v2man
    judge "v2man 启动"

    enable_process_systemd
    acme_cron_update
}

install_V2manAndV2ray(){
    install_v2man
    check_system
    chrony_install
    dependency_install
    basic_optimization
   
    install_v2ray
    v2ray_conf_add
    web_camouflage

    systemctl daemon-reload
    chown -R root.root /var/log/v2ray/
    systemctl restart v2ray
    judge "V2ray 启动"
    systemctl restart v2man
    judge "v2man 启动"
    systemctl enable v2ray
    judge "设置 v2ray 开机自启"
}

install_V2manAndV2ray_cf(){
    install_v2man
    check_system
    chrony_install
    dependency_install
    basic_optimization
    domain_check_cf
    port_alterid_set_cf
    install_v2ray
    port_exist_check 80

    #自带服务 和开机启动
    nginx_exist_check
    v2ray_conf_add_tls
    nginx_conf_add_cf
    web_camouflage
    vmess_qr_config_cf_ws

    basic_information
    vmess_link_image_choice
    show_information
    start_process_systemd
    systemctl restart v2man
    judge "v2man 启动"

    enable_process_systemd
    
}

judge() {
    if [[ 0 -eq $? ]]; then
        echo -e "${OK} ${GreenBG} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 失败${Font}"
        exit 1
    fi
}

#安装 基础 依赖
dependency_install() {
    #同时安装   wget git lsof
    #${INS} install wget  lsof -y
    install_software wget
    install_software lsof
    if [[ "${ID}" == "centos" ]]; then
        install_software crontabs
    else
        #安装  定时任务模块
      install_software cron
    fi
    judge "安装 crontab"

    if [[ "${ID}" == "centos" ]]; then
        touch /var/spool/cron/root && chmod 600 /var/spool/cron/root
        systemctl start crond && systemctl enable crond
    else
        #修改 文件时间为 当前系统时间
        touch /var/spool/cron/crontabs/root && chmod 600 /var/spool/cron/crontabs/root
        #新创建的cron job，不会马上执行，至少要过2分钟才执行。如果重启cron则马上执行。
        systemctl start cron && systemctl enable cron

    fi

    judge "crontab 自启动配置 "

    install_software bc
    judge "安装 bc"

    install_software unzip
    judge "安装 unzip"

    install_software qrencode
    judge "安装 qrencode"

    install_software curl
    judge "安装 curl"

 


    #    ${INS} -y install rng-tools
    #    judge "rng-tools 安装"

    #安装 补充系统随机数滴池 的模块
    install_software haveged
    #    judge "haveged 安装"

    #    sed -i -r '/^HRNGDEVICE/d;/#HRNGDEVICE=\/dev\/null/a HRNGDEVICE=/dev/urandom' /etc/default/rng-tools

    if [[ "${ID}" == "centos" ]]; then
        #       systemctl start rngd && systemctl enable rngd
        #       judge "rng-tools 启动"
        systemctl start haveged && systemctl enable haveged
        #       judge "haveged 启动"
    else
        #       systemctl start rng-tools && systemctl enable rng-tools
        #       judge "rng-tools 启动"
        systemctl start haveged && systemctl enable haveged
        #       judge "haveged 启动"
    fi

    mkdir -p /usr/local/bin >/dev/null 2>&1
}

basic_optimization() {
    # 最大文件打开数
    #修改 limits.conf文件，删除系统当前生效（soft） 和 系统设定的最大值（hard）， 打开的文件描述符（nofile）的数目 的设置
    sed -i '/^\*\ *soft\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    sed -i '/^\*\ *hard\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    #将允许打开的文件描述符 值 设成最大值 追加到 limits.conf中
    echo '* soft nofile 65536' >>/etc/security/limits.conf
    echo '* hard nofile 65536' >>/etc/security/limits.conf

    # 关闭 Selinux
    if [[ "${ID}" == "centos" ]]; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        setenforce 0
    fi

}

domain_check() {
    read -rp "请输入你的域名信息(eg:www.wulabing.com):" domain
    domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    echo -e "${OK} ${GreenBG} 正在获取 公网ip 信息，请耐心等待 ${Font}"
    local_ip=$(curl https://api-ipv4.ip.sb/ip) 
    echo -e "域名dns解析IP：${domain_ip}"
    echo -e "本机IP: ${local_ip}"
    sleep 2
    if [[ $(echo "${local_ip}" | tr '.' '+' | bc) -eq $(echo "${domain_ip}" | tr '.' '+' | bc) ]]; then
        echo -e "${OK} ${GreenBG} 域名dns解析IP 与 本机IP 匹配 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} 请确保域名添加了正确的 A 记录，否则将无法正常使用 V2ray ${Font}"
        echo -e "${Error} ${RedBG} 域名dns解析IP 与 本机IP 不匹配 是否继续安装？（y/n）${Font}" && read -r install
        case $install in
        [yY][eE][sS] | [yY])
            echo -e "${GreenBG} 继续安装 ${Font}"
            sleep 2
            ;;
        *)
            echo -e "${RedBG} 安装终止 ${Font}"
            exit 2
            ;;
        esac
    fi
}

domain_check_cf() {
    read -rp "请输入你的域名信息(eg:www.wulabing.com):" domain
}

port_alterid_set() {
        read -rp "请输入连接端口（default:443）:" port
        [[ -z ${port} ]] && port="443"
        read -rp "请输入alterID（default:2 仅允许填数字）:" alterID
        [[ -z ${alterID} ]] && alterID="2"
}
port_alterid_set_cf() {
        port=80
        read -rp "请输入alterID（default:2 仅允许填数字）:" alterID
        [[ -z ${alterID} ]] && alterID="2"
}

port_exist_check() {
    if [[ 0 -eq $(lsof -i:"$1" | grep -i -c "listen") ]]; then
        echo -e "${OK} ${GreenBG} $1 端口未被占用 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} 检测到 $1 端口被占用，以下为 $1 端口占用信息 ${Font}"
        lsof -i:"$1"
        echo -e "${OK} ${GreenBG} 5s 后将尝试自动 kill 占用进程 ${Font}"
        sleep 5
        lsof -i:"$1" | awk '{print $2}' | grep -v "PID" | xargs kill -9
        echo -e "${OK} ${GreenBG} kill 完成 ${Font}"
        sleep 1
    fi
}

#检查系统 并更新 对应的 安装包源
check_system() {
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Centos ${VERSION_ID} ${VERSION} ${Font}"
        INS="yum"
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Debian ${VERSION_ID} ${VERSION} ${Font}"
        INS="apt"
        $INS update
        ## 添加 Nginx apt源
    elif [[ "${ID}" == "ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 16 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME} ${Font}"
        INS="apt"
        rm /var/lib/dpkg/lock
        dpkg --configure -a
        rm /var/lib/apt/lists/lock
        rm /var/cache/apt/archives/lock
        $INS update
    else
        echo -e "${Error} ${RedBG} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font}"
        exit 1
    fi
    
    #安装进程通信 dbus
    install_software dbus

    #centos 防火墙
    systemctl stop firewalld
    systemctl disable firewalld
    echo -e "${OK} ${GreenBG} firewalld 已关闭 ${Font}"

    #debian 防火墙
    systemctl stop ufw
    systemctl disable ufw
    echo -e "${OK} ${GreenBG} ufw 已关闭 ${Font}"
}
# Chrony是网络时间协议（NTP）的实现。您可以使用Chrony：
# 
# 使系统时钟与NTP服务器同步，
# 使系统时钟与参考时钟（例如GPS接收器）同步，要将系统时钟与手动时间输入同步，
# 作为NTPv4(RFC 5905)服务器或对等方以向网络中的其他计算机提供时间服务。
# Chrony在各种条件下都表现良好，包括间歇性网络连接，网络严重拥塞，温度变化（普通计算机时钟对温度敏感）以及无法连续运行或在虚拟机上运行的系统。
chrony_install() {

    linen=$(systemctl list-units | grep 'chrony' | awk -F ' ' '{print $1}' | wc -l) 
    if [[ $linen > 0 ]] ;then
        echo "chrony已安装"
        return
    fi

    ${INS} -y install chrony
    judge "安装 chrony 时间同步服务 "

    #timedatectl是Linux下的一条命令，用于控制系统时间和日期。可以用来查询和更改系统时钟于设定，同时可以设定和修改时区信息。
    #启动NTP时间同步（启用NTP服务或者Chrony服务）
    timedatectl set-ntp true

    if [[ "${ID}" == "centos" ]]; then
        systemctl enable chronyd && systemctl restart chronyd
    else
        #设置chrony开机启动 后 重启chrony服务
        systemctl enable chrony && systemctl restart chrony
    fi

    #judge "chronyd 启动 "

    #设置时区为 上海时间 
    timedatectl set-timezone Asia/Shanghai

    echo -e "${OK} ${GreenBG} 等待时间同步 ${Font}"
    sleep 10

    chronyc sourcestats -v
    chronyc tracking -v
    date
    read -rp "请确认时间是否准确,误差范围±3分钟(Y/N): " chrony_install

    #用户输入为空时，设置 chrony_install 为默认为 Y
    [[ -z ${chrony_install} ]] && chrony_install="Y"
    case $chrony_install in
    [yY][eE][sS] | [yY])
        echo -e "${GreenBG} 继续安装 ${Font}"
        sleep 2
        ;;
    *)
        echo -e "${RedBG} 安装终止 ${Font}"
        exit 2
        ;;
    esac
}

install_v2ray(){
    #  v2ray使用到的默认路径
    #-config /etc/v2ray/config.json
    #/var/log/v2ray/access.log
    #/var/log/v2ray/error.log
    #/usr/local/bin/v2ray
    #/usr/local/bin/v2ctl
    #/usr/local/lib/v2ray/geoip.dat
    #/usr/local/lib/v2ray/geosite.dat
    #V2RAY_LOCATION_ASSET=/usr/local/lib/v2ray/

    if  [[ -f $v2ray_bin_dir ]];then 
         echo "v2ray已安装"
         service v2ray stop
        return
    fi

   #systemctl stop v2ray
   #-d 文件名	如果文件存在且为目录则为真
    if [[ -d /root/v2ray ]]; then
        rm -rf /root/v2ray
    fi

    if [[ -d /etc/v2ray ]]; then
        rm -rf /etc/v2ray
    fi
    #创建多级目录 -p
    mkdir -p /root/v2ray
    cd /root/v2ray || exit
    #下载 v2ray.sh 保存在当前目录
    wget -N --no-check-certificate https://raw.githubusercontent.com/wulabing/V2Ray_ws-tls_bash_onekey/master/v2ray.sh
    if [[ -f v2ray.sh ]]; then
        #移除开机启动服务 文件
        rm -rf $v2ray_systemd_file
        #重载systemctl
        systemctl daemon-reload
        #会新开一个子 Shell 执行脚本 v2ray.sh，子 Shell 执行的时候, 父 Shell 还在。子 Shell 执行完毕后返回父 Shell。 子 Shell 从父 Shell 继承环境变量，但是子 Shell 中的环境变量不会带回父 Shell。
        bash v2ray.sh --force
        #judge "安装 V2ray"
    else
        echo -e "${Error} ${RedBG} V2ray 安装文件下载失败，请检查下载地址是否可用 ${Font}"
        exit 4
    fi
    # 清除临时文件
    rm -rf /root/v2ray
}

ssl_update_manuel() {
    if [[ -f "/data/v2ray.key" || -f "/data/v2ray.crt" ]]; then
        [ -f ${amce_sh_file} ] && "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" || echo -e "${RedBG}证书签发工具不存在，请确认你是否使用了自己的证书${Font}"
        domain="$(info_extraction '\"add\"')"
        "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /data/v2ray.crt --keypath /data/v2ray.key --ecc
    else
      domain="$(info_extraction '\"add\"')"
        ssl_judge_and_install
    fi
}

menu() {
    echo -e "\t V2man 安装脚本 ${Red}[${shell_version}]${Font}"
    echo -e "当前已安装版本:${shell_mode}\n"
    echo -e "—————————————— 安装向导 ——————————————"""
    echo -e "${Green}0.${Font}  安装 V2man"
    echo -e "${Green}1.${Font}  卸载 V2man "
    echo -e "${Green}2.${Font}  安装 V2man+v2ray(nginx+ws+tls)"
    echo -e "${Green}3.${Font}  安装 V2man+v2ray(纯净)"
    echo -e "${Green}31.${Font}  安装 V2man+v2ray(cf+nginx+ws)"
    #cf+ws 可由v2man 直接导入 
    echo -e "${Green}4.${Font}  升级 V2Ray core"
    echo -e "—————————————— 其他选项 ——————————————"
    echo -e "${Green}5.${Font} 安装 4合1 bbr 锐速安装脚本"
    echo -e "${Green}6.${Font} 证书 有效期更新或安装"
    echo -e "${Green}7.${Font} 更新 证书crontab计划任务"
    echo -e "${Green}8.${Font} 清空 证书遗留文件"
    echo -e "${Green}9.${Font} 修改本地DNS(下载异常时使用)"
    echo -e "${Green}99.${Font} 退出 \n"

    read -rp "请输入数字：" menu_num

    case $menu_num in
        0)
        install_v2man
        ;;
        1)
        remove_v2man
        ;;
        2)
        install_V2manAndV2ray_wstls
        ;;
        3)
        install_V2manAndV2ray
        ;;
        6)
        stop_process_systemd
        ssl_update_manuel
        start_process_systemd
        ;;
        9)
        editdns
        ;;
        31)
        install_V2manAndV2ray_cf
        ;;
        *)
        exit
        #echo -e "${RedBG}请输入正确的数字${Font}"
        ;;
    esac 

}

editdns(){
    read -p $'选择需要切换到的DNS提供商 1.aliyun , 2.google  :' dnstype
 
    if [[ $dnstype == 1 ]]
        then
        echo  "search localdomain" > "/etc/resolv.conf"
        echo "nameserver 223.5.5.5" >> "/etc/resolv.conf"
        echo "nameserver 223.6.6.6" >> "/etc/resolv.conf"
        service networking restart
        else
        echo  "search localdomain" > "/etc/resolv.conf"
        echo "nameserver 8.8.8.8" >> "/etc/resolv.conf"
        echo "nameserver 8.8.4.4" >> "/etc/resolv.conf"
        service networking restart >/dev/null 2>&1
    fi
    echo "已切换DNS"
}

identify_the_operating_system_and_architecture
menu

