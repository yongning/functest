#!/bin/bash

# ============================================================================
# global config

_uid="$(id -u)"
if [ $_uid -ne 0 ]
then 
    echo "运行功能测试程序需要超级用户权限，否则无法正常运行，请重试"
    exit
fi

RESULTPATH="testresult"
DATAPATH="data"
WAVFILE="file_wav.wav"
CONFPATH="conf"
CONFFILE="test2.conf"
TEMPPATH="functesttmp"

# REALDIR=$(dirname "$(realpath -s "$0")")
REALDIR=$(dirname "$(realpath "$0")")
# echo $REALDIR

swreq="$(dpkg --list jq 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到jq软件，请通过apt安装]"
    exit 1
fi

swreq="$(dpkg --list atftp 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到atftp软件，请通过apt安装]"
    exit 1
fi

swreq="$(dpkg --list zenity 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到zenity软件，请通过apt安装]"
    exit 1
fi

swreq="$(dpkg --list gnome-terminal 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到gnome-terminal软件，请通过apt安装]"
    exit 1
fi

swreq="$(dpkg --list memtester 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到memtester软件，请通过apt安装]"
    exit 1
fi

if [ ! -f "$REALDIR/$CONFPATH/$CONFFILE" ]; then
    echo "[错误]:[全局配置]:[]:[没有检测到测试配置文件，请检查]"
    exit 1
fi

if [ ! -f "$REALDIR/$DATAPATH/$WAVFILE" ]; then
    echo "[错误]:[全局配置]:[]:[没有检测到测试数据文件，请检查]"
    exit 1
fi

USERNAME="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.global.username')"

test -d "/home/$USERNAME/$RESULTPATH" || mkdir -p "/home/$USERNAME/$RESULTPATH"

