#!/bin/bash
# ============================================================================
# global config
function zenerror {
    if [ $zenerrorenable -eq 1 ] ; then
        zenity --error --text="$errormsg" --width=600 --height=200
        exit 1
    fi
}


_uid="$(id -u)"
if [ $_uid -ne 0 ]
then 
    echo "运行功能测试程序需要超级用户权限，否则无法正常运行，请重试"
    exit
fi

RESULTPATH="/var/log/functestresult"
DATAPATH="data"
WAVFILE="file_wav.wav"
CONFPATH="conf"
CONFFILE="test2.conf"
TEMPPATH="functesttmp"

# REALDIR=$(dirname "$(realpath -s "$0")")
REALDIR=$(dirname "$(realpath "$0")")

swreq="$(dpkg --list jq 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到jq软件，请通过apt安装,测试程序即将退出]"
    sleep 5
    exit 1
fi

if [ ! -f "$REALDIR/$CONFPATH/$CONFFILE" ]; then
    echo "[错误]:[全局配置]:[]:[没有检测到测试配置文件，请检查,测试程序即将退出]"
    sleep 5
    exit 1
fi

netdev="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.global.netdev')"
if [ $netdev = "null" ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到全局网络接口配置，请检查，测试程序即将退出]"
    sleep 5
    exit 1
fi

eth1macaddr="$(LANG=C ifconfig $netdev | grep -Po 'HWaddr \K.*$' | tr -d ':')"
if [ -z $eth1macaddr ] ; then
    echo "[错误]:[全局配置]:[]:[配置全局网络接口获取设备信息错误，请检查，测试程序即将退出]"
    sleep 5
    exit 1
fi 
gmacaddr=`expr substr "$eth1macaddr" 1 12`
# echo $gmacaddr

monthday="$(LANG=C date "+%b%d")"
# echo $monthday
time="$(LANG=C date "+%T" | tr -d ':')"
# echo $time
# echo $gmacaddr$monthday$time

fileprefix="$gmacaddr$monthday$time"
# echo $fileprefix

