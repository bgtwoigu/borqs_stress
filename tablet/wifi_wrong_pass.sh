#!/bin/bash
ss=""
[[ -n $1 ]] && ss="-s $1"
for (( n=1; n<=1000; n++ ))
do
   adb $ss shell input tap 540 214
   sleep 2   
   adb $ss shell input tap 571 579
   sleep 10
   echo $n
done
echo "done"

