#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

# 定义颜色变量
Font_Yellow='\033[1;33m'
Font_Suffix='\033[0m'
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_BrightBlack="\033[90m"
Font_BrightRed="\033[91m"
Font_BrightGreen="\033[92m"
Font_BrightYellow="\033[93m"
Font_BrightBlue="\033[94m"
Font_BrightPurple="\033[95m"
Font_BrightSkyBlue="\033[96m"
Font_BrightWhite="\033[97m"
Font_Orange="\033[38;5;208m"

if [ ! -d /www/server/panel/BTPanel ];then
	echo "============================================="
	echo "错误, 5.x不可以使用此命令升级!"
	echo "5.9平滑升级到6.0的命令：curl http://io.bt.sb/install/update_to_6.sh|bash"
	exit 0;
fi

if [ ! -f "/www/server/panel/pyenv/bin/python3" ];then
	echo "============================================="
	echo "错误, 当前面板过旧/py-2.7/无pyenv环境，无法升级至最新版面板"
	echo "请截图 联系 TG群组：@rsakuras 或者 QQ群组：630947024 求助！"
	exit 0;
fi

public_file=/www/server/panel/install/public.sh
publicFileMd5=$(md5sum ${public_file} 2>/dev/null|awk '{print $1}')
md5check="acfc18417ee58c64ff99d186f855e3e1"
if [ "${publicFileMd5}" != "${md5check}"  ]; then
	wget -O Tpublic.sh http://download.bt.cn/install/public.sh -T 20;
	publicFileMd5=$(md5sum Tpublic.sh 2>/dev/null|awk '{print $1}')
	if [ "${publicFileMd5}" == "${md5check}"  ]; then
		\cp -rpa Tpublic.sh $public_file
	fi
	rm -f Tpublic.sh
fi
. $public_file

Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
if [ "${Centos8Check}" ];then
	if [ ! -f "/usr/bin/python" ] && [ -f "/usr/bin/python3" ] && [ ! -d "/www/server/panel/pyenv" ]; then
		ln -sf /usr/bin/python3 /usr/bin/python
	fi
fi

mypip="pip"
env_path=/www/server/panel/pyenv/bin/activate
if [ -f $env_path ];then
	mypip="/www/server/panel/pyenv/bin/pip"
fi

download_Url=http://io.bt.sb
setup_path=/www

