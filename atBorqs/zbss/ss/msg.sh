#!/bin/bash

move()
{
	adb $sa shell input motionevent $1 $2 down
	adb $sa shell input motionevent $1 $2 up
}

verification()
{
	echo "Start verification..."
	adb $sa shell logcat -b radio -c
	adb $sb shell logcat -b radio -c
	adb $sa shell am start -a android.intent.action.SENDTO -d sms:$num
	#-n com.android.mms/.ui.ComposeMessageActivity -W
	sleep 1
	adb $sa shell input text test$n
	sleep 1
	adb $sa shell input keyevent 22
	sleep 1
	adb $sa shell input keyevent 23
	sleep 3
	adb $sa shell input keyevent 23
	while true;do
		ra=`adb $sa shell logcat -b radio -d -v time | grep UNSOL_RESPONSE_NEW_SMS`
		rb=`adb $sb shell logcat -b radio -d -v time | grep UNSOL_RESPONSE_NEW_SMS`
		if [ -n "$ra"  ];then
			tmp="$sa"
			sa="$sb"
			sb="$tmp"
			break
		elif [ -n "$rb" ];then
			break
		else
			sleep 1
		fi
	done
	echo "Overed, Start testing in 5 seconds."
	sleep 5
}



mms()
{
	verification
	adb $sa shell rm -r /system/app/Quickoffice.apk
	echo "`date`: Empty your Msg box first, any key to continue."
	read anyelse
	n=1
	while [ $n -le 100 ];do
		doom=0
		adb $sa shell tcpdump -i any -s 0 -w /mnt/sdcard/"$n"_tcp.pcap &
		adb $sb shell tcpdump -i any -s 0 -w /mnt/sdcard/"$n"_tcp.pcap &
		echo "`date`: `date`:Start to send MMS to $num"
		echo "`date`: Looping No.$n"
		adb $sa shell am start -a android.intent.action.SENDTO -d sms:$num
		#n com.borqs.mms/.ui.ComposeMessageActivity -W
		sleep 2
		adb $sa shell input text testABC$n
		sleep 2
		#add attachments.
		adb $sa shell input keyevent 82
		sleep 2
		if [ $n -eq 1 ];then # menu
			move 150 310
		else
			move 150 310
		fi
		sleep 2
		move 140 400 #
		sleep 3
		move 150 100
		sleep 3
		move 250 445
		sleep 3
		adb $sa shell input keyevent 22
		adb $sa shell input keyevent 22
		sleep 1
		adb $sa shell input keyevent 23
		sleep 1
		adb $sb shell logcat -b events -c
		sleep 2
		adb $sa shell input keyevent 4
		adb $sa shell input keyevent 4
		dur=1
		while  [ $dur -le 900 ]; do
			sleep 1
			r="`adb $sb shell logcat -b radio -d -v time | grep UNSOL_RESPONSE_NEW_SMS`"
			if [ -n "$r"  ];then
				echo "`date`: MMS recieved!"
				result "m1"
				cleanup "$sa"
				cleanup "$sb"
				sleep 5
				break
			fi
			if [ $dur -eq 300 ];then
				echo "`date`: MMS not recieved! Now catching logs"
				#loger
				result "m0"
				doom=1
				break
			fi
			dur=$((dur+1))
		done
		[ $doom -eq 1 ] && n=$((n+1)) && continue
		n=$((n+1))
	done
}


loger()
{
	adb $sa pull /data/logs/ ./"$n"_logs/A/
	adb $sa pull /data/anr/ ./"$n"_logs/A/
	adb $sa pull /mnt/sdcard/"$n"_tcp.pcap ./"$n"_logs/A/
	adb $sb pull /data/logs/ ./"$n"_logs/B/
	adb $sb pull /data/anr/ ./"$n"_logs/B/
	adb $sb pull /mnt/sdcard/"$n"_tcp.pcap ./"$n"_logs/B/
	cleanup "$sa"
	cleanup "$sb"
}


cleanup()
{
	adb kill-server
	adb start-server > /dev/null
	adb $1 shell rm -r /data/logs/aplog.log.[0-9][0-9] > /dev/null
	adb $1 shell rm -r /data/logs/aplog.log.[456789] > /dev/null
	adb $1 shell rm -r /mnt/sdcard/"$n"_tcp.pcap  > /dev/null
	adb $1 shell rm -r /data/logs/bplog.* > /dev/null
	adb $1 shell rm -r /data/logs/logcat-ril.log.[345] > /dev/null
}


sms()
{
	verification
	n=1
	while [ $n -le $1 ];do
		doom=0
		echo "`date`: `date`: Start to send SMS to $num"
		echo "`date`: Looping No.$n"
		adb $sa shell am start -a android.intent.action.SENDTO -d sms:$num
		#-n com.android.mms/.ui.ComposeMessageActivity -W
		sleep 1
		adb $sa shell input text testABC$n
		sleep 1
		adb $sa shell input keyevent 22
		sleep 1
		adb $sa shell input keyevent 23
		sleep 1
		adb $sa shell input keyevent 22
		sleep 1
		adb $sa shell input keyevent 23

		sleep 3
		adb $sa shell input keyevent 23
		#adb $sb shell logcat -b radio -c
		adb $sa shell input keyevent 4
		adb $sa shell input keyevent 4
		dur=1
		while  [ $dur -le 60 ]; do
			sleep 1
			r=`adb $sb shell logcat -b radio -d -v time | grep UNSOL_RESPONSE_NEW_SMS`
			if [ -n "$r"  ];then
				echo "`date`: Msg recieved!"
				result "s1"
				sleep 5
				break
			fi
			if [ $dur -eq 60 ];then
				echo "`date`: Msg not recieved! Now catching logs"
				#loger
				result "s0"
				doom=1
				break
			fi
			dur=$((dur+1))
		done
		[ $doom -eq 1 ] && n=$((n+1)) && continue
		n=$((n+1))
		adb $sb shell logcat -b radio -c
	done
}

result()
{
	case $1 in
		m1) echo "`date`: $n, MMS received." >> ./result.txt;;
		m0) echo "`date`: $n, MMS received failed." >> ./result.txt;;
		s1) echo "`date`: $n, SMS received." >> ./result.txt;;
		s0) echo "`date`: $n, SMS received failed" >> ./result.txt;;
	esac
}

main()
{
	adb kill-server
	adb start-server
	echo "`date`: Input number of Target phone"
	read num
	sa="-s `adb devices | awk 'NR==2 {print $1}'`"
	sb="-s `adb devices | awk 'NR==3 {print $1}'`"
	[ -z "$sa" -o -z "$sb" ] && echo "Please make sure TWO devices have been connected to PC."
	count="$2"
	[[ -z "$2" ]] && count=100
	adb $sa root
	adb $sb root
	sleep 3
	adb $sa remount
	adb $sb remount

	cleanup "$sa"
	cleanup "$sb"
	$1 $count
}
shtime="`date +%y%m%d%H%M%S`"
mkdir -p Msg_$shtime
cd Msg_$shtime
rm -fr ./[Rr]esult.txt
main $@ 2>&1 | tee Msg.log
