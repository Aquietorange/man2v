#!/bin/bash

#包安装命令
PACKAGE_MANAGEMENT_INSTALL=""

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

install_Netpenetrate(){
     TMP_FILE="$(mktemp)"
     echo "创建临时文件："$TMP_FILE

     if ! wget -O $TMP_FILE --no-check-certificate https://api.github.com/repos/Aquietorange/man2v/releases/latest ; then 
        echo "下载失败"
        rm "$TMP_FILE"
        exit 1
     fi
    RELEASE_LATEST="$(sed 'y/,/\n/' "$TMP_FILE" | grep 'tag_name' | awk -F '"' '{print $4}')"
    rm "$TMP_FILE"

    echo "最新版本："$RELEASE_LATEST
     
    mkdir -p $(pwd)/plugs/NetPenetrate &&   cd $(pwd)/plugs/NetPenetrate || exit

    netpen_FILE="$(pwd)/NetPenetrate.tar.gz"
    
    
    if [ ! -f $netpen_FILE ] 
    then
        if ! wget -O $netpen_FILE --no-check-certificate "https://github.com/Aquietorange/man2v/releases/download/$RELEASE_LATEST/netpe_linux_arm64.tar.gz"; then 
                echo "下载失败"
                exit 1
        fi
    fi
    tar -zxvf $netpen_FILE 
    chmod +x ./client
    chmod +x ./server
  
}

identify_the_operating_system_and_architecture
install_Netpenetrate

if [[ $?==0 ]];then
    echo "install succeed"
else 
    echo  "install failure"
fi
