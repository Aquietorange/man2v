#!/bin/bash
#第一个shell小程序

#定义一个变量
hello="hello word"

#变量名外面的花括号{ }是可选的，加不加都行，加花括号是为了帮助解释器识别变量的边界

skill='sh${hello}'
echo "这是一个自定义变量 ${skill}Script"

#以单引号' '包围变量的值时，单引号里面是什么就输出什么，即使内容中有变量和命令（命令需要反引起来）也会把它们原样输出。这种方式比较适合定义显示纯字符串的情况，即不希望解析变量、命令等的场景。

#以双引号" "包围变量的值时，输出时会先解析里面的变量和命令，而不是把双引号中的变量名和命令原样输出。这种方式比较适合字符串中附带有变量和命令并且想将其解析后再输出的变量定义。

#将命令的结果赋值给变量
#variable=`command`
#variable=$(command)
#第一种方式把命令用反引号包围起来，反引号和单引号非常相似，容易产生混淆，所以不推荐使用这种方式；第二种方式把命令用$()包围起来，区分更加明显，所以推荐使用这种方式。

#使用 cat 命令将 1.txt 的内容读取出来，并赋值给log变量，然后使用 echo 命令输出。
log=$(cat 1.txt)
echo $log

#shell 变量的高级用法 
#  从头开始匹配，将符合最短(长)的数据删除 
#       variable_1="I love you, Do you love me"
#       echo $variable_1
#       variable_2=${variable_1#*ov} //从头开始匹配，将复合最短的数据删除, 将 ov(含)之前的内容删除 ,输出 ：e you, Do you love me
#       variable_3=${variable_1##*ov} //从头开始匹配，将复合最长的数据删除, 将 ov(含)之前的内容删除,输出 ：e me
#       echo $variable_2 $variable_3
#替换字符串
#       echo $PATH
#       var6=${PATH/bin/BIN}  //将PATH 变量中内容 bin 替换成 BIN 只替换一次
#       var7=${PATH//bin/BIN}  //将PATH 变量中内容 bin 全部替换成 BIN
#       echo $var6
#
#https://www.cnblogs.com/crazymagic/p/11067147.html


#使用 readonly 命令可以将变量定义为只读变量
#使用 unset 命令可以删除变量

# 特殊变量列表
# 变量	含义
#  $0	当前脚本的文件名
#  $n	传递给脚本或函数的参数。n 是一个数字，表示第几个参数。例如，第一个参数是#  $1，第二个参数是$2。
#  $#	传递给脚本或函数的参数个数。
#  $*	传递给脚本或函数的所有参数。
#  $@	传递给脚本或函数的所有参数。被双引号(" ")包含时，与 $* 稍有不同，下面将会讲到。
#  $?	上个命令的退出状态，或函数的返回值。
#  $$	当前Shell进程ID。对于 Shell 脚本，就是这些脚本所在的进程ID。

#$* 和 $@ 的区别
#$* 和 $@ 都表示传递给函数或脚本的所有参数，不被双引号(" ")包含时，都以"$1" "$2" … "$n" 的形式输出所有参数。

#但是当它们被双引号(" ")包含时，"$*" 会将所有的参数作为一个整体，以"$1 $2 … $n"的形式输出所有参数；"$@" 会将各个参数分开，以"$1" "$2" … "$n" 的形式输出所有参数。



#  下面的转义字符都可以用在 echo 中：echo -e 可以替换转义符
#  转义字符	含义
#  \\	反斜杠
#  \a	警报，响铃
#  \b	退格（删除键）
#  \f	换页(FF)，将当前位置移到下页开头
#  \n	换行
#  \r	回车
#  \t	水平制表符（tab键） 
#  \v	垂直制表符

# 命令替换是指Shell可以先执行命令，将输出结果暂时保存，在适当的地方输出。
DATE=`date`
echo "Date is $DATE"

#变量替换
#变量替换可以根据变量的状态（是否为空、是否定义等）来改变它的值

#  可以使用的变量替换形式：
#  形式	说明
#  ${var}	变量本来的值

#  ${var:-word}	如果变量 var 为空或已被删除(unset)，那么返回 word，但不改变 var 的值。

#  ${var:=word}	如果变量 var 为空或已被删除(unset)，那么返回 word，并将 var 的值设置为 word。

#  ${var:?message}	如果变量 var 为空或已被删除(unset)，那么将消息 message 送到标准错误输出，可以用来检测变量 var 是否可以被正常赋值。
#  若此替换出现在Shell脚本中，那么脚本将停止运行。
#  
#  ${var:+word}	如果变量 var 被定义，那么返回 word，但不改变 var 的值。