if [ -f "/www/server/panel/data/is_beta.pl" ];then
version=$(curl -Ss --connect-timeout 5 -m 2 https://api.bt.sb/api/panel/beta_version)
else
version=$(curl -Ss --connect-timeout 5 -m 2 https://api.bt.sb/api/panel/get_version)
fi

if [ "$version" = '' ];then
	version='9.5.0'
fi
armCheck=$(uname -m|grep arm)
if [ "${armCheck}" ];then
	version='7.7.0'
fi

if [ "$1" ];then
	version=$1
fi

wget -T 5 -O /tmp/panel.zip $download_Url/install/update/LinuxPanel-${version}.zip
chattr -i /www/server/panel/data/userInfo.json
dsize=$(du -b /tmp/panel.zip|awk '{print $1}')
if [ $dsize -lt 10240 ];then
	echo "获取更新包失败，请及时联系 TG群组：@rsakuras 或者 QQ群组：663908405 进行反馈！"
	exit;
fi
unzip -o /tmp/panel.zip -d $setup_path/server/ > /dev/null
rm -f /tmp/panel.zip
#wget -O /www/server/panel/data/userInfo.json http://io.bt.sb/install/token/userInfo.json
#chattr +i /www/server/panel/data/userInfo.json
sed -i 's/[0-9\.]\+[ ]\+www.bt.cn//g' /etc/hosts
sed -i 's/[0-9\.]\+[ ]\+api.bt.sb//g' /etc/hosts
cd $setup_path/server/panel/
check_bt=`cat /etc/init.d/bt`
if [ "${check_bt}" = "" ];then
	rm -f /etc/init.d/bt
	wget -O /etc/init.d/bt $download_Url/install/src/bt7.init -T 20
	chmod +x /etc/init.d/bt
fi
rm -f /www/server/panel/*.pyc
rm -f /www/server/panel/class/*.pyc
#pip install flask_sqlalchemy
#pip install itsdangerous==0.24

pip_list=$($mypip list)
request_v=$(btpip list 2>/dev/null|grep "requests "|awk '{print $2}'|cut -d '.' -f 2)
if [ "$request_v" = "" ] || [ "${request_v}" -gt "28" ];then
	$mypip install requests==2.27.1
fi

openssl_v=$(echo "$pip_list"|grep pyOpenSSL)
if [ "$openssl_v" = "" ];then
	$mypip install pyOpenSSL
fi

#cffi_v=$(echo "$pip_list"|grep cffi|grep 1.12.)
#if [ "$cffi_v" = "" ];then
#	$mypip install cffi==1.12.3
#fi

pymysql=$(echo "$pip_list"|grep pymysql)
if [ "$pymysql" = "" ];then
	$mypip install pymysql
fi

pymysql=$(echo "$pip_list"|grep pycryptodome)
if [ "$pymysql" = "" ];then
	$mypip install pycryptodome
fi

#psutil=$(echo "$pip_list"|grep psutil|awk '{print $2}'|grep '5.7.')
#if [ "$psutil" = "" ];then
#	$mypip install -U psutil
#fi

if [ -d /www/server/panel/class/BTPanel ];then
	rm -rf /www/server/panel/class/BTPanel
fi

chattr -i /etc/init.d/bt
chmod +x /etc/init.d/bt

#echo > /www/server/panel/data/bind.pl
rm -rf /www/server/panel/data/bind.pl

rm -rf /www/server/panel/class/pluginAuth.cpython-37m-aarch64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-37m-i386-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-37m-loongarch64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-37m-x86_64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-310-aarch64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-310-x86_64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.so
#rm -rf /www/server/panel/class/pluginAuth.py

rm -rf /www/server/panel/class/libAuth.aarch64.so
rm -rf /www/server/panel/class/libAuth.glibc-2.14.x86_64.so
rm -rf /www/server/panel/class/libAuth.loongarch64.so
rm -rf /www/server/panel/class/libAuth.x86-64.so
rm -rf /www/server/panel/class/libAuth.x86.so

#rm -rf /www/server/panel/class/PluginLoader.aarch64.Python3.7.so
#rm -rf /www/server/panel/class/PluginLoader.i686.Python3.7.so
rm -rf /www/server/panel/class/PluginLoader.loongarch64.Python3.7.so
#rm -rf /www/server/panel/class/PluginLoader.so
rm -rf /www/server/panel/class/PluginLoader.s390x.Python3.7.so
#rm -rf /www/server/panel/class/PluginLoader.x86_64.glibc214.Python3.7.so
#rm -rf /www/server/panel/class/PluginLoader.x86_64.Python3.7.so

#echo "====================================="
rm -f /dev/shm/bt_sql_tips.pl
kill $(ps aux|grep -E "task.pyc|main.py"|grep -v grep|awk '{print $2}')
/etc/init.d/bt start
echo ""
echo 'True' > /www/server/panel/data/restart.pl
pkill -9 gunicorn &

echo "====================================="

# 调用接口获取统计信息
response=$(curl -s "https://tj.bt.sb/api/count?param=bt&token=6920626369b1f05844f5e3d6f93b5f6e")
# 检查 Python 版本
if command -v python3 &>/dev/null; then
    # 使用 Python 3 解析 JSON
    TodayRunTimes=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['today_count'])")
    TotalRunTimes=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['total_count'])")
elif command -v python &>/dev/null; then
    # 使用 Python 2 解析 JSON
    TodayRunTimes=$(echo "$response" | python -c "import sys, json; print json.load(sys.stdin)['today_count']")
    TotalRunTimes=$(echo "$response" | python -c "import sys, json; print json.load(sys.stdin)['total_count']")
else
    echo "Error: Python is not installed." >&2
    exit 1
fi

# 调用接口获取广告信息
ads_response=$(curl -s https://ads.bt.sb/ads)
if [ -z "$ads_response" ];then
    echo "Failed to fetch ads"
    rm -f $Updating
    exit 1
fi

# 解析广告数据
ads_texts=$(echo "$ads_response" | grep -o '"text":"[^"]*"' | sed 's/"text":"\(.*\)"/\1/')

# 显示广告信息
i=0
while IFS= read -r text; do
  case $i in
    0)
      echo ""
      echo -e "${Font_Orange}${text}${Font_Suffix}"
      ;;
    1)
      echo ""
      echo -e "${text}"
      ;;
    2)
      echo -e ""
      echo -e "${Font_BrightGreen}${text}${Font_Suffix}"
      ;;
    3)
      echo -e "${text}"
      ;;
    4)
      echo -e "${Font_BrightPurple}${text}${Font_Suffix}"
      ;;
    5)
      echo -e ""
      echo -e "${Font_BrightSkyBlue}${text}${Font_Suffix}"
      ;;
    6)
      echo -e "${text}"
      ;;
    7)
      echo -e "${Font_BrightGreen}${text}${Font_Suffix}"
      ;;
    8)
      echo -e "${Font_Red}${text}${Font_Suffix}"
      echo -e ""
      ;;
    9)
      echo -e "${text}"
      ;;
    *)
      echo -e "${text}"
      ;;
  esac
  i=$((i+1))
done <<< "$ads_texts"

rm -f $Updatings

echo ""
# 显示统计结果
echo -e "${Font_Yellow}脚本当天运行次数: ${TodayRunTimes}; 共计运行次数: ${TotalRunTimes} ${Font_Suffix}"
echo ""
rm -f $Updating

echo "已成功升级到 [$version]企业版";
echo ""




