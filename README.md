## Simple Shell based function testing

Testing requires root login in, not root privilege since irq affinity adjustment required.
In order to do auto reboot testing, need root autologin.
How to enable root login and root autologin, please search website, tons of info。
A reference on Ubuntu based
- sudo passwd root
- sudo passwd -u root
- modify /etc/lightdm/lightdm.conf enable root login and autologin, see ref dir

Testing depends following components
- jq
- zenity
- gnome-terminal
- atftp
- memtest
- ltp (old and micro modified, in dep dir)

Desktop shortcut in data dir

in conf/test2.conf file, special testtype
testtype = stability => mainly for long time memory/ltp/reboot test case, reboot test will automatically start after ltp test
testtype = pcie2usb => only for pcie to usb device stability test case, reboot + pcie2usb device num test
testtype = function => normal functional test
