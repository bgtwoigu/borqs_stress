#!/bin/bash

main()
{
	echo "Please input capture times:"
	read num
	echo "Input device number"
	read dev	
	i=1
	while [ $i -le $num ];do
		echo "Camera Capture... $i of $num, camera."
		#adb logcat -c
		adb -s $dev shell input keyevent 27
		sleep 5
		adb -s $dev shell input keyevent 27
		i=$((i+1))
	sleep 5
		
	done
}
main 2>&1 | tee ./camera.txt
cd ..
