#颜色定义
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
cn='\033[0m'

##定义变量

#默认jdk安装包路径
jdkSourcePath=/usr/local/java

# check root 检查权限
[[ $EUID -ne 0 ]] && echo -e "${red}错误:${cn} 必须使用root用户运行此脚本！\n" && exit 1

# 选择安装和卸载
echo -e "${blue}欢迎使用Jenkins自动安装脚本${cn}"
echo -e "$blue------------------------------------------------------------------------$cn"
echo -e "$blue| 使用时请使用Root权限账号操作 sudo -i$cn"
echo -e "$blue| 有问题联系作者: https://github.com/FuGuiLiu || liu997121@gmail.com$cn"
echo -e "$blue------------------------------------------------------------------------$cn"
# 选择安装和卸载
echo -e "${blue}安装或卸载Jenkins程序${cn}"
echo -e "$blue----------------------------------------------$cn"
echo -e "$blue| 1.   Install        - 安装                  $cn"
echo -e "$red| 2.   Uninstall      - 卸载                  $cn"
echo -e "$blue| 3.   exit   - 退出(我点错了)                  $cn"
echo -e "$blue----------------------------------------------$cn"

#函数

#安装jdk,jdk版本为11
jdkInstall() {
	echo -e "${blue}jdk默认安装路径:${cn}${green}$jdkSourcePath${cn}"

	#CentOS系统相关操作
	if [ "$release" == "centos" ]; then
		#下载jdk安装包
		wget -P $jdkSourcePath https://www.dropbox.com/s/bttx2jhp3po4r3e/jdk-11.0.13_linux-x64_bin.tar.gz --no-check-certificate
		tar -zxvf ${jdkSourcePath}/jdk-11.0.13_linux-x64_bin.tar.gz -C ${jdkSourcePath}
		echo "export JAVA_HOME=${jdkSourcePath}/jdk-11.0.13" >>/etc/profile
		echo "export JRE_HOME=\${JAVA_HOME}/jre" >>/etc/profile
		echo "export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib" >>/etc/profile
		echo "export PATH=\${JAVA_HOME}/bin:\$PATH" >>/etc/profile
		echo -e "${blue}刷新环境变量${cn}\n"

		source /etc/profile

		java -version

		successInstallJavaEnv=$?
		if [ $successInstallJavaEnv -ne 0 ]; then
			echo -e "${red}java 环境安装失败,请检查脚本配置${cn}"
			exit
		else
			echo -e "${green}java 环境安装成功\n\n\n${cn}"
		fi
	fi
}
#安装git
gitInstall() {
	if [ "$release" == "centos" ]; then
		echo -e "${blue}安装git${cn}"
		yum install -y git
	elif [ "$release" == "ubuntu" ]; then
		echo "暂不支持"
	fi
}
#安装Jenkins
jenkinsInstall() {
	if [ "$release" == "centos" ]; then
		echo -e "${blue}下载Jenkins安装包${cn}"
		# 不检查证书
		wget -P /opt/jenkins https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/jenkins-2.263.1-1.1.noarch.rpm --no-check-certificate

		echo -e "${blue}开始解压安装.......${cn}"
		cd /opt/jenkins && rpm -ivh jenkins-2.263.1-1.1.noarch.rpm

		echo -e "${blue}修改jenkins配置,修改用户为root${cn}"
		sed -i 's/JENKINS_USER.*/JENKINS_USER="root"/g' /etc/sysconfig/jenkins

		# 设置Jenkins默认端口号
		# shellcheck disable=SC2162
		read -p "$(echo -e "${blue}设置Jenkins访问端口(默认3333):${cn}")" jenkinsPort
		if [ ! "$jenkinsPort" ]; then
			jenkinsPort=3333
		fi
		until
			# shellcheck disable=SC2166
			[ $jenkinsPort -gt 1 -a $jenkinsPort -lt 65536 ]
		do
			echo -e "${red}无效的端口号输入,请重新输入${cn}"
			read -p "$(echo -e "${blue}设置Jenkins访问端口:(默认3333):${cn}")" jenkinsPort
		done

		# 修改Jenkins默认端口号
		echo -e $jenkinsPort
		sed -i "s/JENKINS_PORT.*/JENKINS_PORT=\"${jenkinsPort}\"/g" /etc/sysconfig/jenkins

		#手动指定Jenkins Java环境,因为我们安装的jdk环境不在它这个candidates候选环境变量列表中 这里我是用 # 符号分割避免 / 路径需要转义
		sed -i "s#candidates=\"#candidates=\"\n${jdkSourcePath}/jdk-11.0.13/bin/java#g" /etc/init.d/jenkins

		# 安装一些字体,防止Jenkins  说这些字体之类的错误 Djava.awt.headless 亲测有效
		yum install -y dejavu-sans-fonts
		yum install -y fontconfig
		yum install -y xorg-x11-server-Xvfb

		#启动Jenkins
		systemctl daemon-reload
		systemctl start jenkins

		#判断Jenkins是否启动成功 1 run 0 not run
		isJenkinsRun=$(ps -ef | grep jenkins | grep -v "grep" | wc -l)
		if [ $isJenkinsRun -eq 1 ]; then
			echo -e "${green}Jenkins 已就绪${cn}"
		else
			echo -e "${red}Jenkins 启动失败,请检测脚本,或联系作者 liu997121@gmail.com${cn}"
		fi
	elif [ "$release" == "ubuntu" ]; then
		echo "暂不支持"
	fi
}

