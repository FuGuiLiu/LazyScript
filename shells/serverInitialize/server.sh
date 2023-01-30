#颜色定义
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
cn='\033[0m'

# check root 检查权限
[[ $EUID -ne 0 ]] && echo -e "${red}错误:${cn} 必须使用root用户运行此脚本！\n" && exit 1

# 选择安装和卸载
echo -e "${blue}欢迎使用服务器初始化脚本${cn}"
echo -e "$blue------------------------------------------------------------------------$cn"
echo -e "$blue| 服务器一键修改Root密码、SSH端口号、关闭禁用防火墙、删除冗余组件、$cn"
echo -e "$blue| 使用时请使用Root权限账号操作 sudo -i$cn"
echo -e "$blue| 有问题联系作者: https://github.com/FuGuiLiu || ryder@ryder.eu.org$cn"
echo -e "$blue------------------------------------------------------------------------$cn"

echo -e "${blue}检查当前系统.......${cn}"
# check os 检查系统版本
if [[ -f /etc/redhat-release ]]; then
	release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
	release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
	release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
	release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
	release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
	release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
	release="centos"
else
	echo -e "${red}未检测到系统版本，请联系脚本作者!${cn}\n" && exit 1
fi

# 当前系统版本
echo -e "${blue}当前系统版本--->${cn}:${red}$release${cn}"

#函数

#修改root密码
changeRootPasswordInfo() {

	# 设置允许使用root用户登录
	sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
	echo -e "${blue}设置允许Root账号登录......${cn}"

	# 设置启动密码认证
	sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	echo -e "${blue}设置允许Root密码校验......${cn}"

	echo -e "${red}设置Root密码.......${cn}"
  passwd

result=$?

until
	[ $result -eq 0 ]
do
	echo -e "${red}两次密码不一致: [请重新输入 (按任意键继续)或者输入 q 退出(quit)]<希望你不是杠精 (っ╥╯﹏╰╥c) >${cn}"

	read -p "" isQuit
	if [[ $isQuit == "q" || $isQuit == "Q" ]]; then
		exit 1
	fi

	if [[ $isQuit != "q" || $isQuit != "Q" ]]; then
		passwd
		result=$?
	fi
done


	echo -e "${blue}重启ssh服务.......${cn}"
	systemctl restart sshd.service
}
#Ubuntu相关配置
ubuntu() {
	#安装系统相关依赖
	echo -e "${blue}安装系统相关依赖.......${cn}"
	apt update -y
	apt-get update -y && apt-get install -y curl

	#删除、关闭、打开各自系统的无用附件、防火墙、端口及规则
	echo -e "${blue}删除、关闭、打开各自系统的无用附件、防火墙、端口及规则.......${cn}"
	#  开放所有端口
	echo -e "${blue}开放所有端口.......${cn}"
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -F

	#  Ubuntu 镜像默认设置了 Iptables 规则，关闭它
	echo -e "${blue}Ubuntu 镜像默认设置了 Iptables 规则，关闭它.......${cn}"
	apt-get -y purge netfilter-persistent
}
#centos相关配置
centos() {
	#安装系统相关依赖
	echo -e "${blue}安装系统相关依赖.......${cn}"
	yum update -y
	yum update -y && yum install -y curl
	#删除、关闭、打开各自系统的无用附件、防火墙、端口及规则
	echo -e "${blue}删除、关闭、打开各自系统的无用附件、防火墙、端口及规则.......${cn}"
	#  删除多余附件
	echo -e "${blue}删除多余附件.......${cn}"
	systemctl stop oracle-cloud-agent
	systemctl disable oracle-cloud-agent
	systemctl stop oracle-cloud-agent-updater
	systemctl disable oracle-cloud-agent-updater
	#  停止 firewall
	echo -e "${blue}停止 firewall防火墙.......${cn}"
	systemctl stop firewalld.service
	#  禁止 firewall 开机启动
	echo -e "${blue}禁止 firewall防火墙 开机启动.......${cn}"
	systemctl disable firewalld.service
	#  关闭selinux
	echo -e "${blue}关闭selinux.......${cn}"
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
}
#debian相关配置
debian() {
	#安装系统相关依赖
	echo -e "${blue}安装系统相关依赖.......${cn}"
	apt-get update -y
	apt-get update -y && apt-get install -y curl
}
#是否重启
isReboot() {

	#读取用户输入
	read -p "$(echo -e "${red}是否重启${cn} [${blue}Y/N$cn]: ")" isReboot

	until
		[ $isReboot == "Y" ] || [ $isReboot == "N" ] || [ $isReboot == "y" ] || [ $isReboot == "n" ]
	do
		read -p "$(echo -e "${red}是否重启${cn} [${blue}Y/N$cn]: ")" isReboot
	done

	#  如果选择Y 重启
	if [ $isReboot == "Y" ] || [ $isReboot == "y" ]; then
		echo -e "${red}Rebooting...${cn}"
		reboot
	fi
	#  如果选择N 不重启
	if [ $isReboot == "N" ] || [ $isReboot == "n" ]; then
		echo -e "${yellow}bye bye...${cn}" && exit 1
	fi
}

### 根据不同的系统进行操作

#Ubuntu系统相关操作
if [ "$release" == "ubuntu" ]; then

	read -p "$(echo -e "是否修改Root密码 [${blue}Y/N${cn}]: ")" isChangeRootPassword
	if [ $isChangeRootPassword == "Y" ] || [ $isChangeRootPassword == "y" ]; then
		#  调用修改root密码函数
		changeRootPasswordInfo
	fi
	ubuntu
	#  判断用户是否自动重启
	isReboot
fi

#CentOS系统相关操作
if [ "$release" == "centos" ]; then

	read -p "$(echo -e "是否修改Root密码 [${blue}Y/N${cn}]: ")" isChangeRootPassword
	if [ $isChangeRootPassword == "Y" ] || [ $isChangeRootPassword == "y" ]; then
		#  调用修改root密码函数
		changeRootPasswordInfo
	fi

	centos
	#  判断用户是否自动重启
	isReboot
fi


#Debian系统相关操作
if [ "$release" == "debian" ]; then

	read -p "$(echo -e "是否修改Root密码 [${blue}Y/N${cn}]: ")" isChangeRootPassword
	if [ $isChangeRootPassword == "Y" ] || [ $isChangeRootPassword == "y" ]; then
		#  调用修改root密码函数
		changeRootPasswordInfo
	fi

	debian
	#  判断用户是否自动重启
	isReboot
fi
