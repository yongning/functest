#!/bin/bash

option=$1

option1=$2

# macaddr=$3
REALDIR=$(dirname "$(realpath "$0")")

eth1macaddr="$(LANG=C ifconfig enp8s0 | grep -Po 'HWaddr \K.*$')"
if [ $? -ne 0 ] ; then
    zenity --error --text="英特尔i210以太网网卡地址获取失败"
    exit 1
fi
eth2macaddr="$(LANG=C ifconfig enaftgm1i1 | grep -Po 'HWaddr \K.*$')"
if [ $? -ne 0 ] ; then
    zenity --error --text="飞腾内置以太网卡2网卡地址获取失败"
    exit 1
fi

if [ $option = "-gl" ] ; then

    message1="i210-1"
    message2="英特尔i210网卡1"

    message4="ft-2"
    message5="飞腾内置网卡2"
    
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
    message1="i210-1"
    message2="英特尔i210网卡1"

    message4="ft-2"
    message5="飞腾内置网卡2"
    
    tmp=$(zenity --list --title="以太网卡硬件地址更新工具" --text="以太网卡序号" --column="以太网卡序号" --column="以太网卡序号描述" --column="以太网卡硬件地址" $message1 $message2 $eth1macaddr $message4 $message5 $eth2macaddr --width 600 --height 200)
fi

if [ $option1 = "-c" ]
then
#    "$REALDIR/i2c1cmd" -c 1 -a 0 -v 55
#    "$REALDIR/i2c1cmd" -c 1 -a 1 -v aa
    temp="$("$REALDIR/i2c1cmd" -c 1 -a 32 -v 55)"
    echo $temp
    tmp1="$(echo $temp | grep "i2c1cmd_error" | wc -l)"
    echo $tmp1
    if [ $tmp1 -ne 0 ] ; then
        zenity --error --text="单板配置信息烧录错误，您需要重新运行烧录程序"
        exit 1
    fi

    temp="$("$REALDIR/i2c1cmd" -c 1 -a 33 -v 0)"
    echo $temp
    tmp1="$(echo $temp | grep "i2c1cmd_error" | wc -l)"
    echo $tmp1
    if [ $tmp1 -ne 0 ] ; then
        zenity --error --text="单板配置信息烧录错误，您需要重新运行烧录程序"
        exit 1
    fi

    temp="$("$REALDIR/i2c1cmd" -c 1 -a 34 -v 21)"
    echo $temp
    tmp1="$(echo $temp | grep "i2c1cmd_error" | wc -l)"
    echo $tmp1
    if [ $tmp1 -ne 0 ] ; then
        zenity --error --text="单板配置信息烧录错误，您需要重新运行烧录程序"
        exit 1
    fi
fi

if [ $option = "-q" ] ; then
    tmp=$2
    macaddr=$3
fi

case $tmp in
ft-1)
    ethdef="飞腾内置网卡1"
    ethdev="enaftgm1i0"
    ;;
ft-2)
    ethdef="飞腾内置网卡2"
    ethdev="enaftgm1i1"
    ;;
i210-1)
    ethdef="英特尔i210网卡1"
    ethdev="enp8s0"
    ;;
i210-2)
    ethdef="英特尔i210网卡2"
    ethdev="enp8s1"
    ;;
*)
    echo "错误网卡序号，请重新输入"
    exit 1
esac

ifconfig $ethdev 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]
then
    echo "$ethdef 不存在，请重新输入"
    exit 1
fi

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

addr1=`expr substr "$macaddr3" 1 2`
addr2=`expr substr "$macaddr3" 3 2`
addr3=`expr substr "$macaddr3" 5 2`
addr4=`expr substr "$macaddr3" 7 2`
addr5=`expr substr "$macaddr3" 9 2`
addr6=`expr substr "$macaddr3" 11 2`

if [ "X$ethdev" = "Xenp8s0" ]
then
    echo "ethtool"
    ethtool -E $ethdev magic 0x15338086 offset 0x00 value "0x$addr1"
    ethtool -E $ethdev magic 0x15338086 offset 0x01 value "0x$addr2"
    ethtool -E $ethdev magic 0x15338086 offset 0x02 value "0x$addr3"
    ethtool -E $ethdev magic 0x15338086 offset 0x03 value "0x$addr4"
    ethtool -E $ethdev magic 0x15338086 offset 0x04 value "0x$addr5"
    ethtool -E $ethdev magic 0x15338086 offset 0x05 value "0x$addr6"
fi

if [ "X$ethdev" = "Xenaftgm1i0" ]
then
    temp="$("$REALDIR/i2c1cmd" -c 2 -a 2 -d "$addr1" -e "$addr2" -f "$addr3" -g "$addr4" -h "$addr5" -i "$addr6")"
    echo $temp
    tmp1="$(echo $temp | grep "i2c1cmd_error" | wc -l)"
    echo $tmp1
    if [ $tmp1 -ne 0 ] ; then
        zenity --error --text="飞腾内置以太网1地址烧录错误，您需要重新运行烧录程序"
        exit 1
    fi
fi

if [ "X$ethdev" = "Xenaftgm1i1" ]
then
    temp="$("$REALDIR/i2c1cmd" -c 2 -a 9 -d "$addr1" -e "$addr2" -f "$addr3" -g "$addr4" -h "$addr5" -i "$addr6")"
    echo $temp
    tmp1="$(echo $temp | grep "i2c1cmd_error" | wc -l)"
    echo $tmp1
    if [ $tmp1 -ne 0 ] ; then
        zenity --error --text="飞腾内置以太网2地址烧录错误，您需要重新运行烧录程序"
        exit 1
    fi
fi

zenity --question --title "以太网硬件地址更新" --text "重启系统使更新生效" --width 600 --height 200
if [ $? -eq 0 ]
then
    reboot
else
    exit
fi
