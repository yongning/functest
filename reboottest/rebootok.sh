#!/bin/bash

/opt/functest/gpio 0x208 0x30 0x10
sleep 0.5
/opt/functest/gpioexport.sh
sleep 0.5
gnome-terminal -- /bin/bash -c "/opt/functest/gpioblinklong.sh"
zenity --info --width=700 --title="单板重启测试" --text="单板重启测试正常完成"

