#!/bin/bash
ss=""
[[ -n $1 ]] && ss="-s $1"
for i in $(seq 1 100)
do 
adb $ss shell input tap 641 181
sleep 2
adb $ss shell input tap 500 560
sleep 2
adb $ss shell input tap 641 181
sleep 2
echo "$i"
done
