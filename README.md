## Simple Shell based function testing

Testing requires root login in, not root privilege since irq affinity adjustment required.
In order to do auto reboot testing, need root autologin.
How to enable root login and root autologin, please search website, tons of info。
A reference on Ubuntu based
- sudo passwd root
- sudo passwd -s root
- modify /etc/lightdm/lightdm.conf enable root login and autologin, see ref dir

Testing depends following components
- jq
- zenity
- gnome-terminal
- atftp
- memtest
- ltp (old and micro modified, in dep dir)

Desktop shortcut in ref dir