#取磁盘根分区剩余空间
disk_size=$(df / | awk '/\//{print $4}')

#提取内存剩余空间
mem_size=$(free | awk '/Mem/{print $4}')

echo "hello:"$hello
echo  "disk_size:"$disk_size
echo  "mem_size:"$mem_size

#使用 read 命令从 stdin 获取输入并赋值给 PERSON 变量，最后在 stdout 上输出
#   -a 后跟一个变量，该变量会被认为是个数组，然后给其赋值，默认是以空格为分割符。
#   -p 后面跟提示信息，即在输入前打印提示信息。
#   -r 屏蔽\，如果没有该选项，则\作为一个转义字符，有的话 \就是个正常的字符了。
read -p "写点什么吧: " youinput
echo "你写的是不是："$youinput

# read -a arr -p "输入数组测试,用空格分隔: "
# echo "$arr"
# echo "${#arr[*]}"
# echo "${arr[3]}"


# RANDOM 为系统自带的系统变量,值为 0‐32767的随机数
# 使用取余算法将随机数变为 1‐100 的随机数
num=$[RANDOM%100+1]
echo "取随机数:"$num

# 使用 read 提示用户猜数字
# 使用 if 判断用户猜数字的大小关系:‐eq(等于),‐ne(不等于),‐gt(大于),‐ge(大于等于),
# ‐lt(小于),‐le(小于等于)
while  :
do
	read -p "计算机生成了一个 1‐100 的随机数,你猜: " cai
    if [ $cai -eq $num ]
    then
       	echo "恭喜,猜对了"
           break
    	elif [ $cai -gt $num ]
    	then
           	echo "Oops,猜大了"
      	else
           	echo "Oops,猜小了"
 	fi
done

echo $?
echo "--------------"
val=`expr 2 + 100`
echo "expr 计算 $val"

#算术运算符

#两点注意：
#表达式和运算符之间要有空格，例如 2+2 是不对的，必须写成 2 + 2，这与我们熟悉的大多数编程语言不一样。
#完整的表达式要被 ` ` 包含，注意这个字符不是常用的单引号，在 Esc 键下边。

#乘号(*)前边必须加反斜杠(\)才能实现乘法运算；


a=10
b=20
val=`expr $a + $b`

echo "a + b : $val"

val=`expr $a - $b`
echo "a - b : $val"

val=`expr $a \* $b`
echo "a * b : $val"

val=`expr $b / $a`
echo "b / a : $val"

val=`expr $b % $a`
echo "b % a : $val"

#注意：条件表达式要放在方括号之间，并且要有空格，例如 [$a==$b] 是错误的，必须写成 [ $a == $b ]。

if [ $a == $b ]
then
   echo "a is equal to b"
fi

if [ $a != $b ]
then
   echo "a is not equal to b"
fi

#文件测试运算符列表
#-b file	检测文件是否是块设备文件，如果是，则返回 true。	[ -b $file ] 返回 #false。
#-c file	检测文件是否是字符设备文件，如果是，则返回 true。	[ -b $file ] 返回 false。
#-d file	检测文件是否是目录，如果是，则返回 true。	[ -d $file ] 返回 false。
#-f file	检测文件是否是普通文件（既不是目录，也不是设备文件），如果是，则返回 true。	[ -f $file ] 返回 true。
#-g file	检测文件是否设置了 SGID 位，如果是，则返回 true。	[ -g $file ] 返回 false。
#-k file	检测文件是否设置了粘着位(Sticky Bit)，如果是，则返回 true。	[ -k $file ] 返回 false。
#-p file	检测文件是否是具名管道，如果是，则返回 true。	[ -p $file ] 返回 false。
#-u file	检测文件是否设置了 SUID 位，如果是，则返回 true。	[ -u $file ] 返回 false。
#-r file	检测文件是否可读，如果是，则返回 true。	[ -r $file ] 返回 true。
#-w file	检测文件是否可写，如果是，则返回 true。	[ -w $file ] 返回 true。
#-x file	检测文件是否可执行，如果是，则返回 true。	[ -x $file ] 返回 true。
#-s file	检测文件是否为空（文件大小是否大于0），不为空返回 true。	[ -s $file ] 返回 true。
#-e file	检测文件（包括目录）是否存在，如果是，则返回 true。	[ -e $file ] 返回 true。

#字符串

