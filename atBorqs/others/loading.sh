#!/usr/bin/bash
full_percent=100
done_percent=0
current_percent=0
echo_process()
{
    number=`expr $1 - $done_percent`
    done_percent=$1
    while [ $number -ne 0 ]
    do
        echo -n "*"
        number=`expr $number - 1`
    done
    [ $done_percent = $full_percent ]  && { echo "";}
}

while :
do
    current_percent=`expr $current_percent + 1`
    echo_process $current_percent
    [ $current_percent = $full_percent ] && { echo "Task is over!"; break; }
done
