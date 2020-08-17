#!/bin/bash
blinktemp=0
while true ; do
sleep 0.5 
blinktemp=`expr $blinktemp + 1`
blinkdata1=`expr $blinktemp % 2`
echo $blinktemp
echo $blinkdata1
echo $blinkdata1 > /sys/class/gpio/gpio480/value
done