if [ -d "/home/$USERNAME/$TEMPPATH" ] ; then
    rm -f /home/$USERNAME/$TEMPPATH/*.data 2>/dev/null
else
    mkdir -p "/home/$USERNAME/$TEMPPATH"
fi

netdev="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.global.netdev')"
eth1macaddr="$(LANG=C ifconfig $netdev | grep -Po 'HWaddr \K.*$' | tr -d ':')"
gmacaddr=`expr substr "$eth1macaddr" 1 12`
# echo $gmacaddr

monthday="$(LANG=C date "+%b%d")"
# echo $monthday

time="$(LANG=C date "+%T" | tr -d ':')"
# echo $time

# echo $gmacaddr$monthday$time

fileprefix="$gmacaddr$monthday$time"
# echo $fileprefix

gserver="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.global.server')"
echo "[信息]:[全局]:[]:[上传服务器地址设置为$gserver]"

#==========================================================================
# test items

audioenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step9.enable')"
if [ $audioenable -eq 1 ]
then
    message1_1="音频测试"
else
    message1_1=
fi

eth1enable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step7.enable')"
if [ $eth1enable -eq 1 ]
then
    message1_2="以太网接口1测试"
else
    message1_2=
fi

eth2enable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step8.enable')"
if [ $eth2enable -eq 1 ]
then
    message1_3="以太网接口2测试"
else
    message1_3=
fi

sataenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step10.enable')"
if [ $sataenable -eq 1 ]
then
    message1_4="SATA第二接口测试"
else
    message1_4=
fi

pcislotenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step11.enable')"
if [ $pcislotenable -eq 1 ]
then
    message1_5="PCIE插槽设备测试"
else
    message1_5=
fi

serialenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step1.enable')"
if [ $serialenable -eq 1 ]
then
    message1_6="串行接口测试"
else
    message1_6=
fi

usbenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step2.enable')"
if [ $usbenable -eq 1 ]
then
    message1_7="USB接口设备检测测试"
else
    message1_7=
fi

usbdatacopyenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step2.datacopy')"
if [ $usbdatacopyenable -eq 1 ]
then
    message1_8="USB接口设数据传输测试"
else
    message1_8=
fi

memtestenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step12.enable')"
if [ $memtestenable -eq 1 ]
then
    message1_9="内存测试"
else
    message1_9=
fi

ltpenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step6.enable')"
if [ $ltpenable -eq 1 ]
then
    message1_10="LTP系统压力测试"
else
    message1_10=
fi

rebootenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step5.enable')"
if [ $rebootenable -eq 1 ]
then
    message1_11="系统重启测试"
else
    message1_11=
fi

zenity --list --title="单板功能测试工具" --text="测试项目" --column="测试项目描述" $message1_1 $message1_2 $message1_3 $message1_4 $message1_5 $message1_6 $message1_7 $message1_8 $message1_9 $message1_10 $message1_11 --width=700 --height=400 --timeout=3

if [ $? -eq 1 -o $? -eq -1 ]
then
    exit 1
fi


# ============================================================================
# cpu mem pci info
cat /proc/cpuinfo > "/home/$USERNAME/$RESULTPATH/$fileprefix.log"

cputmp1="$(cat /proc/cpuinfo | grep "CPU part")"
cputmp2="$(cat /proc/cpuinfo | grep "CPU revision")"
cpunum1="$(echo $cputmp1 | grep -o "0x663" | wc -l)"
cpunum2="$(echo $cputmp2 | grep -o "3" | wc -l)"
echo $cpunum1
echo $cpunum2
if [ $cpunum1 -eq $cpunum2 ] && [ $cpunum1 -eq 4 ]; then
    echo "CPU类型和数量检测正确"
    echo "cpu type and core number ok" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
else
    echo "CPU类型和数量检测错误"
    echo "cpu type and core number error" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
fi

# mem test required?
cat /proc/meminfo >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"

lspci >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"

# ===================================================================================
# audio playback and record
# audioenable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step9.enable')"
if [ $audioenable -eq 1 ]
then
    audiotestok=TRUE
    audioplaytime="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step9.playtime')"
    audiorectime="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step9.rectime')"
    audiotottime=`expr $audiorectime \* 2`
    echo "音频功能测试"
    echo "音频功能测试需要" $audiotottime "秒"
    if [ -f "$REALDIR/$DATAPATH/$WAVFILE" ]
    then
        aplay -d "$audioplaytime" "$REALDIR/$DATAPATH/$WAVFILE" &
    else
        echo "音频播放测试文件不存在，忽略音频播放"
        echo "音频播放测试文件不存在，忽略音频播放" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    fi

    arecord -f cd -d "$audiorectime" "/home/$USERNAME/$RESULTPATH/audio$fileprefix.mov"
    sleep 2
    echo "播放录制音频文件。。。"
    aplay -d "$audiorectime" "/home/$USERNAME/$RESULTPATH/audio$fileprefix.mov"
else
    audiotestok=
    echo "音频功能测试禁止" 
fi


# =====================================================================================
# test ethernet
# eth1enable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step7.enable')"
if [ $eth1enable -eq 1 ]
then
    eth1server="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step7.server')"
#   echo $eth1server
    echo "以太网1功能测试。。。"

    ping -c 5 $eth1server

    if [ $? -eq 0 ]
    then
        eth1testok=TRUE
        echo "以太网1 PING 功能测试正常"
        echo "ethernet1 ping ok" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    else
        eth1testok=FALSE
        echo "以太网1 PING 功能测试错误"
        echo "ethernet1 ping error" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    fi
else
    eth1testok=
    echo "以太网1功能测试禁止"
fi


# eth2enable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step8.enable')"
if [ $eth2enable -eq 1 ]
then
    eth2server="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step8.server')"
#   echo $eth2server
    echo "以太网2功能测试。。。"

    ping -c 5 $eth2server

    if [ $? -eq 0 ]
    then
        eth2testok=TRUE
        echo "以太网2 PING 功能测试正常"
        echo "ethernet2 ping ok" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    else
        eth2testok=FALSE
        echo "以太网2 PING 功能测试错误"
        echo "ethernet2 ping error" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    fi
else
    eth2testok=
    echo "以太网2功能测试禁止"
fi

# =============================================================================
# pcie slot test
if [ $pcislotenable -eq 1 ]
then
    echo "PCIE插槽设备检测"
    pcislotno="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step11.slot')"
    pcislotnum="$(lspci -s $pcislotno | wc -l)"
    if [ $pcislotnum -eq 1 ]
    then
        pcislottestok=TRUE
        echo "PCIE插槽设备检测正常"
        echo "pcie slot device detection normal" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    else
        pcislottestok=FALSE
        echo "PCIE插槽设备检测失败"
        echo "pcie slot device detection error" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    fi    
else
    pcislottestok=
    echo "PCIE插槽设备检测功能禁止"
fi

# ==============================================================================
# 2nd sata interface test
if [ $sataenable -eq 1 ]
then
    echo "SATA第二接口设备检测。。。"
    sata2ndblknum="$(lsblk -l -o name | grep -E "sdb1" | wc -l)"
    # echo $sata2ndblknum
    if [ $sata2ndblknum -eq 1 ]
    then
        satatestok=TRUE
        echo "SATA第二接口设备检测正常"
        echo "SATA 2nd interface device detection normal" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    else
        satatestok=FALSE
        echo "SATA第二接口设备检测失败"
        echo "SATA 2nd interface device detection error" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    fi
else
    satatestok=
    echo "SATA第二接口设备检测禁止"
fi


# ===============================================================================
# serial test
# serialenable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step1.enable')"
if [ $serialenable -eq 1 ]
then
    serialtime="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step1.time')"
    serialnum="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step1.number')"
    serialtottime=`expr $serialtime + 15 + 4`
    serialrxtime=`expr $serialtime + 5`
    echo "串口功能测试。。。"
    echo "时间大约需要" $serialtottime "秒"

    temploop=0
    
    porttemp="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step1.port[]')"
    port=($porttemp)

    # serial interrupt affinity configuration, require root 
    tempirq=0
    tempirq1=0
    irqset=10
    tempdata=0
    while [ $tempirq -lt $serialnum ]
    do
        if [[ ${port[$tempirq]} == "/dev/ttyAMA"* ]] ; then
            
            $REALDIR/serial -s -e -p ${port[$tempirq]} -b 115200 -w 128 -a 50 -i 2 -o 1 -f "/home/$USERNAME/$RESULTPATH/logserialtemp.log" -g "/home/$USERNAME/$RESULTPATH/resserialtemp.log"  >/dev/null 2>/dev/null
            irqset=`expr $irqset + $tempirq1`
            tempdata=`expr $(($tempirq1 + 1)) \* 2`
            tempirq1=`expr $tempirq1 + 1`
            # echo $tempirq1  $tempdata
            # echo $irqset
            echo $tempdata > "/proc/irq/$irqset/smp_affinity"
        fi

        tempirq=`expr $tempirq + 1`
    done
    # end of interrupt affinity

    while [ $temploop -lt $serialnum ]
    do
        # echo ${port[$temploop]}
        if [[ ${port[$temploop]} == "/dev/ttyAMA"* ]] ; then
            echo "飞腾内置串口测试"
            sleep $serialrxtime
            echo "ft2000 internal serial testing" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
            gnome-terminal -- /bin/bash -c "$REALDIR/serial -s -e -p ${port[$temploop]} -b 115200 -w 128 -a 70 -i $serialrxtime -o $serialtime -f "/home/$USERNAME/$RESULTPATH/log$temploop.log" -g "/home/$USERNAME/$RESULTPATH/res$temploop.log"; exec bash"
            # sleep 1
        else
            echo "PCIE转接串口测试"
            echo "pcie to serial port testing" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
            gnome-terminal -- /bin/bash -c "$REALDIR/serial -s -e -p ${port[$temploop]} -b 115200 -w 512 -i $serialrxtime -o $serialtime -f "/home/$USERNAME/$RESULTPATH/log$temploop.log" -g "/home/$USERNAME/$RESULTPATH/res$temploop.log"; exec bash"
            sleep 1
        fi
        temploop=`expr $temploop + 1`
    done
    
    sleep $serialtottime

    serialtestok=TRUE

    temploop1=0
    while [ $temploop1 -lt $serialnum ]
    do
        # cat "/home/$USERNAME/$RESULTPATH/res$temploop1.log"
        serialresult="$(cat "/home/$USERNAME/$RESULTPATH/res$temploop1.log")"
        # echo $serialresult
        if [ $serialresult -ne 0 ]
        then
            serialtestok=FASLE
            echo $temploop1 "串口测试错误"
        else
            echo $temploop1 "串口测试正常"
        fi

        cat "/home/$USERNAME/$RESULTPATH/log$temploop1.log" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
        cat "/home/$USERNAME/$RESULTPATH/res$temploop1.log" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
        rm "/home/$USERNAME/$RESULTPATH/log$temploop1.log"
        rm "/home/$USERNAME/$RESULTPATH/res$temploop1.log"
        temploop1=`expr $temploop1 + 1`
    done

   # serialtestresult="$(/home/$USERNAME/test_bench/serial)"
   # echo $serialtestresult
   # echo $serialtestresult >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
else
    serialtestok=
    echo "串口功能测试禁止"
fi

# ==============================================================================
# usb test

# usbenable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step2.enable')"
if [ $usbenable -eq 1 ]
then

    usb3disknum="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step3.number')"
    # echo $usb3disknum

    usb3disktemp=0

    usb2disknum="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step4.number')"
    # echo $usb2disknum

    usbdisktemp=`expr $usb3disknum + $usb2disknum`
    echo "USB接口配置设备数量是" $usbdisktemp


    # if sata interface check
    if [ $sataenable -eq 1 ]
    then
        blknum="$(lsblk -l -o name | grep -E "sd[c-r].{1,}" | wc -l)"
        # echo $blknum

        blkdata="$(lsblk -l -o name | grep -E "sd[c-r].{1,}")"
        # echo $blkdata
    else
        blknum="$(lsblk -l -o name | grep -E "sd[b-q].{1,}" | wc -l)"
        # echo $blknum

        blkdata="$(lsblk -l -o name | grep -E "sd[b-q].{1,}")"
        # echo $blkdata
    fi

    # else no sata interface check

    if [ $usbdisktemp -eq $blknum ]
    then
        usbtestok=TRUE
        echo "[信息]:[USB接口检测]:[]:[USB接口设备检测正常]"
        echo "[INFO]:[USB detect]:[]:[all $blknum usb interface disk device detect normal]" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    else
        usbtestok=FALSE
        echo "[错误]:[USB接口检测]:[]:[USB接口设备数量检测错误]"
        echo "[ERROR]:[USB detect]:[]:[$blknum usb interface disk device miss]" >> "/home/gwi/testresult/$fileprefix.log"
    fi

    if [ $usbdatacopyenable -eq 1 ]
    then
        timetotal=`expr $usb3disknum \* 10 + $usb2disknum \* 27`
        # echo $timetotal
        echo "USB接口设备数据传输测试。。。大约需要" $timetotal "秒"
        timereal=0

        if [ $sataenable -eq 1 ]
        then
            lsblk -l -o name | grep -E "sd[c-r].{1,}" | while IFS= read -r line
            do
                # echo "$line"
                devtemp="/dev/""$line"
                # echo $devtemp
                mkdir -p "/home/$USERNAME/$line"
                mount $devtemp "/home/$USERNAME/$line"
    
                start_time=`date +%s`
                cp -f "/home/$USERNAME/$line/usbfile.data" "/home/$USERNAME/$TEMPPATH/$line.data"
                sync
                end_time=`date +%s`
                timeinv=`expr $end_time - $start_time`
                # echo $timeinv
                timereal=`expr $timeinv + $timereal`
                echo $timereal > "/home/$USERNAME/$TEMPPATH/time.data"
                umount "/home/$USERNAME/$line"
                rmdir "/home/$USERNAME/$line"
            done 
        else
            lsblk -l -o name | grep -E "sd[b-q].{1,}" | while IFS= read -r line
            do
                # echo "$line"
                devtemp="/dev/""$line"
                # echo $devtemp
                mkdir -p "/home/$USERNAME/$line"
                mount $devtemp "/home/$USERNAME/$line"
    
                start_time=`date +%s`
                cp -f "/home/$USERNAME/$line/usbfile.data" "/home/$USERNAME/$TEMPPATH/$line.data"
                sync
                end_time=`date +%s`
                timeinv=`expr $end_time - $start_time`
                # echo $timeinv
                timereal=`expr $timeinv + $timereal`
                echo $timereal > "/home/$USERNAME/$TEMPPATH/time.data"
                umount "/home/$USERNAME/$line"
                rmdir "/home/$USERNAME/$line"
            done
        fi

        timereal="$(cat "/home/$USERNAME/$TEMPPATH/time.data")"
        echo $timereal

        if [ $timereal -gt $timetotal ]
        then
            usbdatacopytestok=FALSE
            echo "[错误]:[USB接口速度]:[]:[USB接口存储设备文件拷贝超时，可能存在错误]"
            echo "[ERROR]:[USB speed]:[]:[usb storage data copy time exceed, maybe error]" >> "/home/$USERNAME/$RESULTPATH/$filprefix.log"
        else
            usbdatacopytestok=TRUE
            echo "[信息]:[USB接口速度]:[]:[USB接口存储设备文件拷贝时间正常]"
            echo "[INFO]:[USB speed]:[]:[usb storage data copy time normal]" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
        fi
    else
        usbdatacopytestok=
        echo "[信息]:[USB接口速度]:[]:[USB接口设备数据传输测试禁止]"
        echo "[INFO]:[USB speed]:[]:[USB interface speed test function disable]" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    fi
else
    usbtestok=
    echo "[信息]:[USB接口]:[]:[USB接口测试禁止]"
    echo "[INFO]:[USB interface]:[]:[USb interface function test disable]"
fi

# ======================================================================================
# memtest
if [ $memtestenable -eq 1 ]
then
    memtestok=TRUE
    memtestsize="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step12.size')"
    memtesttime="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step12.time')"
    memtester $memtestsize $memtesttime
    if [ $? -ne 0 ]; then
        memtestok=FALSE
        echo "内存测试失败"
        echo "memtest $memtestsize $memtesttime error" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    else
        echo "内存测试正常"
        echo "memtest $memtestsize $memtesttime normal" >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
    fi
else
    memtestok=
    echo "内存测试禁止"
fi

# ======================================================================================

# =======================================================================================
# ltp stress test
if [ $ltpenable -eq 1 ]
then
    ltptestok=TRUE
    ltphours="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step6.time')"
    echo "LTP压力测试。。。" $ltphours "小时"
    cd /opt/ltp/testscripts
    ./run_ltp_test.sh $ltphours    
else
    ltptestok=
    echo "LTP压力测试禁止"
fi

# ========================================================================================
# upload log and result file to server
logfileupload="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.global.logupload')"
if [ $logfileupload -eq 1 ]
then
    echo "上传记录文件至服务器"
    atftp -p -l "/home/$USERNAME/$RESULTPATH/$fileprefix.log" -r "$fileprefix.log" $gserver
    atftp -p -l "/home/$USERNAME/$RESULTPATH/audio$fileprefix.mov" -r "audio$fileprefix.mov" $gserver
else
    echo "记录文件不上传"
fi

# =========================================================================================

zenity --list --title="单板功能测试工具" --text "单板功能测试结果" --checklist --column "测试结果" --column "测试功能描述" $audiotestok $message1_1 $eth1testok $message1_2 $eth2testok $message1_3 $satatestok $message1_4 $pcislottestok $message1_5 $serialtestok $message1_6 $usbtestok $message1_7 $usbdatacopytestok $message1_8 $memtestok $message1_9 $ltptestok $message1_10 --width=700 --height=400

# ========================================================================================
# reboot test


# rebootenable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step5.enable')"
if [ $rebootenable -eq 1 ]
then
    rebootnumdef="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step5.number')"
    echo $rebootnumdef

    rebootcurnum=0

    if [ ! -e "/home/$USERNAME/$RESULTPATH/rebootnum.data" ]
    then
        echo 0 > "/home/$USERNAME/$RESULTPATH/rebootnum.data"
        chmod 777 "/home/$USERNAME/$RESULTPATH/rebootnum.data"
        cp "$REALDIR/reboottest/reboottest.service" /etc/systemd/system/reboottest.service
        chmod 777 /etc/systemd/system/reboottest.service
        systemctl daemon-reload
        systemctl enable reboottest.service
    else
        read line < "/home/$USERNAME/$RESULTPATH/rebootnum.data"
        rebootcurnum=`expr $line + 1`
        echo $rebootcurnum
        echo $rebootcurnum > "/home/$USERNAME/$RESULTPATH/rebootnum.data"
    fi

    if [ $rebootcurnum -gt $rebootnumdef ]
    then
        echo "reboot test succeed"
        mv "/home/$USERNAME/$RESULTPATH/rebootnum.data" "/home/$USERNAME/$RESULTPATH/rebootnumbak.data"
        rm /etc/systemd/system/reboottest.service
        systemctl daemon-reload
    else
        reboot
    fi
else
    echo "重启测试禁止"
fi

# ==============================================================================================
# end of function test
