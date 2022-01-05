red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
cn='\033[0m'
checkSystem() {
	echo -e "$blue检查当前系统.......$cn"
	if [[ -f /etc/redhat-release ]]; then
		yum update -y
		release="centos"
	elif cat /etc/issue | grep -Eqi "debian"; then
		release="debian"
	elif cat /etc/issue | grep -Eqi "ubuntu"; then
		apt-get update
		release="ubuntu"
	elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
		yum update -y
		release="centos"
	elif cat /proc/version | grep -Eqi "debian"; then
		release="debian"
	elif cat /proc/version | grep -Eqi "ubuntu"; then
		apt-get update
		release="ubuntu"
	elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
		yum update -y
		release="centos"
	else
		echo -e "$red未检测到系统版本，请联系脚本作者!$cn\n" && exit 1
	fi
	echo -e "$blue当前系统版本--->$cn:$red$release$cn"

	if [ "$release" == "centos" ]; then
		onCentOS
	elif [ "$release" == "ubuntu" ]; then
		onUbuntu
	elif [ "$release" == "debian" ]; then
		onDebian
	fi
}
onCentOS() {
	yum remove -y docker \
	docker-client \
	docker-client-latest \
	docker-common \
	docker-latest \
	docker-latest-logrotate \
	docker-logrotate \
	docker-engine

	yum install -y yum-utils

	yum-config-manager \
	--add-repo \
	https://download.docker.com/linux/centos/docker-ce.repo

	yum install -y docker-ce docker-ce-cli containerd.io

	systemctl start docker
}

onDebian() {
	apt-get remove -y docker docker-engine docker.io containerd runc

	apt-get update -y

	apt-get install -y \
	ca-certificates \
	curl \
	gnupg \
	lsb-release

	curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

	echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

	apt-get update

	apt-get install -y docker-ce docker-ce-cli containerd.io
}

onUbuntu() {
	apt-get -y remove docker docker-engine docker.io containerd runc

	apt-get -y install \
	ca-certificates \
	curl \
	gnupg \
	lsb-release

	apt-get install -y curl

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

	apt-get -y update
	apt-get install -y docker-ce docker-ce-cli containerd.io
}
[[ $EUID -ne 0 ]] && echo -e "$red错误:$cn 必须使用root用户运行此脚本！\n" && exit 1
echo -e "${blue}docker一键安装脚本$cn"
echo -e "$blue------------------------------------------------------------------------$cn"
echo -e "$blue以下步骤来自官方文档__均安装最新版本$cn"
echo -e "$blue| 使用时请使用Root权限账号操作 sudo -i$cn"
echo -e "$blue| 有问题联系作者: https://github.com/FuGuiLiu || liu997121@gmail.com$cn"
echo -e "$blue------------------------------------------------------------------------$cn"
echo -e "$blue安装或者卸载docker$cn"
echo -e "$blue----------------------------------------------$cn"
echo -e "$blue| 1.   Install        - 安装Docker             $cn"
echo -e "$blue| 2.   exit           - 退出(我点错了)           $cn"
echo -e "$blue----------------------------------------------$cn"
read -p "请选择(1-3):" chooseNumber
until
	[ "$chooseNumber" -gt 0 -a "$chooseNumber" -lt 3 ]
do
	read -p "请选择(1-2):" chooseNumber
done
if [ "$chooseNumber" -eq 1 ]; then
	checkSystem
fi
