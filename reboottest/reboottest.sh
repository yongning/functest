#!/bin/bash

RESULTPATH="/var/log/functestresult"
CONFFILE="/opt/functest/conf/test2.conf"

USERNAME="$(cat $CONFFILE | jq -r '.global.username')"
[ $USERNAME != "null" ] && RESULTPATH="$RESULTPATH/$USERNAME"

rebootnumdef="$(cat $CONFFILE | jq -r '.step5.number')"
# echo $rebootnumdef

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
    timetemp="$(LANG=C date "+%T" | tr -d ':')"
    echo $rebootcurnum > "$RESULTPATH/$timetemp.log"
fi

if [ $rebootcurnum -gt $rebootnumdef ]
then
    # echo "reboot test succeed"
    netdev="$(cat $CONFFILE | jq -r '.global.netdev')"
    ethmacaddr="$(LANG=C ifconfig $netdev | grep -Po 'HWaddr \K.*$' | tr -d ':')"
    gmacaddr=`expr substr "$ethmacaddr" 1 12`
    monthday="$(LANG-C date "+%b%d")"
    time="$(LANG=C date "+%T" | tr -d ':')"
    fileprefix="$gmacaddr$monthday$time"
    mv "$RESULTPATH/rebootnum.data" "$RESULTPATH/reboot$fileprefix.data"
    rm /etc/systemd/system/reboottest.service
    systemctl daemon-reload
    
    globalserver="$(cat $CONFFILE | jq -r '.global.server')"

    sleep 15
    atftp -p -l "$RESULTPATH/reboot$fileprefix.data" -r "reboot$fileprefix.data" $globalserver
else
   reboot
fi

# globalserver="$(cat "/home/gwi/functest/conf/test2.conf" | jq -r '.global.server')"

# sleep 15
# atftp -p -l "/home/gwi/testresult/reboot$fileprefix.data" -r "reboot$fileprefix.data" $globalserver
