#! /bin/bash
n=1
while true; do
sleep 15
adb "wait-for-devices" reboot
echo "reboot $n times"
n=$((n+1))
done
