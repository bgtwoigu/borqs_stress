#####
# Create by Luke.Zhang
# mail: luke.zhang@borqs.com
#####

#!/bin/bash

main()
{
	while getopts "i:n:l:hs:r" opt; do
    case $opt in
		i) interval=$OPTARG;;
		n) count=$OPTARG;;
		l) loop=$OPTARG;;
		s) ss=$OPTARG;;
		r) isreboot=true;;
		h) usage;;
		*) usage;;
		\?) usage;;
    esac
done
[[ -z "$isreboot" ]] && isreboot=false
[[ -z $ss ]] && echo "Please input device number" && usage
[[ -n $ss ]] && ss="-s $ss"
[[ -z `echo $interval | tr -cd '0-9'` ]] && interval=400
[[ -z `echo $count | tr -cd '0-9'` ]] && count=10000
[[ -z `echo $loop | tr -cd '0-9'` ]] && loop=10
model="`adb shell getprop ro.product.model`"
monkey
}

preboot()
{
	echo "`date`: Now, reboot..."
	adb $ss shell reboot
	dur=1
	while true;do
		adbstate="`adb devices | grep $ss`"
		sleep 5
		if [ -n "$adbstate" ];then
			adb $ss  logcat -d | grep "BOOT_COMPLETED" > ./Boot.log
			rpower="`cat ./Boot.log | grep "BOOT_COMPLETED"`"
			rpower2="`cat ./Boot.log | grep -i "BOOTCOMPLETED"`"
			sleep 5
			if [ -n "$rpower" -o -n "$rpower2" ]; then
				echo "Powered up!"
				break
			fi
		fi
		if [ $dur -eq 80 ];then
			echo "Phone did not power up!"
			logger
			cleanup
			exit 1
		fi
		dur=$((dur+1))
	done
	sleep 10
	echo "`date`: Unlocking..."
	if [ "$model" = "X900" -o "$model" = "BKBGB" ];then
	## Android home ##
		adb $ss shell input motionevent 100 800 down
		adb $ss shell input motionevent 580 800 move
		adb $ss shell input motionevent 580 800 up
	#################
	else
	## Orange Home ##
		adb $ss shell input motionevent 280 900 down && adb $ss shell input motionevent 280 900 up && adb $ss shell input motionevent 280 900 down && adb $ss shell input motionevent 280 900 up
		adb $ss shell input motionevent 280 900 down && adb $ss shell input motionevent 280 900 up && adb $ss shell input motionevent 280 900 down && adb $ss shell input motionevent 280 900 up
		adb $ss shell input motionevent 280 900 down && adb $ss shell input motionevent 280 900 up && adb $ss shell input motionevent 280 900 down && adb $ss shell input motionevent 280 900 up
	#################
	fi
}




usage()
{
	echo "Usage: `basename $0` -i [interval] -n [count] -l [loop number] -s [devices number] -r"
	echo "-i	Interval of monkey, empty=400"
	echo "-n	Count of monkey, empty=10000"
	echo "-l	Number of loop, empty=10"
	echo "-r	Reboot Device after every monkey command finished, to cleanup."
	echo "-h	Show this help."
	echo "-s	Run with mutil devices, follow with a device number, MUST ADD."
	echo "Empty means none options inputed."
	rm -fr ./monkeysys"_`date +%y%m%d`"
	exit 1
}

cleanup()
{
	echo "Clean up..."
	adb $ss shell input keyevent 20
	adb $ss shell input keyevent 23
	kmedia=`adb $ss shell ps | grep mediaserver | awk '{printf $2}'` 
	adb $ss shell kill -9 $kmedia
	adb $ss shell rm -r /data/logs/aplog.log.[67890]
	adb $ss shell rm -r /data/logs/aplog.log.[0-9][0-9]
	adb $ss shell rm -r /data/anr/*
	adb $ss shell rm -r /data/system/dropbox/*
}

logger()
{
	adb $ss pull /data/logs/ ./$n/logs
	adb $ss pull /data/anr/ ./$n/logs
	adb $ss pull /data/system/dropbox/ ./$n/logs
	adb $ss shell dumpstate > ./$n/logs/dumpstate.txt
}

monkey()
{
	n=1
	while [ $n -le $loop ];do
		wocao=`adb devices | grep $ss`
		if [ -z "$wocao" ]; then
			echo "adb $ss disconnected!"
			usage
			exit 1
		fi
		echo -e "#\tResult\tComments\tMonkeyCommand" >> ./Result.xls
		R=`date +%N`
		mkdir ./$n
		echo "`date`: Start testing, $n of $loop..."
		echo "Seed is $R"
		mkcmd="adb $ss shell monkey -s $R -v --pct-touch 30 --throttle $interval $count --ignore-crashes --monitor-native-crashes"
		echo "Monkey command is:"
		echo $mkcmd
		process &
		tstart=`date +%s`
		adb $ss shell monkey -s $R -v --pct-touch 30 --throttle $interval $count --ignore-crashes --monitor-native-crashes > ./$n/"$n"_monkey.log
		tend=`date +%s`
		duration=$(((tend-tstart)/60))
		njobs="`jobs | tail -n 1 | tr -cd '0-9'`"
		kill -9 %$njobs > /dev/null
		lastlineok="`tail -n 1 ./$n/"$n"_monkey.log | grep "finished"`"
		lastlinefc="`cat ./$n/"$n"_monkey.log | grep "CRASH"`"
		lastlineanr="`cat ./$n/"$n"_monkey.log | grep "ANR"`"
		if [ -n "$lastlineok" ];then
			printf $count
			echo -e "\nPass!"
			echo -e "$n\tPass\t$duration minutes, N/A\t$mkcmd" >> ./Result.xls
		elif [ -n "$lastlinefc" ];then
			echo -e "\nForce close!"
			echo -e "$n\tFailed\t$duration minutes, Force close\t$mkcmd" >> ./Result.xls
			logger
			cleanup
		elif [ -n "$lastlineanr" ];then
			echo -e "\nANR!"
			sleep 10
			echo -e "$n\tFailed\t$duration minutes, ANR\t$mkcmd" >> ./Result.xls
			logger
			cleanup
		else
			wocao=`adb devices | grep $ss`
			if [ -z "$wocao" ]; then
				echo -e "\nadb $ss disconnected!"
				echo -e "$n\tFailed\t$duration minutes, adb $ss disconnected\t$mkcmd" >> ./Result.xls
				exit 1
			else
				echo -e "\nUnknown error"
				echo -e "$n\tFailed\t$duration minutes, N/A\t$mkcmd" >> ./Result.xls
				logger
				cleanup
			fi
		fi
		echo "Duration: $duration minutes."
		n=$((n+1))
		sleep 5
		echo " "
		$isreboot && preboot
	done
}

process()
{
	while true ;do
		printf .
		sleep 5
		tmp=$pkey
		pkey="`cat ./$n/"$n"_monkey.log | grep "Sending event #" | tail -n 1 | tr -cd '[0-9]'`" >/dev/nul
		if [ "$pkey" = "$tmp" ];then
			continue
		else
			printf $pkey
		fi
	done
}

rm -fr ./monkeysys"_`date +%y%m%d`"
mkdir -p ./monkeysys"_`date +%y%m%d`"
cd ./monkeysys"_`date +%y%m%d`"
main $@ 2>&1 | tee ./monkey.log
cd ..
chmod 777 -R ./monkeysys"_`date +%y%m%d`"



