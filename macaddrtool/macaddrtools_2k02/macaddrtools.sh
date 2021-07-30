#!/bin/bash

option=$1

option1=$2

# macaddr=$3
REALDIR=$(dirname "$(realpath "$0")")

if [ $option = "-gl" ] ; then

eth1macaddr="$(LANG=C ifconfig enp3s0 | grep -Po 'HWaddr \K.*$')"
if [ $? -ne 0 ] ; then
    zenity --error --text="英特尔i211以太网网卡1地址获取失败 是否已经进行nvm烧录"
    exit 1
fi
eth2macaddr="$(LANG=C ifconfig enp4s0 | grep -Po 'HWaddr \K.*$')"
if [ $? -ne 0 ] ; then
    zenity --error --text="英特尔i211以太网网卡2地址获取失败 是否已经进行nvm烧录"
    exit 1
fi

#if [ $option = "-gl" ] ; then

    message1="i211-1"
    message2="英特尔i211网卡1"

    message4="i211-2"
    message5="英特尔i211网卡2"
    
    tmp=$(zenity --list --title="以太网卡硬件地址更新工具" --text="以太网卡序号" --column="以太网卡序号" --column="以太网卡序号描述" --column="以太网卡硬件地址" $message1 $message2 $eth1macaddr $message4 $message5 $eth2macaddr --width 600 --height 200)
    exit 0
fi

_uid="$(id -u)"
if [ $_uid -ne 0 ]
then 
    echo "运行以太网硬件地址更新功能需要超级用户权限，请重试"
    exit
fi

if [ $option = "-gb" ] ; then
    message1="i211-1"
    message2="英特尔i211网卡1"
    eth1macaddr="空"

    message4="i211-2"
    message5="英特尔i211网卡2"
    eth2macaddr="空"
    
    tmp=$(zenity --list --title="以太网卡硬件地址更新工具" --text="以太网卡序号" --column="以太网卡序号" --column="以太网卡序号描述" --column="以太网卡硬件地址" $message1 $message2 $eth1macaddr $message4 $message5 $eth2macaddr --width 600 --height 200)
fi

if [ $option = "-q" ] ; then
    tmp=$2
    macaddr=$3
fi

case $tmp in
i211-1)
    ethdef="英特尔i211网卡1"
#    ethdev="enp3s0"
    ethdev=1
    ;;
i211-2)
    ethdef="英特尔i211网卡2"
#    ethdev="enp4s0"
    ethdev=2
    ;;
*)
    echo "错误网卡序号，请重新输入"
    exit 1
esac

# ifconfig $ethdev 1>/dev/null 2>/dev/null
# if [ $? -ne 0 ]
# then
#    echo "$ethdef 不存在，请重新输入"
#    exit 1
# fi

macaddr="$(zenity --entry --title "以太网硬件地址更新" --text "$ethdef" --width 600 --height 200)"

if [ $? -ne 0 ]
then
    exit 1
fi

# input mac address checking
var='^[0-9a-f]+$'
maclen=${#macaddr}
if [ $maclen -eq 17 -o $maclen -eq 12 ]
then
    macaddr2=`echo $macaddr | tr [:upper:] [:lower:]`
    macaddr3=`echo $macaddr2 | tr -d ':'`
    if [[ "$macaddr3" =~ $var ]]
    then
#       echo $macaddr2
        echo $macaddr3
    else
        echo "以太网硬件地址输入错误"
        exit 1
    fi
else
    echo "以太网硬件地址输入错误"
    exit 1
fi

# addr1=`expr substr "$macaddr3" 1 2`
# addr2=`expr substr "$macaddr3" 3 2`
# addr3=`expr substr "$macaddr3" 5 2`
# addr4=`expr substr "$macaddr3" 7 2`
# addr5=`expr substr "$macaddr3" 9 2`
# addr6=`expr substr "$macaddr3" 11 2`

$REALDIR/mactool I211APM.HEX $macaddr3

if [ $? -ne 0 ]
then
    zenity --error --text="英特尔i211以太网网卡nvm烧录文件错误"
    exit 1
fi

echo $ethdev

$REALDIR/EepromAccessTool -nic=$ethdev -f=I211APM.HEX

# if [ "X$ethdev" = "Xenp3s0" ]
# then
#    echo "ethtool"
#    ethtool -E $ethdev magic 0x15338086 offset 0x00 value "0x$addr1"
#    ethtool -E $ethdev magic 0x15338086 offset 0x01 value "0x$addr2"
#    ethtool -E $ethdev magic 0x15338086 offset 0x02 value "0x$addr3"
#    ethtool -E $ethdev magic 0x15338086 offset 0x03 value "0x$addr4"
#    ethtool -E $ethdev magic 0x15338086 offset 0x04 value "0x$addr5"
#    ethtool -E $ethdev magic 0x15338086 offset 0x05 value "0x$addr6"
# fi

# if [ "X$ethdev" = "Xenp4s0" ]
# then
#    echo "ethtool"
#    ethtool -E $ethdev magic 0x15338086 offset 0x00 value "0x$addr1"
#    ethtool -E $ethdev magic 0x15338086 offset 0x01 value "0x$addr2"
#    ethtool -E $ethdev magic 0x15338086 offset 0x02 value "0x$addr3"
#    ethtool -E $ethdev magic 0x15338086 offset 0x03 value "0x$addr4"
#    ethtool -E $ethdev magic 0x15338086 offset 0x04 value "0x$addr5"
#    ethtool -E $ethdev magic 0x15338086 offset 0x05 value "0x$addr6"
# fi

zenity --question --title "以太网硬件地址更新" --text "重启系统使更新生效" --width 600 --height 200
if [ $? -eq 0 ]
then
    reboot
else
    exit
fi