#读取用户输入
read -p "请选择(1-3):" chooseNumber

until
	# shellcheck disable=SC2166
	[ "$chooseNumber" -gt 0 -a "$chooseNumber" -lt 4 ]
do
	# shellcheck disable=SC2162
	read -p "请选择(1-3):" chooseNumber
done

if [ "$chooseNumber" -eq 1 ]; then
	echo -e "${blue}检查当前系统.......${cn}"
	# check os 检查系统版本
	if [[ -f /etc/redhat-release ]]; then
		#检测Jenkins是否已经启动,启动的话无需安装
		isJenkinsRun=$(ps -ef | grep jenkins | grep -v "grep" | wc -l)
		if [ $isJenkinsRun -eq 1 ]; then
			echo -e "${green}Jenkins 已安装无需继续安装${cn}"
			exit
		fi
		yum update -y
		yum install -y wget
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

	## 根据不同的系统进行操作
	#Ubuntu系统相关操作
	if [ "$release" == "ubuntu" ]; then
		echo "暂不支持该系统"
	fi

	#Debian系统相关操作
	if [ "$release" == "debian" ]; then
		echo "暂不支持该系统"
	fi

	jdkInstall
	gitInstall
	jenkinsInstall
elif [ "$chooseNumber" -eq 2 ]; then
	#卸载jdk
	#移除所有的安装包
	echo -e "${red}卸载jdk${cn}"
	rm -rf $jdkSourcePath/jdk-11.0.13_linux-x64_bin.tar.gz
	rm -rf $jdkSourcePath/jdk-11.0.13
	#移除环境变量
	sed -i '/JAVA_HOME/d' /etc/profile
	#刷新环境变量
	source /etc/profile

	echo -e "${red}卸载git${cn}"
	yum remove -y git

	echo -e "${red}卸载Jenkins${cn}"
	#移除Jenkins的安装包
	rm -rf /opt/jenkins/jenkins-2.263.1-1.1.noarch.rpm

	systemctl stop jenkins.service
	rpm -e jenkins
	rpm -qa | grep jenkins
	rm -rf /etc/sysconfig/jenkins.rpmsave
	rm -rf /var/cache/jenkins/
	rm -rf /var/lib/jenkins/
	rm -rf /var/log/jenkins
	rm -rf /usr/lib/jenkins
	#判断Jenkins是否启动成功 1 run 0 not run
	# shellcheck disable=SC2009
	# shellcheck disable=SC2126
	isJenkinsRun=$(ps -ef | grep jenkins | grep -v "grep" | wc -l)
	if [ "$isJenkinsRun" -eq 0 ]; then
		echo -e "${green}Jenkins 卸载成功${cn}"
	else
		echo -e "${red}Jenkins 卸载失败,请检测脚本,或联系作者 liu997121@gmail.com${cn}"
	fi
fi