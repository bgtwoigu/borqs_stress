#!/bin/bash

adb shell /system/bin/screencap -p /sdcard/screenshot.png
sleep 2
adb pull /sdcard/screenshot.png ./
