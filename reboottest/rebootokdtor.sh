CONFFILE="/opt/functest/conf/test2.conf"
USERNAME="$(cat $CONFFILE | jq -r '.global.username')"
echo "123123" | sudo cp "/home/$USERNAME/lightdm.conf.uos.original" /etc/lightdm/lightdm.conf
echo "123123" | sudo rm -f "/home/$USERNAME/lightdm.conf.uos.original"
echo "123123" | sudo rm -f "/home/$USERNAME/.config/autostart/.desktop"
echo "123123" | sudo rm -f "/home/$USERNAME/Desktop/functest.desktop"
echo "123123" | sudo rm -f "/home/$USERNAME/Desktop/funcremove.desktop"
echo "123123" | sudo rm -f "/home/$USERNAME/*.log"
echo "123123" | sudo rm -f "/home/$USERNAME/*.data"
echo "123123" | sudo rm -f "/home/$USERNAME/.config/deepin/deepin-movie/config.conf"
echo "123123" | sudo rm -rf "/home/$USERNAME/functesttmp"
echo "123123" | sudo rm -rf /opt/ltp
echo "123123" | sduo rm -rf /opt/functest
echo "123123" | sudo dpkg --purge -y meas_utils jq memtester zenity gnome-terminal atftp


