#!/bin/bash

RESULTPATH="/var/log/functestresult"
CONFFILE="/opt/functest/conf/test2.conf"

USERNAME="$(cat $CONFFILE | jq -r '.global.username')"
[ $USERNAME != "null" ] && RESULTPATH="$RESULTPATH/$USERNAME"

TESTTYPE="$(cat $CONFFILE | jq -r '.global.testtype')"

rebootnumdef="$(cat $CONFFILE | jq -r '.step5.number')"
# echo $rebootnumdef

BOARDTYPE="$(cat $CONFFILE | jq -r '.global.boardtype')"

rebootcurnum=0

if [ ! -e "$RESULTPATH/rebootnum.data" ]
then
    echo 0 > "$RESULTPATH/rebootnum.data"
    chmod 777 "$RESULTPATHH/rebootnum.data"
    cp "/opt/functest/reboottest/reboottest.service" /etc/systemd/system/reboottest.service
    chmod 777 /etc/systemd/system/reboottest.service
    systemctl daemon-reload
    systemctl enable reboottest.service
else
    read line < "$RESULTPATH/rebootnum.data"
    rebootcurnum=`expr $line + 1`
    # echo $rebootcurnum
    echo $rebootcurnum > "$RESULTPATH/rebootnum.data"
    monthday="$(LANG=C date "+%b%d")"
    timetemp="$(LANG=C date "+%T" | tr -d ':')"
    echo $rebootcurnum > "$RESULTPATH/$monthday$timetemp.log"
    sync "$RESULTPATH/$monthday$timetemp.log"
    sync "$RESULTPATH/rebootnum.data"

    if [ $TESTTYPE = "pcie2usb" ] ; then
        pcieusbnum="$(lspci | grep uPD720201 | wc -l)"
        if [ $pcieusbnum != 4 ] ; then
            pcieusbresult="pcieusbexcep"
        else
            pcieusbresult="pcieusbok"
        fi    
    else
        if [ $BOARDTYPE = "mbc" ] && [ $TESTTYPE = "factstable" ] ; then
            pcieusbnum="$(lspci | grep uPD720201 | wc -l)"
            if [ $pcieusbnum != 4 ] ; then
                pcieusbresult="pcieusbexcep"
            else
                pcieusbresult="pcieusbok"
            fi
         else 
             pcieusbresult="pcieusbok"
         fi
    fi
fi

if [ $pcieusbresult = "pcieusbexcep" ] ; then
    exit 0
fi

if [ $rebootcurnum -gt $rebootnumdef ]
then
    # echo "reboot test succeed"
    mkdir -p /root/.config/autostart
    cp /opt/functest/reboottest/desktop /root/.config/autostart/.desktop
    chmod 777 /root/.config/autostart/.desktop
    netdev="$(cat $CONFFILE | jq -r '.global.netdev')"
    ethmacaddr="$(LANG=C ifconfig $netdev | grep -Po 'HWaddr \K.*$' | tr -d ':')"
    gmacaddr=`expr substr "$ethmacaddr" 1 12`
    monthday="$(LANG-C date "+%b%d")"
    time="$(LANG=C date "+%T" | tr -d ':')"
    fileprefix="$gmacaddr$monthday$time"
    mv "$RESULTPATH/rebootnum.data" "$RESULTPATH/reboot$fileprefix.data"
    rm /etc/systemd/system/reboottest.service
    systemctl daemon-reload
    
#    globalserver="$(cat $CONFFILE | jq -r '.global.server')"
#    atftp -p -l "$RESULTPATH/reboot$fileprefix.data" -r "reboot$fileprefix.data" $globalserver

else
   sleep 5
   reboot
fi
