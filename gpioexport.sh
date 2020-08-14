#!/bin/bash
echo 480 > /sys/class/gpio/export
sleep 1
echo out > /sys/class/gpio/gpio480/direction