zs(){

#拼接字符串
your_name="qinjx"
greeting="hello, "$your_name" !"
greeting_1="hello, ${your_name} !"
echo $greeting $greeting_1

#获取字符串长度
string="abcd"
echo ${#string} #输出 4

#提取子字符串
string="alibaba is a great company"
echo ${string:1:4} #输出liba

#查找子字符串
string="alibaba is a great company"
echo `expr index "$string" is`

}

#定义数组
zs(){
在Shell中，用括号来表示数组，数组元素用“空格”符号分割开。定义数组的一般形式为：

array_name=(value0 value1 value2 value3)

#还可以单独定义数组的各个分量：
#可以不使用连续的下标，而且下标的范围没有限制。
array_name[0]=value0
array_name[1]=value1
array_name[2]=value2

}

#读取数组
zs(){
    读取数组元素值的一般格式是：
  #  ${array_name[index]}

  #  例：valuen=${array_name[2]}
}
NAME[0]="Zara"
NAME[1]="Qadir"
NAME[2]="Mahnaz"
NAME[3]="Ayan"
NAME[4]="Daisy"
echo "数组， First Index: ${NAME[0]}"
echo "数组， Second Index: ${NAME[1]}"

#使用@ 或 * 可以获取数组中的所有元素，例如：
echo "数组， First Index: ${NAME[*]}"
echo "数组， Second Index: ${NAME[@]}"

#获取数组的长度
length=${#NAME[*]}
# 取得数组单个元素的长度
lengthn=${#NAME[n]}

echo $length
echo $lengthn

#显示结果重定向至文件
echo "aaaaaaaaaaa" >./1.txt

# test 命令用于检查某个条件是否成立，它可以进行数值、字符和文件三个方面的测试。

# Shell还提供了与( ! )、或( -o )、非( -a )三个逻辑操作符用于将测试条件连接起来，其优先级为：“!”最高，“-a”次之，“-o”最低。例如：
if test -e ./1.txt -o  -e ./2.txt 
    then 
    echo " 其中有一个文件存在"
    else 
    echo "2个文件都不存在"
fi

#case ... esac 与其他语言中的 switch ... case 语句类似，是一种多分枝选择结构。
echo 'Input a number between 1 to 4'
echo 'Your number is:\c'
read aNum
case $aNum in
    1)  echo 'You select 1'
    ;;
    2)  echo 'You select 2'
    ;;
    3)  echo 'You select 3'
    ;;
    4)  echo 'You select 4'
    ;;
    *)  echo 'You do not select a number between 1 to 4'
    ;;
esac

#for循环
#显示当前目录下以 .bash 开头的文件：

#输出当前脚本所在目录
pathsh=$(dirname "$0")

