#!/bin/bash

option=$1

option1=$2

# macaddr=$3
REALDIR=$(dirname "$(realpath "$0")")

eth1macaddr="$(LANG=C ifconfig enaphyt4i0 | grep -Po 'HWaddr \K.*$')"
if [ $? -ne 0 ] ; then
    zenity --error --text="飞腾内置以太网卡1 网卡地址获取失败"
    exit 1
fi
eth2macaddr="$(LANG=C ifconfig enaphyt4i1 | grep -Po 'HWaddr \K.*$')"
if [ $? -ne 0 ] ; then
    zenity --error --text="飞腾内置以太网卡2 网卡地址获取失败"
    exit 1
fi

if [ $option = "-gl" ] ; then

    message1="ft-1"
    message2="飞腾内置网卡1"

    message4="ft-2"
    message5="飞腾内置网卡2"
    
    tmp=$(zenity --list --title="以太网卡硬件地址更新工具" --text="以太网卡序号" --column="以太网卡序号" --column="以太网卡序号描述" --column="以太网卡硬件地址" $message1 $message2 $eth1macaddr $message4 $message5 $eth2macaddr --width 600 --height 200)
    exit 0
fi

if [ $option = "-gp" ] ; then
    var='^[0-9a-f]+$'
    macaddr2=`echo $eth1macaddr | tr [:upper:] [:lower:]`
    macaddr3=`echo $macaddr2 | tr -d ':'`
    if [[ "$macaddr3" =~ $var ]]
    then
        echo $macaddr3
    else
        echo "以太网硬件地址错误"
        exit 1
    fi

    macaddr4=`echo $eth2macaddr | tr [:upper:] [:lower:]`
    macaddr5=`echo $macaddr4 | tr -d ':'`
    if [[ "$macaddr5" =~ $var ]]
    then
        echo $macaddr5
    else
        echo "以太网硬件地址错误"
        exit 1
    fi

    barcode -b $macaddr3 -b $macaddr5 -t 1x2+20+400-20-10 -o macaddr.ps
    convert macaddr.ps -background white -alpha remove -alpha off macaddr.png
    display macaddr.png

    zenity --question --title "以太网硬件打印" --text "以太网地址打印完毕" --width 600 --height 200
    exit 0
fi

if [ $option = "-gc" ] ; then
    _uid="$(id -u)"
    if [ $_uid -ne 0 ]
    then 
        echo "运行以太网硬件地址修改功能需要超级用户权限，请重试"
        exit 0
    fi

    message1="ft-1"
    message2="飞腾内置网卡1"

    message4="ft-2"
    message5="飞腾内置网卡2"
    
    tmp=$(zenity --list --title="以太网卡硬件地址修改工具" --text="以太网卡序号" --column="以太网卡序号" --column="以太网卡序号描述" --column="以太网卡硬件地址" $message1 $message2 $eth1macaddr $message4 $message5 $eth2macaddr --width 600 --height 200)

    case $tmp in
    ft-1)
        ethdef="飞腾内置网卡1"
        ethdev="enaphyt4i0"
        ;;
    ft-2)
        ethdef="飞腾内置网卡2"
        ethdev="enaphyt4i1"
        ;;
    *)
        echo "错误网卡序号，请重新输入"
        exit 1
    esac
    macaddr="$(zenity --entry --title "以太网硬件地址更新" --text "$ethdef" --width 600 --height 200)"

# input mac address checking
    var='^[0-9a-f]+$'
    maclen=${#macaddr}
    if [ $maclen -eq 17 -o $maclen -eq 12 ]
    then
        macaddr2=`echo $eth1macaddr | tr [:upper:] [:lower:]`
        macaddr3=`echo $macaddr2 | tr -d ':'`
        if [[ "$macaddr3" =~ $var ]]
        then
#           echo $macaddr2
            echo $macaddr3
        else
            echo "以太网硬件地址输入错误"
            exit 1
        fi
    else
        echo "以太网地址输入错误"
        exit 1
    fi

# write mac addr to e2rom
# ...

fi