USERNAME="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.global.username')"
[ $USERNAME != "null" ] && RESULTPATH="$RESULTPATH/$USERNAME"
# echo $RESULTPATH
test -d $RESULTPATH || mkdir -p $RESULTPATH
touch "$RESULTPATH/$fileprefix.log"
if [ -d "$RESULTPATH/$TEMPPATH" ] ; then
    rm -f $RESULTPATH/$TEMPPATH/*.data 2>/dev/null
else
    mkdir -p "$RESULTPATH/$TEMPPATH"
fi

gserver="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.global.server')"
if [ $gserver = "null" ] ; then
    echo "[错误]:[全局配置]:[];[请正确配置全局上报服务起地址，测试程序即将退出]"
    echo "[ERROR]:[Global]:[]:[Please configure global upload server address, application will exit]" >> "$RESULTPATH/$fileprefix.log"
    sleep 5
    exit 1
fi
echo "[信息]:[全局]:[]:[上传服务器地址设置为$gserver]"
echo "[INFO]:[Global]:[]:[Global upload server address is $gserver]" >> "$RESULTPATH/$fileprefix.log"

swreq="$(dpkg --list atftp 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到atftp软件，请通过apt安装,测试程序即将退出]"
    echo "[ERROR]:[Global]:[]:[atftp not installed, please install, application will exit]" >> "$RESULTPATH/$fileprefix.log" 
    exit 1
fi

swreq="$(dpkg --list alsa-utils 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到音频alsa软件，请通过apt安装,测试程序即将退出]"
    echo "[ERROR]:[Global]:[]:[alsa-utils not installed, please install, application will exit]" >> "$RESULTPATH/$fileprefix.log" 
    exit 1
fi

swreq="$(dpkg --list zenity 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到zenity软件，请通过apt安装]"
    echo "[ERROR]:[Global]:[]:[zenity not installed, please install, application will exit]" >> "$RESULTPATH/$fileprefix.log" 
    exit 1
fi

swreq="$(dpkg --list gnome-terminal 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到gnome-terminal软件，请通过apt安装]"
    echo "[ERROR]:[Global]:[]:[gnome-terminal not installed, please install, application will exit]" >> "$RESULTPATH/$fileprefix.log" 
    exit 1
fi

swreq="$(dpkg --list memtester 2>/dev/null | grep -w ii | wc -l)"
if [ $swreq -ne 1 ] ; then
    echo "[错误]:[全局配置]:[]:[没有检测到memtester软件，请通过apt安装]"
    echo "[ERROR]:[Global]:[]:[memtest not installed, please install, application will exit]" >> "$RESULTPATH/$fileprefix.log" 
    exit 1
fi
#==========================================================================
# test items
sysmemenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step14.enable')"
if [ $sysmemenable -eq 1 ]
then
    message1_1="系统内存容量和系统日期检测测试"
else
    message1_1=
fi

audioenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step9.enable')"
if [ $audioenable -eq 1 ]
then
    message1_2="音频测试"
else
    message1_2=
fi

eth1enable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step7.enable')"
if [ $eth1enable -eq 1 ]
then
    message1_3="以太网接口1测试"
else
    message1_3=
fi

eth2enable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step8.enable')"
if [ $eth2enable -eq 1 ]
then
    message1_4="以太网接口2测试"
else
    message1_4=
fi

sataenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step10.enable')"
if [ $sataenable -eq 1 ]
then
    message1_5="SATA第二接口测试"
else
    message1_5=
fi

pcislotenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step11.enable')"
if [ $pcislotenable -eq 1 ]
then
    message1_6="PCIE插槽设备测试"
else
    message1_6=
fi

serialenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step1.enable')"
if [ $serialenable -eq 1 ]
then
    message1_7="串行接口测试"
else
    message1_7=
fi

prnenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step13.enable')"
if [ $prnenable -eq 1 ]
then
    message1_8="并行打印接口设备检测测试"
else
    message1_8=
fi

usbenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step2.enable')"
if [ $usbenable -eq 1 ]
then
    message1_9="USB接口设备检测测试"
else
    message1_9=
fi

usbdatacopyenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step2.datacopy')"
if [ $usbdatacopyenable -eq 1 ]
then
    message1_10="USB接口设数据传输测试"
else
    message1_10=
fi

memtestenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step12.enable')"
if [ $memtestenable -eq 1 ]
then
    message1_11="内存稳定性测试"
else
    message1_11=
fi

ltpenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step6.enable')"
if [ $ltpenable -eq 1 ]
then
    message1_12="LTP系统压力测试"
else
    message1_12=
fi

rebootenable="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step5.enable')"
if [ $rebootenable -eq 1 ]
then
    message1_13="系统重启测试"
else
    message1_13=
fi

zenity --list --title="单板功能测试工具" --text="测试项目" --column="测试项目描述" $message1_1 $message1_2 $message1_3 $message1_4 $message1_5 $message1_6 $message1_7 $message1_8 $message1_9 $message1_10 $message1_11 $message1_12 $message1_13 --width=700 --height=500 --timeout=5

if [ $? -eq 1 -o $? -eq -1 ]
then
    exit 1
fi

echo "[INFO]:[Global]:[]:[testing items are $message1_1 $message1_2 $message1_3 $message1_4 $message1_5 $message1_6 $message1_7 $message1_8 $message1_9 $message1_10 $message1_11 $message1_12 $message1_13]" >> "$RESULTPATH/$fileprefix.log"

testtypetmp="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.global.testtype')"
if [ $testtypetmp = 'factfunc' ] ; then
    zenerrorenable=1
else
    zenerrorenable=0
fi

if [ $testtypetmp = 'factstable' ] ; then
    gnome-terminal -- /bin/bash -c "$REALDIR/gpioblink.sh; exec bash"
fi

# ============================================================================
# cpu mem pci info
echo "[INFO]:[General]:[]:[" >> "$RESULTPATH/$fileprefix.log"
cat /proc/cpuinfo >> "$RESULTPATH/$fileprefix.log"
echo "]" >> "$RESULTPATH/$fileprefix.log"

cputmp1="$(cat /proc/cpuinfo | grep "CPU part")"
cputmp2="$(cat /proc/cpuinfo | grep "CPU revision")"
cpunum1="$(echo $cputmp1 | grep -o "0x663" | wc -l)"
cpunum2="$(echo $cputmp2 | grep -o "3" | wc -l)"
# echo $cpunum1
# echo $cpunum2
if [ $cpunum1 -eq $cpunum2 ] && [ $cpunum1 -eq 4 ]; then
    echo "[信息]:[通用]:[CPU]:[CPU类型和数量检测正确]"
    echo "[INFO]:[General]:[CPU]:[cpu type and core number $cpunum1 are ok]" >> "$RESULTPATH/$fileprefix.log"
else
    echo "[错误]:[通用]:[CPU]:[CPU类型和数量检测错误]"
    echo "[ERROR]:[General]:[CPU]:[cpu type and core number error]" >> "$RESULTPATH/$fileprefix.log"
    errormsg="错误 CPU类型或者数量检测错误"
    zenerror
fi

# mem test required?
echo "[INFO]:[General]:[Memory]:[" >> "$RESULTPATH/$fileprefix.log"
cat /proc/meminfo >> "$RESULTPATH/$fileprefix.log"
echo "]" >> "$RESULTPATH/$fileprefix.log"

if [ $sysmemenable -eq 1 ] ; then
    sysmemdef="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step14.memnum')"
    sysmemnum="$(cat /proc/meminfo | grep MemTotal | grep -Po "[0-9]*")"
    if [ $sysmemnum -gt $sysmemdef ]
    then
        echo "[信息]:[通用]:[内存]:[系统内存 $sysmemum 检测正常]"
        echo "[INFO]:[General]:[Mem]:[system memory $sysmemnum normal]" >> "$RESULTPATH/$fileprefix.log"
        sysmemtestok=TRUE
    else
        echo "[错误]:[通用]:[内存]:[系统内存 $sysmemnum 检测错误]"
        echo "[ERROR]:[General]:[Mem]:[system memory $sysmemnum error]" >> "$RESULTPATH/$fileprefix.log"
        sysmemtestok=FALSE
        errormsg="错误 系统内存检测错误"
        zenerror
    fi

    systimedef="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step14.date')"
    systimenow="$(date "+%Y%m")"
    echo $systimedef
    echo $systimenow
    if [ $systimenow -lt $systimedef ] ; then
        echo "[错误]:[通用]:[系统时间]:[系统时间设定错误]"
        echo "[ERROR]:[General]:[Time]:[system time $systemnow error]" >> "$RESULTPATH/$fileprefix.log"
        sysmemtestok=FALSE
        errormsg="错误 系统当前时间早于设定时间"
        zenerror
    else
        echo "[信息]:[通用]:[系统时间]:[系统时间设定正确]"
        echo "[INFO]:[General]:[Time]:[System time $systemnow normal]" >> "$RESULTPATH/$fileprefix.log"
        sysmemtestok=TRUE
    fi

else
    sysmemtestok=
    echo "[信息]:[系统内存容量检测]:[]:[系统内存容量和设定时间检测功能禁止]" 
fi

echo "[INFO]:[General]:[PCI]:[" >> "$RESULTPATH/$fileprefix.log"
lspci >> "$RESULTPATH/$fileprefix.log"
echo "]" >> "$RESULTPATH/$fileprefix.log"

# ===================================================================================
# audio playback and record
# audioenable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step9.enable')"
if [ $audioenable -eq 1 ]
then
    audiotestok=TRUE
    audioplaytime="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step9.playtime')"
    audiorectime="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step9.rectime')"
    audiotottime=`expr $audiorectime \* 2`
    echo "[信息]:[音频功能]:[]:[音频第一接口功能测试,测试大约需要 $audiotottime 秒]"
    if [ -f "$REALDIR/$DATAPATH/$WAVFILE" ]
    then
        aplay -d "$audioplaytime" "$REALDIR/$DATAPATH/$WAVFILE" &
    else
        echo "[警告]:[音频功能]:[]:[音频播放测试文件不存在，忽略音频播放]"
        echo "[WARN]:[Audio]:[]:[Audo playback data file does not exist, ignore audio playback]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="警告 音频播放测试文件不存在"
        zenerror
    fi

    arecord -f cd -d "$audiorectime" "$RESULTPATH/audio$fileprefix.mov"
    sleep 2
    echo "[信息]:[音频功能]:[]:[播放录制音频文件。。。]"
    aplay -d "$audiorectime" "$RESULTPATH/audio$fileprefix.mov"
   
    zenity --question --width=700 --title="音频第一接口测试" --text="您是否正确听到播放和录制音频" --timeout=10
    if [ $? -eq 1 -o $? -eq -1 ]
    then
        audiotestok=FALSE
        echo "[错误]:[音频功能]:[]:[音频第一接口播放或录制异常]"
        echo "[ERROR]:[Audio]:[]:[Audio 1st interface playback or record error]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="错误 音频第一接口播放或录制错误"        
        zenerror
    else
        echo "[信息]:[音频功能]:[]:[音频第一接口播放或录制正常]"
        echo "[INFO]:[Audio]:[]:[Audio 1st interface playback or record succeeds]" >> "$RESULTPATH/$fileprefix.log"
    fi

    audio2ndintf="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step9.intfsec')"
    if [ $audio2ndintf -eq 1 ]
    then
        sleep 10
        echo "[信息]:[音频功能]:[]:[音频第二接口功能测试,测试大约需要 $audiotottime 秒]"
        if [ -f "$REALDIR/$DATAPATH/$WAVFILE" ]
        then
            aplay -d "$audioplaytime" "$REALDIR/$DATAPATH/$WAVFILE" &
        else
            echo "[警告]:[音频功能]:[音频播放测试文件不存在，忽略音频播放]"
            echo "[WARN]:[Audio]:[]:[Audo playback data file does not exist, ignore audio playback]" >> "$RESULTPATH/$fileprefix.log"
            errormsg="警告 音频播放文件存在"
            zenerror
        fi

        arecord -f cd -d "$audiorectime" "$RESULTPATH/audio2ndintf$fileprefix.mov"
        sleep 2
        echo "[信息]:[音频功能]:[]:[播放录制音频文件。。。]"
        aplay -d "$audiorectime" "$RESULTPATH/audio2ndintf$fileprefix.mov"

        zenity --question --width=700 --title="音频第二接口测试" --text="您是否正确听到播放和录制音频" --timeout=10
        if [ $? -eq 1 -o $? -eq -1 ]
        then
            audiotestok=FALSE
            echo "[错误]:[音频功能]:[]:[音频第二接口播放或录制异常]"
            echo "[ERROR]:[Audio]:[]:[Audio 2nd interface playback or record error]" >> "$RESULTPATH/$fileprefix.log"
            errormsg="错误 音频第二接口播放或录制错误"
            zenerror
        else
            echo "[信息]:[音频功能]:[]:[音频第二接口播放或录制正常]"
            echo "[INFO]:[Audio]:[]:[Audio 2nd interface playback or record succeeds]" >> "$RESULTPATH/$fileprefix.log"
        fi
    fi

else
    audiotestok=
    echo "[信息]:[音频功能]:[]:[音频功能测试禁止]" 
fi


# =====================================================================================
# test ethernet
# eth1enable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step7.enable')"
if [ $eth1enable -eq 1 ]
then
    eth1server="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step7.server')"
    eth1devname="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step7.devname')"
#   echo $eth1server
    echo "[信息]:[以太网1]:[]:[以太网1功能测试。。。]"

    ping -c 5 $eth1server

    if [ $? -eq 0 ]
    then
        eth1testok=TRUE
        echo "[信息]:[以太网1]:[]:[以太网1 PING 功能测试正常]"
        echo "[INFO]:[ethernet1]:[]:[Ethernet 1 ping ok]" >> "$RESULTPATH/$fileprefix.log"
    else
        eth1testok=FALSE
        echo "[错误]:[以太网1]:[]:[以太网1PING 功能测试错误]"
        echo "[ERROR]:[ethernet1]:[]:[Ethernet 1 ping error]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="错误 以太网接口1 PING功能测试错误"
        zenerror
    fi

    eth1speed="$(ethtool $eth1devname | grep "Speed: ")"
    echo $eth1speed
    eth1speedtmp=${eth1speed:8:4}
    echo $eth1speedtmp
    if [ $eth1speedtmp -ne 1000 ] ; then
        eth1testok=FALSE
        echo "[错误]:[以太网1]:[]:[以太网接口1速率协商错误]"
        echo "[ERROR]:[ethernet1]:[]:[Ethernet 1 speed error]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="错误 以太网接口1速率协商错误"
        zenerror
    else
        eth1testok=TRUE
        echo "[信息]:[以太网1]:[]:[以太网1接口速率协商正确]"
        echo "[INFO]:[ethernet1]:[]:[Ethernet 1 speed right]" >> "$RESULTPATH/$fileprefix.log"
    fi
else
    eth1testok=
    echo "[信息]:[以太网1]:[]:[以太网1功能测试禁止]"
fi


# eth2enable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step8.enable')"
if [ $eth2enable -eq 1 ]
then
    eth2server="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step8.server')"
#   echo $eth2server
    eth2devname="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step8.devname')"
    echo "[信息]:[以太网2]:[]:[以太网2功能测试。。。]"

    ping -c 5 $eth2server

    if [ $? -eq 0 ]
    then
        eth2testok=TRUE
        echo "[信息]:[以太网2]:[]:[以太网2 PING 功能测试正常]"
        echo "[INFO]:[ethernet2]:[]:[Ethernet 2 ping ok]" >> "$RESULTPATH/$fileprefix.log"
    else
        eth2testok=FALSE
        echo "[错误]:[以太网2]:[]:[以太网2 PING 功能测试错误]"
        echo "[ERROR]:[ethernet2]:[]:Ethernet 2 ping error]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="错误 以太网接口2 PING功能测试错误"
        zenerror
    fi

    eth2speed="$(ethtool $eth2devname | grep "Speed: ")"
    echo $eth2speed
    eth2speedtmp=${eth2speed:8:4}
    echo $eth2speedtmp
    if [ $eth2speedtmp -ne 1000 ] ; then
        eth2testok=FALSE
        echo "[错误]:[以太网2]:[]:[以太网接口2速率协商错误]"
        echo "[ERROR]:[ethernet2]:[]:[Ethernet 2 speed error]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="错误 以太网接口2速率协商错误"
        zenerror
    else
        eth2testok=TRUE
        echo "[信息]:[以太网2]:[]:[以太网2接口速率协商正确]"
        echo "[INFO]:[ethernet2]:[]:[Ethernet 2 speed right]" >> "$RESULTPATH/$fileprefix.log"
    fi
else
    eth2testok=
    echo "[信息]:[以太网2]:[]:[以太网2功能测试禁止]"
fi

# =============================================================================
# pcie slot test
if [ $pcislotenable -eq 1 ]
then
    echo "[信息]:[PCIE插槽]:[]:[PCIE插槽设备检测...]"
    pcislotno="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step11.slot')"
    pcislotnum="$(lspci -s $pcislotno | wc -l)"
    if [ $pcislotnum -eq 1 ]
    then
        pcislottestok=TRUE
        echo "[信息]:[PCIE插槽]:[]:[PCIE插槽设备检测正常]"
        echo "[INFO]:[PCIE slot]:[]:[pcie slot device detection normal]" >> "$RESULTPATH/$fileprefix.log"
    else
        pcislottestok=FALSE
        echo "[错误]:[PCIE插槽]:[]:[PCIE插槽设备检测失败]"
        echo "[ERROR]:[PCIE slot]:[]:[pcie slot device detection error]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="错误 PCIE插槽设备检测失败"
        zenerror
    fi    
else
    pcislottestok=
    echo "[信息]:[PCIE插槽]:[]:[PCIE插槽设备检测功能禁止]"
fi

# ==============================================================================
# 2nd sata interface test
if [ $sataenable -eq 1 ]
then
    echo "[信息]:[SATA第二接口]:[]:[SATA第二接口设备检测。。。]"
    sata2ndblknum="$(lsblk -l -o name | grep -E "sdb1" | wc -l)"
    # echo $sata2ndblknum
    if [ $sata2ndblknum -eq 1 ]
    then
        satatestok=TRUE
        echo "[信息]:[SATA第二接口]:[]:[SATA第二接口设备检测正常]"
        echo "[INFO]:[SATA 2nd interface]:[]:[SATA 2nd interface device detection normal" >> "$RESULTPATH/$fileprefix.log"
    else
        satatestok=FALSE
        echo "[错误]:[SATA第二接口]:[]:[SATA第二接口设备检测失败]"
        echo "[ERROR]:[SATA 2nd interface]:[]:[SATA 2nd interface device detection error]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="错误 SATA接口2设备检测失败"
        zenerror
    fi
else
    satatestok=
    echo "[信息]:[SATA第二接口]:[]:[SATA第二接口设备检测禁止]"
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
    echo "[信息]:[串口]:[]:[串口功能测试。。。]"
    echo "[信息]:[串口]:[]:[串口功能测试时间大约需要 $serialtottime 秒]"

    temploop=0
    
    porttemp="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step1.port[]')"
    port=($porttemp)

    # serial interrupt affinity configuration, require root 
    # temporary disable serial irq affinity since no usage Jul09

    # tempirq=0
    # tempirq1=0
    # irqset=10
    # tempdata=0
    # while [ $tempirq -lt $serialnum ]
    # do
    #    if [[ ${port[$tempirq]} == "/dev/ttyAMA"* ]] ; then
            
    #        $REALDIR/serial -s -e -p ${port[$tempirq]} -b 115200 -w 128 -a 50 -i 2 -o 1 -f "$RESULTPATH/logserialtemp.log" -g "$RESULTPATH/resserialtemp.log"  >/dev/null 2>/dev/null
    #        irqset=`expr $irqset + $tempirq1`
    #        tempdata=`expr $(($tempirq1 + 1)) \* 2`
    #        tempirq1=`expr $tempirq1 + 1`
    #        # echo $tempirq1  $tempdata
    #        # echo $irqset
    #        echo $tempdata > "/proc/irq/$irqset/smp_affinity"
    #    fi

    #    tempirq=`expr $tempirq + 1`
    # done
    
    # end of interrupt affinity

    while [ $temploop -lt $serialnum ]
    do
        # echo ${port[$temploop]}
        if [[ ${port[$temploop]} == "/dev/ttyAMA"* ]] ; then
            echo "[信息]:[串口]:[]:[飞腾内置串口测试]"
            sleep $serialrxtime
            echo "[INFO]:[Serial]:[]:[ft2000 internal serial testing]" >> "$RESULTPATH/$fileprefix.log"
            gnome-terminal -- /bin/bash -c "$REALDIR/serial -s -e -p ${port[$temploop]} -b 115200 -w 128 -a 70 -i $serialrxtime -o $serialtime -f "$RESULTPATH/log$temploop.log" -g "$RESULTPATH/res$temploop.log"; exec bash"
            # sleep 1
        else
            echo "[信息]:[串口]:[]:[PCIE或USB转接串口测试]"
            echo "[INFO]:[Serial]:[]:[pcie/usb to serial port testing]" >> "$RESULTPATH/$fileprefix.log"
            gnome-terminal -- /bin/bash -c "$REALDIR/serial -s -e -p ${port[$temploop]} -b 115200 -w 512 -i $serialrxtime -o $serialtime -f "$RESULTPATH/log$temploop.log" -g "$RESULTPATH/res$temploop.log"; exec bash"
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
        serialresult="$(cat "$RESULTPATH/res$temploop1.log")"
        # echo $serialresult
        if [ $serialresult -ne 0 ]
        then
            serialtestok=FASLE
            echo "[错误]:[串口]:[]:[$temploop1 串口测试错误]"
            echo "[ERROR]:[Serial]:[]:[$temploop1 serial testing error]" >> "$RESULTPATH/$fileprefix.log"
            errormsg="错误 串口数据接收发送测试错误"
            zenerror
        else
            echo "[信息]:[串口]:[]:[$temploop1 串口测试正常]"
            echo "[INFO]:[Serial]:[]:[$temploop1 serial testing succeeds]" >> "$RESULTPATH/$fileprefix.log"
        fi

        cat "$RESULTPATH/log$temploop1.log" >> "$RESULTPATH/$fileprefix.log"
        cat "$RESULTPATH/res$temploop1.log" >> "$RESULTPATH/$fileprefix.log"
        rm "$RESULTPATH/log$temploop1.log"
        rm "$RESULTPATH/res$temploop1.log"
        temploop1=`expr $temploop1 + 1`
    done

   # serialtestresult="$(/home/$USERNAME/test_bench/serial)"
   # echo $serialtestresult
   # echo $serialtestresult >> "/home/$USERNAME/$RESULTPATH/$fileprefix.log"
else
    serialtestok=
    echo "[信息]:[串口]:[]:[串口功能测试禁止]"
fi

# =============================================================================
# prn test
if [ $prnenable -eq 1 ]
then
    echo "[信息]:[打印并口]:[]:[打印并口功能检测]"
    if [ ! -e "/dev/usb/lp0" ] ; then
        echo "[错误]:[打印并口]:[]:[打印并口检测失败]"
        echo "[ERROR]:[PRN Interface]:[]:[prn interface detection error]" >> "$RESULTPATH/$fileprefix.log"
        prntestok=FASLE
        errormsg="错误 USB转并行打印接口设备检测错误"
        zenerror
    else
        echo "[信息]:[打印并口]:[]:[打印并口检测正常]"
        echo "[INFO]:[PRN Interface]:[]:[prn interface detection succeeds]" >> "$RESULTPATH/$fileprefix.log"
        prntestok=TRUE
    fi
    
    # real print test 
    sleep 2
    echo "------------------------------------" > /dev/usb/lp0
    echo $(LANG=C date) > /dev/usb/lp0
    echo "$fileprefix" > /dev/usb/lp0

    zenity --question --width=700 --title="打印接口测试" --text="您是否观察到打印机正常打印" --timeout=10
        if [ $? -eq 1 -o $? -eq -1 ]
        then
            audiotestok=FALSE
            echo "[错误]:[打印并口]:[]:[打印接口实际打印异常]"
            echo "[ERROR]:[PRN Interface]:[]:[PRN interface print error]" >> "$RESULTPATH/$fileprefix.log"
            errormsg="错误 打印接口实际打印错误"
            zenerror
        else
            echo "[信息]:[打印并口]:[]:[打印接口实际打印正常]"
            echo "[INFO]:[PRN Interface]:[]:[Print interface print succeeds]" >> "$RESULTPATH/$fileprefix.log"
        fi
else
    prntestok=
    echo "[信息]:[打印并口]:[]:[打印并口检测功能禁止]"
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
    # echo "USB接口配置设备数量是" $usbdisktemp


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
        echo "[INFO]:[USB detect]:[]:[all $blknum usb interface disk device detect normal]" >> "$RESULTPATH/$fileprefix.log"
    else
        usbtestok=FALSE
        echo "[错误]:[USB接口检测]:[]:[USB接口设备数量检测错误]"
        echo "[ERROR]:[USB detect]:[]:[$blknum usb interface disk device miss]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="错误 USB接口设备数量检测错误"
        zenerror
    fi

    if [ $usbdatacopyenable -eq 1 ]
    then
        timetotal=`expr $usb3disknum \* 10 + $usb2disknum \* 27`
        # echo $timetotal
        echo "[信息]:[USB接口设备数据传输]:[]:[USB接口设备数据传输测试。。。大约需要 $timetotal 秒]"
        timereal=0

        if [ $sataenable -eq 1 ]
        then
            lsblk -l -o name | grep -E "sd[c-r].{1,}" | while IFS= read -r line
            do
                # echo "$line"
                devtemp="/dev/""$line"
                # echo $devtemp
                mkdir -p "$REALDIR/$line"
                mount $devtemp "$REALDIR/$line"
    
                start_time=`date +%s`
                cp -f "$REALDIR/$line/usbfile.data" "$RESULTPATH/$TEMPPATH/$line.data"
                sync
                end_time=`date +%s`
                timeinv=`expr $end_time - $start_time`
                # echo $timeinv
                timereal=`expr $timeinv + $timereal`
                echo $timereal > "$RESULTPATH/$TEMPPATH/time.data"
                umount "$REALDIR/$line"
                rmdir "$REALDIR/$line"
            done 
        else
            lsblk -l -o name | grep -E "sd[b-q].{1,}" | while IFS= read -r line
            do
                # echo "$line"
                devtemp="/dev/""$line"
                # echo $devtemp
                mkdir -p "$REALDIR/$line"
                mount $devtemp "$REALDIR/$line"
    
                start_time=`date +%s`
                cp -f "$REALDIR/$line/usbfile.data" "$RESULTPATH/$TEMPPATH/$line.data"
                sync
                end_time=`date +%s`
                timeinv=`expr $end_time - $start_time`
                # echo $timeinv
                timereal=`expr $timeinv + $timereal`
                echo $timereal > "$RESULTPATH/$TEMPPATH/time.data"
                umount "$REALDIR/$line"
                rmdir "$REALDIR/$line"
            done
        fi

        timereal="$(cat "$RESULTPATH/$TEMPPATH/time.data")"
        echo $timereal

        if [ $timereal -gt $timetotal ]
        then
            usbdatacopytestok=FALSE
            echo "[错误]:[USB接口速度]:[]:[USB接口存储设备文件拷贝超时，可能存在错误]"
            echo "[ERROR]:[USB speed]:[]:[usb storage data copy time exceed, maybe error]" >> "$RESULTPATH/$filprefix.log"
        else
            usbdatacopytestok=TRUE
            echo "[信息]:[USB接口速度]:[]:[USB接口存储设备文件拷贝时间正常]"
            echo "[INFO]:[USB speed]:[]:[usb storage data copy time normal]" >> "$RESULTPATH/$fileprefix.log"
        fi
    else
        usbdatacopytestok=
        echo "[信息]:[USB接口速度]:[]:[USB接口设备数据传输测试禁止]"
        echo "[INFO]:[USB speed]:[]:[USB interface speed test function disable]" >> "$RESULTPATH/$fileprefix.log"
    fi
else
    usbtestok=
    echo "[信息]:[USB接口]:[]:[USB接口测试禁止]"
    # echo "[INFO]:[USB interface]:[]:[USb interface function test disable]"
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
        echo "[错误]:[内存稳定]:[]:[内存稳定测试失败]"
        echo "[ERROR]:[memory stability]:[]:[memtest $memtestsize $memtesttime error]" >> "$RESULTPATH/$fileprefix.log"
        errormsg="错误 内存稳定测试失败"
        zenerror
    else
        echo "[信息]:[内存稳定]:[]:[内存稳定测试正常]"
        echo "[INFO]:[memory stability]:[]:[memtest $memtestsize $memtesttime succeeds]" >> "$RESULTPATH/$fileprefix.log"
    fi
else
    memtestok=
    echo "[信息]:[内存稳定]:[]:[内存稳定测试禁止]"
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
    atftp -p -l "$RESULTPATH/$fileprefix.log" -r "$fileprefix.log" $gserver
    #  atftp -p -l "$RESULTPATH/audio$fileprefix.mov" -r "audio$fileprefix.mov" $gserver
else
    echo "记录文件不上传"
fi

# =========================================================================================
testtype="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.global.testtype')"
if [ $testtype = "stability" ] || [ $testtype = "pcie2usb" ] ; then
    zenity --list --title="单板功能测试工具" --text "单板功能测试结果" --checklist --column "测试结果" --column "测试功能描述" $sysmemtestok $message1_1 $audiotestok $message1_2 $eth1testok $message1_3 $eth2testok $message1_4 $satatestok $message1_5 $pcislottestok $message1_6 $serialtestok $message1_7 $prntestok $message1_8 $usbtestok $message1_9 $usbdatacopytestok $message1_10 $memtestok $message1_11 $ltptestok $message1_12 --width=700 --height=500 --timeout=10
else
    zenity --list --title="单板功能测试工具" --text "单板功能测试结果" --checklist --column "测试结果" --column "测试功能描述" $sysmemtestok $message1_1 $audiotestok $message1_2 $eth1testok $message1_3 $eth2testok $message1_4 $satatestok $message1_5 $pcislottestok $message1_6 $serialtestok $message1_7 $prntestok $message1_8 $usbtestok $message1_9 $usbdatacopytestok $message1_10 $memtestok $message1_11 $ltptestok $message1_12 --width=700 --height=500
fi

echo "[INFO]:[Global]:[]:[$sysmemtestok $message1_1 $audiotestok $message1_2 $eth1testok $message1_3 $eth2testok $message1_4 $satatestok $message1_5 $pcislottestok $message1_6 $serialtestok $message1_7 $prntestok $message1_8 $usbtestok $message1_9 $usbdatacopytestok $message1_10 $memtestok $message1_11 $ltptestok $message1_12]" >> "$RESULTPATH/$fileprefix.log"

# ========================================================================================
# reboot test
# rebootenable="$(cat "/home/$USERNAME/test_bench/test2.conf" | jq -r '.step5.enable')"
if [ $rebootenable -eq 1 ]
then
    rebootnumdef="$(cat "$REALDIR/$CONFPATH/$CONFFILE" | jq -r '.step5.number')"
    echo $rebootnumdef

    rebootcurnum=0

    if [ -e "$RESULTPATH/rebootnum.data" ] ; then
	echo "[警示]:[系统重启]:[]:[系统重启测试开始检测到异常rebootnum.data文件]"
	echo "[WARNING]:[Sysreboot]:[]:[Sysreboot detects abnormal rebootnum.data file]" >> "RESULTPATH/$fileprefix.log"
	mv "$RESULTPATH/rebootnum.data" "$RESULTPATH/rebootnumabn.data"
    fi
	
    echo 0 > "$RESULTPATH/rebootnum.data"
    chmod 777 "$RESULTPATH/rebootnum.data"
    cp "$REALDIR/reboottest/reboottest.service" /etc/systemd/system/reboottest.service
    chmod 777 /etc/systemd/system/reboottest.service
    systemctl daemon-reload
    systemctl enable reboottest.service

    if [ $rebootcurnum -gt $rebootnumdef ]
    then
        echo "[警示]:[系统重启]:[]:[系统重启测试次数$rebootnumdef设置错误，请检查配置文件]"
	echo "[WARNING]:[Sysreboot]:[]:[Sysreboot configured number $rebootnumdef error, check conf file]" >> "RESULTPATH/$fileprefix.log"
        mv "$RESULTPATH/rebootnum.data" "$RESULTPATH/rebootnumbakabn.data"
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