for FILE in $pathsh/*.sh
do
   echo $FILE
done

#while循环 读取键盘信息 ctrl+d 结束
while read FILM
do
    echo "Yeah! great film the $FILM"
done


#  关系运算符列表
#  运算符	                说明	                举例
#  -eq	    检测两个数是否相等，相等返回 true。	        [ $a -eq $b ] 返回 true。
#  -ne	    检测两个数是否相等，不相等返回 true。	        [ $a -ne $b ] 返回 true。
#  -gt	    检测左边的数是否大于右边的，如果是，则返回 true。	        [ $a -gt $b ] 返回 false。
#  -lt	    检测左边的数是否小于右边的，如果是，则返回 true。	        [ $a -lt $b ] 返回 true。
#  -ge	    检测左边的数是否大等于右边的，如果是，则返回 true。	        [ $a -ge $b ] 返回 false。
#  -le	    检测左边的数是否小于等于右边的，如果是，则返回 true。	        [ $a -le $b ] 返回 true。

#until循环 循环执行一系列命令直至条件为 true 时停止。until 循环与 while 循环在处理方式上刚好相反。
#使用 until 命令输出 0 ~ 9 的数字：
a=0
until [ ! $a -lt 10 ]
do
   echo $a
   a=`expr $a + 1`
done

# break命令
# break命令允许跳出所有循环（终止执行后面的所有循环）。

#continue命令
#continue命令与break命令类似，只有一点差别，它不会跳出所有循环，仅仅跳出当前循环。

#   函数
#   function_name () {
#       list of commands
#       [ return value ]
#   }

#函数返回值，可以显式增加return语句；如果不加，会将最后一条命令运行结果作为返回值。

# 函数返回值只能是整数，一般用来表示函数执行成功与否，0表示成功，其他值表示失败。如果 return 其他数据，比如一个字符串，往往会得到错误提示：“numeric argument required”。

#调用函数只需要给出函数名，不需要加括号。

#像删除变量一样，删除函数也可以使用 unset 命令，不过要加上 .f 选项，如下所示：
# unset .f function_name

#如果希望直接从终端调用函数，可以将函数定义在主目录下的 .profile 文件，这样每次登录后，在命令提示符后面输入函数名字就可以立即调用。

funWithReturn(){
    echo "The function is to get the sum of two numbers..."
    echo -n "Input first number: "
    read aNum
    echo -n "Input another number: "
    read anotherNum
    echo "The two numbers are $aNum and $anotherNum !"
    return $(($aNum+$anotherNum))
}

funWithReturn

# $? 取上一个命令的执行结果
ret=$?
echo "The sum of two numbers is $ret !"

#函数参数
#调用函数时可以向其传递参数。在函数体内部，通过 $n 的形式来获取参数的值，例如，$1表示第一个参数，$2表示第二个参数...
#注意，$10 不能获取第十个参数，获取第十个参数需要${10}。当n>=10时，需要使用${n}来获取参数。

#   $#	传递给函数的参数个数。
#   $*	显示所有传递给函数的参数。
#   $@	与$*相同，但是略有区别，请查看Shell特殊变量。
#   $?	函数的返回值。

#Unix 命令默认从标准输入设备(stdin)获取输入，将结果输出到标准输出设备(stdout)显示。一般情况下，标准输入设备就是键盘，标准输出设备就是终端，即显示器。

#输出重定向
#命令的输出不仅可以是显示器，还可以很容易的转移向到文件，这被称为输出重定向。

#语法
# command > file
#例:
#who > users

#输出重定向会覆盖文件内容
#如果不希望文件内容被覆盖，可以使用 >> 追加到文件末尾，例如：
# echo line 2 >> users

#输入重定向
#和输出重定向一样，Unix 命令也可以从文件获取输入，语法为：
#command < file

#例如，计算 users 文件中的行数，可以使用命令：wc -l users
#也可以 wc -l < users

#Shell文件包含
#可以使用：
#. filename
# 或
#source filename

#两种方式的效果相同，简单起见，一般使用点号(.)，但是注意点号(.)和文件名中间有一空格。
#注意：被包含脚本不需要有执行权限。


#linux ; &&和&，|和||的用法
#在用linux命令时候,我们可以一行执行多条命令或者有条件的执行下一条命令

# ; 分号用法

#方式：command1 ; command2
#用;号隔开每个命令, 每个命令按照从左到右的顺序,顺序执行， 彼此之间不关心是否失败， 所有命令都会执行。


# | 管道符用法

#上一条命令的输出，作为下一条命令参数
#方式：command1 | command2
#Linux所提供的管道符“|”将两个命令隔开，管道符左边命令的输出就会作为管道符右边命令的输入。连续使用管道意味着第一个命令的输出会作为 第二个命令的输入，第二个命令的输出又会作为第三个命令的输入，依此类推


# & 符号用法

#&放在启动参数后面表示设置此进程为后台进程
#方式：command1 &
#默认情况下，进程是前台进程，这时就把Shell给占据了，我们无法进行其他操作，对于那些没有交互的进程，很多时候，我们希望将其在后台启动，可以在启动参数的时候加一个'&'实现这个目的。

# && 符号用法

#shell 在执行某个命令的时候，会返回一个返回值，该返回值保存在 shell 变量 $? 中。当 $? == 0 时，表示执行成功；当 $? == 1 时（我认为是非0的数，返回值在0-255间），表示执行失败。
#有时候，下一条命令依赖前一条命令是否执行成功。如：在成功地执行一条命令之后再执行另一条命令，或者在一条命令执行失败后再执行另一条命令等。shell 提供了 && 和 || 来实现命令执行控制的功能，shell 将根据 && 或 || 前面命令的返回值来控制其后面命令的执行。

#语法格式如下：
#command1 && command2 [&& command3 ...]
#命令之间使用 && 连接，实现逻辑与的功能。
#只有在 && 左边的命令返回真（命令返回值 $? == 0），&& 右边的命令才会被执行。
#只要有一个命令返回假（命令返回值 $? == 1），后面的命令就不会被执行。

# || 符号用法

#逻辑或的功能
#语法格式如下：
#command1 || command2 [|| command3 ...]

#命令之间使用 || 连接，实现逻辑或的功能。
#只有在 || 左边的命令返回假（命令返回值 $? == 1），|| 右边的命令才会被执行。这和 c 语言中的逻辑或语法功能相同，即实现短路逻辑或操作。
#只要有一个命令返回真（命令返回值 $? == 0），后面的命令就不会被执行。 –直到返回真的地方停止执行。


#启动NTP时间同步（启用NTP服务或者Chrony服务）：timedatectl set-ntp true

#systemctl enable XXX 将服务设置为每次开机启动；
#systemctl start XXX 服务立即启动 下次不启动；
#systemctl enable --now
# systemctl restart XXX  重启
# systemctl stop XX 停止
# systemctl reload XXX 重载
# systemctl status XXX  检查状态
# systemctl list-units  列出当前已经启动的 unit，如果添加 -all 选项会同时列出没有启动的 unit。
# systemctl list-units | grep 'v2man' | awk -F ' ' '{print $1}'  查找当前是否存在v2man 服务
# systemctl show --property MainPID --value v2ray   // property 指定只显示 服务的特定属性，--value 指定只显示 属性值
#systemctl mask unit  注销 unit，注销后你就无法启动这个 unit 了。
#systemctl unmask unit   取消对 unit 的注销。
#systemctl disable unit   禁用服务 设置下次开机时 ，后面接的 unit 不会被启动。


# journalctl -u unitxxx.service   //输出此服务的日志
# journalctl   -f -u v2xxx.service  //实时输出指定服务日志



#echo $(systemctl list-units | grep 'v2man' | awk -F ' ' '{print $1}')
#注意：当我们使用systemctl的start，restart，stop和reload命令时，终端不会输出任何内容，只有status命令可以打印输出。



#chrony
# Chrony是网络时间协议（NTP）的实现。debian 安装 Chrony： apt -y install chrony
# 它由两个程序组成：chronyd和chronyc。
# 使系统时钟与NTP服务器同步，
# 使系统时钟与参考时钟（例如GPS接收器）同步，要将系统时钟与手动时间输入同步，
# 作为NTPv4(RFC 5905)服务器或对等方以向网络中的其他计算机提供时间服务。
# Chrony在各种条件下都表现良好，包括间歇性网络连接，网络严重拥塞，温度变化（普通计算机时钟对温度敏感）以及无法连续运行或在虚拟机上运行的系统。
# chronyc sourcestats -v #查看时间同步源状态：
# chronyc tracking -v			显示系统时间信息

#lsof
#lsof是系统管理/安全的尤伯工具。将这个工具称之为lsof真实名副其实，因为它是指“列出打开文件（lists openfiles）”。而有一点要切记，在Unix中一切（包括网络套接口）都是文件。
#lsof -i  显示所有连接和监听端口
#lsof  -iTCP  仅显示TCP连接（同理可获得UDP连接）
#lsof  -i:22   显示与指定端口相关的网络信息
# lsof  -i@172.16.12.5  显示 到指定远程主机的连接 （如果有）
# lsof  -t -c XXX  返回指定进程名 的 进程PID
# lsof -p XXX   查看指定进程ID已打开的内容
# lsof ~/go_demo/v2man   显示与指定目录交互的所有一切

#wget
#wget是Linux中的一个下载文件的工具，wget是在Linux下开发的开放源代码的软件
#https://www.cnblogs.com/sx66/p/11887022.html

#bc
#bc 命令是任意精度计算器语言，通常在linux下当计算器用。
#它类似基本的计算器, 使用这个计算器可以做基本的数学运算。
# echo "15+5" | bc

#unzip
#Linux unzip命令用于解压缩zip文件
#unzip为.zip压缩文件的解压缩程序。
#unzip -l abc.zip  查看压缩文件中包含的文件
#unzip abc.zip   将abc.zip 解压到当前文件下
#unzip -n abc.zip -d /tmp   将abc.zip 解压到/tmp ,并且不替换已有文件
#unzip -o abc.zip -d /tmp   将abc.zip 解压到/tmp ,并且替换已有文件

#qrencode
#Linux下二维码生成工具：QRencode
# apt -y install qrencode
# Usage: qrencode [OPTION]... [STRING]
# OPTIONS：
# -o：输出的二维码文件名。如test.png。需要以.png结尾。-表示输出到控制台。
# -s：指定图片大小。默认为3个像素。
# -t：指定产生的图片类型。默认为PNG。可以是PNG/ANSI/ANSI256/ASCIIi/UTF8等。如果需要输出到控制台，可以用ANSI、ANSI256等
# 
# STRING：可以是text、url等
# 例：输出 指定文字生成的二维码 到控制台
#   qrencode -o - -t ANSI "自定义内容"

#curl
#在Linux中curl是一个利用URL规则在命令行下工作的文件传输工具，可以说是一款很强大的http命令行工具。它支持文件的上传和下载，是综合传输工具，但按传统，习惯称url为下载工具。
#语法：# curl [option] [url]
# curl http://www.linux.com 基本用法
# curl http://www.linux.com >> linux.html  保存访问的网页,使用linux的重定向功能 >> 保存
# curl -o linux.html http://www.linux.com   使用curl的内置option:-o(小写)保存网页
# curl -O http://www.linux.com/hello.sh  使用curl的内置option:-O(大写)保存网页中的文件,要注意这里后面的url要具体到某个文件，不然抓不下来
# curl -o /dev/null -s -w %{http_code} www.baidu.com  测试网页返回值,常见的测试网站是否正常的用法
# curl -x 192.168.100.100:1080 www.baidu.com   指定proxy服务器以及其端口 访问网页
# curl -c cookiec.txt  http://www.baidu.com  执行后cookie信息就被存到了cookiec.txt里面了
# curl -D header.txt http://www.baidu.com   执行后header信息就被存到了header.txt里面了
# curl -b cookiec.txt http://www.baidu.com  使用cookiec.txt 为cookie 访问网页
# curl -O http://www.linux.com/dodo[1-5].JPG 循环下载，有时候下载图片可以能是前面的部分名称是一样的，就最后的尾椎名不一样
#curl可以通过ftp下载文件，curl提供两种从ftp中下载的语法
#curl -O -u 用户名:密码 ftp://www.linux.com/dodo1.JPG
#curl -O ftp://用户名:密码@www.linux.com/dodo1.JPG
#curl -T dodo1.JPG -u 用户名:密码 ftp://www.linux.com/img/  上传文件到FTP，通过-T来实现
# local_ip=$(curl https://api-ipv4.ip.sb/ip)   取公网IP地址
# https://www.cnblogs.com/yanguhung/p/10115911.html

#apt-cache
#查看哪些包被 build-essential依赖用命令:
#apt-cache depends build-essential   列出build-essential包的依赖

#build-essential
#作用是提供编译程序必须软件包的列表信息,即提供 把源码编译成可执行文件 所需的编译环境
#apt-get install build-essential

#haveged
#cat /proc/sys/kernel/random/entropy_avail  查询系统随机熵池
#补充系统随机数滴池 的模块
#  apt-y install haveged
#https://www.livelu.com/201910366.html

#mkdir
#mkdir（英文全拼：make directory）命令用于创建目录。
#mkdir -p runoob2/test  //在工作目录下的 runoob2 目录中，建立一个名为 test 的子目录。，若 runoob2 目录原本不存在，则建立一个。（注：本例若不加 -p 参数，且原本 runoob2 目录不存在，则产生错误。）

#mkdir runoob  在当前目录，建立一个名为 runoob 的子目录 :

#sed是一种流编辑器，它是文本处理中非常好的工具，能够完美的配合正则表达式使用，功能不同凡响。处理时，把当前处理的行存储在临时缓冲区中，称为“模式空间”（pattern space），接着用sed命令处理缓冲区中的内容，处理完成后，把缓冲区的内容送往屏幕。接着处理下一行，这样不断重复，直到文件末尾。文件内容并没有改变，除非你使用重定向存储输出。Sed主要用来自动编辑一个或多个文件，可以将数据行进行替换、删除、新增、选取等特定工作，简化对文件的反复操作，编写转换程序等。
#https://www.linuxprobe.com/linux-sed-command.html

#   参数说明：
#       -e<script>或--expression=<script> 以选项中指定的script来处理输入的文本文件。
#       -f<script文件>或--file=<script文件> 以选项中指定的script文件来处理输入的文本文件。
#       -h或--help 显示帮助。
#       -n或--quiet或--silent 仅显示script处理后的结果。
#       -V或--version 显示版本信息。
#   
#   动作说明：
#       a ：新增， a 的后面可以接字串，而这些字串会在新的一行出现(目前的下一行)～
#       c ：取代， c 的后面可以接字串，这些字串可以取代 n1,n2 之间的行！
#       d ：删除，因为是删除啊，所以 d 后面通常不接任何咚咚；
#       i ：插入， i 的后面可以接字串，而这些字串会在新的一行出现(目前的上一行)；
#       p ：打印，亦即将某个选择的数据印出。通常 p 会与参数 sed -n 一起运行～
#       s ：取代，可以直接进行取代的工作哩！通常这个 s 的动作可以搭配正规表示法！例如 1,20s/old/new/g 就是啦！

# sed -n '/PWD/p' ./1.txt       //搜索当前目录下1.txt 文件内包含 PWD 的 所有行，并输出显示 
# echo "$(cat 1.txt | sed -n '1{/XDG/p}' )"   //在第一行 搜索 是否包含 XDG ，如果是，则输出 第一行，不是则输出 空
# sed -e 4a\newLine testfile   在testfile文件的第四行后添加一行，并将结果输出到标准输出，在命令行提示符下输入如下命令：

# sed -i 'gggggggggg' ./1.txt    //在当前目录下1.txt 文件中，每一行后面，追加新的一行内容 gggggggggg
# sed  '/PWD/d'                  /将当前目录下1.txt 文件中 所有 包含 PWD 的行 删除后，输出显示，此操作 不改变文件内容
# sed '/^$/d' file              删除空白行：
# sed '2d' fil                  删除文件的第2行：
# sed -i '/cdrom/d' fil e                 所有含cdrom的行：
# sed '$d' file                 删除文件最后一行
# sed '/^test/'d file           删除文件中所有开头是test的行：
# sed -i "/acme.sh/c 0 3 * * 0 bash abcdef" ./1.txt    用0 3 * * 0 bash abcdef 替换acme.sh所在行

#修改 limits.conf文件，删除系统当前生效（soft） 和 系统设定的最大值（hard）， 打开的文件描述符（nofile）的数目 的设置
#sed -i '/^\*\ *soft\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
#sed -i '/^\*\ *hard\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf

#正则表达式 \w\+ 匹配每一个单词，使用 [&] 替换它，& 对应于之前所匹配到的单词：
#echo this is a test line | sed 's/\w\+/[&]/g'          //输出：[this] [is] [a] [test] [line] 

#子串匹配标记\1
#echo this is digit 7 in a number | sed 's/digit \([0-9]\)/\1/'   输出 ：this is 7 in a number
#命令中 digit 7，被替换成了 7。样式匹配到的子串是 7，\([0-9]\) 用于匹配子串，对于匹配到的第一个子串就标记为 \1，依此类推匹配到的第二个结果就是 \2，例如：
#echo aaa BBB | sed 's/\([a-z]\+\) \([A-Z]\+\)/\2 \1/'   输出 ： BBB aaa

# test=hello 
# echo hello WORLD | sed "s/$test/HELLO"   //sed表达式可以使用单引号来引用，但是如果表达式内部包含变量字符串，就需要使用双引号。

#组合多个表达式
# sed '表达式' | sed '表达式'  等价于：  sed '表达式; 表达式' 

#选定行的范围：,（逗号）
#
#sed -n '/HOME/,/TERM/p' ./1.txt   //所有在模板test和check所确定的范围内的行都被打印： 即只输出 匹配到 HOME行 和 TERM行 ，之间的所有行内容，包括HOME所在行 和TERM所在行
#sed -n '5,/^test/p' ./1.txt   //打印从第5行开始到第一个包含以test开始的行之间的所有行

#对于模板HOME和TERM之间的行，每行的末尾用字符串aaa bbb替换：
#sed '/HOME/,/TERM/s/$/aaa bbb/' ./1.txt

#取ping IP
#domain_ip=$(ping "www.baidu.com" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')  //匹配第一行, 删除这一行， 不以 ( 开头的字符 到 ( 之前的内容，然后删除 ) 之后的全部内容,即 取到 () 之间的内容ip地址
#echo $domain_ip

#ping
#Linux ping 命令用于检测主机。
#执行 ping 指令会使用 ICMP 传输协议，发出要求回应的信息，若远端主机的网络功能没有问题，就会回应该信息，因而得知该主机运作正常。
#ping www.baidu.com -c 3  //ping baidu 3次后结束 
# -c <完成次数> 设置完成要求回应的次数。
# -f 极限检测。
# -i<间隔秒数> 指定收发信息的间隔时间。
# -w <deadline> 在 deadline 秒后退出。
# -W <timeout> 在等待 timeout 秒后开始执行。

#tr
#tr 命令用于转换或删除文件中的字符。
#https://blog.csdn.net/jeffreyst_zb/article/details/8047065
#tr 指令从标准输入设备读取数据，经过字符串转译后，将结果输出到标准输出设备。
#cat testfile |tr a-z A-Z  //将文件testfile中的小写字母全部转换成大写字母，此时，可使用如下命令：
#cat testfile |tr [:lower:] [:upper:]   //大小写转换，也可以通过[:lower][:upper]参数来实现
#cat file | tr "abc" "xyz" > new_file   //将文件file中出现的"abc"替换为"xyz",，凡是在file中出现的"a"字母，都替换成"x"字母，"b"字母替换为"y"字母，"c"字母替换为"z"字母。而不是将字符串"abc"替换为字符串"xyz"。

#  "127.5.6.188" | tr '.' '+' | bc  //将ip 相加 计算后 输出

#rm
# rm（英文全拼：remove）命令用于删除一个文件或者目录。
# rm [options] name...
#   参数：
#   -i 删除前逐一询问确认。
#   -f 即使原档案属性设为唯读，亦直接删除，无需逐一确认。
#   -r 将目录及以下之档案亦逐一删除。
# rm -rf ./1.txt   //删除1.txt 无需确认

#uname
# uname（英文全拼：unix name）命令用于显示系统信息。
# uname 可显示电脑以及操作系统的相关信息。
#   参数说明：
#   -a或--all 　显示全部的信息。
#   -m或--machine 　显示电脑类型。
#   -n或--nodename 　显示在网络上的主机名称。
#   -r或--release 　显示操作系统的发行编号。
#   -s或--sysname 　显示操作系统名称。
#   -v 　显示操作系统的版本。
#   --help 　显示帮助。
#   --version 　显示版本信息。

#pidof
#pidof命令用于查找指定名称进程的进程号id号。
#pidof(选项)(参数)
#pidof nginx  //输出 PID ： 13344
#   选项
#      -s：仅返回一个进程号；
#      -c：仅显示具有相同“root”目录的进程；
#      -x：显示由脚本开启的进程；
#      -o：指定不显示的进程ID。
#
#   参数
#       进程名称：指定要查找的进程名称。

#install
#install命令的作用是安装或升级软件或备份数据，它的使用权限是所有用户。 
#https://www.jb51.net/article/124538.htm
#将可执行文件v2man 移动到 目录 /usr/local/bin/ ，同时设定可执行权限
#install -m 755 "/root/demo/v2man" "/usr/local/bin/v2man"

#tar
#解压 文件 到 当前目录
#tar -zxvf nginx-"$nginx_version".tar.gz
#压缩打包文件
#tar -czvf test.tar.gz a.c   //压缩 a.c文件为test.tar.gz
#列出压缩文件内容
# tar -tzvf test.tar.gz 
#解压 文件 到 指定目录, 指定目录 需要 是已存在的
#tar -zxvf nginx-"$nginx_version".tar.gz -c /home/test


#docker rmi $(docker images | grep none | awk '{print $3}')

#设置系统代理
#export HTTP_PROXY="http://127.0.0.1:10708/"
#export HTTPS_PROXY="http://127.0.0.1:10708/"
#export FTP_PROXY="http://127.0.0.1:10708/"
#export NO_PROXY="127.0.0.1,localhost"


#创建Swap交换文件 虚拟内存
#在这个例子中，我们将创建并激活1G的Swap，要创建更大的Swap，请将1G替换为所需Swap空间的大小。
#以下步骤操作如何在Debian 10上添加Swap交换空间。
#
#1、首先创建一个用于Swap的文件：
#fallocate -l 1G /swapfile
#
#如果未安装fallocate或者你收到错误消息，指出fallocate失败：操作不受支持（fallocate failed: Operation not supported），你可以使用以下命令创建交换文件：
#dd if=/dev/zero of=/swapfile bs=1024 count=1048576
#
#2、只有root用户才能读取和写入交换文件，输入以下命令以设置正确的权限：
# chmod 600 /swapfile
#
#3、使用mkswap工具在文件上设置Linux Swap区域：
# mkswap /swapfile
#
#4、激活Swap文件：
#swapon /swapfile
#
#要使更改永久，打开/etc/fstab文件：
#nano /etc/fstab
#
#并粘贴以下行：
#/swapfile swap swap defaults 0 0
#
#5、使用swapon或free命令验证Swap是否处于活动状态，如下所示：
#sudo swapon --show


#tail 
#命令可用于查看文件的指定行数或长度内容
#tail notes.log           默认显示最后 10 行
#tail -f notes.log        跟踪名为 notes.log 的文件的增长情况
#tail -n +20 notes.log    从第 20 行至文件末尾:
#tail -c 10 notes.log     显示文件 notes.log 的最后 10 个字符: