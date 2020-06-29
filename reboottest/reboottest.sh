#!/bin/sh

rebootnumdef="$(cat "/home/gwi/functest/conf/test2.conf" | jq -r '.step5.number')"
echo $rebootnumdef

rebootcurnum=0

if [ ! -e "/home/gwi/testresult/rebootnum.data" ]
then
    echo 0 > "/home/gwi/testresult/rebootnum.data"
    chmod 777 "/home/gwi/testresult/rebootnum.data"
    cp "/home/gwi/functest/reboottest/reboottest.service" /etc/systemd/system/reboottest.service
    chmod 777 /etc/systemd/system/reboottest.service
    systemctl daemon-reload
    systemctl enable reboottest.service
else
    read line < "/home/gwi/testresult/rebootnum.data"
    rebootcurnum=`expr $line + 1`
    echo $rebootcurnum
    echo $rebootcurnum > "/home/gwi/testresult/rebootnum.data"
    timetemp="$(LANG=C date "+%T" | tr -d ':')"
    echo $rebootcurnum > "/home/gwi/testresult/$timetemp.log"
fi

if [ $rebootcurnum -gt $rebootnumdef ]
then
    echo "reboot test succeed"
    netdev="$(cat "/home/gwi/functest/conf/test2.conf" | jq -r '.global.netdev')"
    ethmacaddr="$(LANG=C ifconfig $netdev | grep -Po 'HWaddr \K.*$' | tr -d ':')"
    gmacaddr=`expr substr "$ethmacaddr" 1 12`
    monthday="$(LANG-C date "+%b%d")"
    time="$(LANG=C date "+%T" | tr -d ':')"
    fileprefix="$gmacaddr$monthday$time"
    mv "/home/gwi/testresult/rebootnum.data" "/home/gwi/testresult/reboot$fileprefix.data"
    rm /etc/systemd/system/reboottest.service
    systemctl daemon-reload
    
    globalserver="$(cat "/home/gwi/functest/conf/test2.conf" | jq -r '.global.server')"

    sleep 15
    atftp -p -l "/home/gwi/testresult/reboot$fileprefix.data" -r "reboot$fileprefix.data" $globalserver
else
   reboot
fi

# globalserver="$(cat "/home/gwi/functest/conf/test2.conf" | jq -r '.global.server')"

# sleep 15
# atftp -p -l "/home/gwi/testresult/reboot$fileprefix.data" -r "reboot$fileprefix.data" $globalserver
