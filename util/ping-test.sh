#!/bin/bash

function ip_validate {
    ip=$1
    sip=$2
    pid_l=$3
    res=$(sudo ip netns exec $pid_l ping -c 1 $ip)

    if [[ "$res" =~ "Destination Host Unreachable" ]]; then
        echo -e "Ping test \033[1;37;40m$sip --> $ip\033[0m: \033[1;37;41mFailed\033[0m"
    else
        echo -e "Ping test \033[1;37;40m$sip --> $ip\033[0m: \033[1;37;44mSuccess\033[0m"
    fi
}
ps=$(docker ps -a | grep 'host-[[:digit:]]*' | awk '{print $1}')
pids=
ips=
for id in $ps; do
    pid=$(docker inspect -f '{{.State.Pid}}' $id)
    pids+="$pid "
    ip=$(sudo ip netns exec $pid ifconfig eth0 | grep -Po 'inet [addr:]*\K[\d.]+')
    ips+="$ip "
done

for pid in $pids; do
    sip=$(sudo ip netns exec $pid ifconfig eth0 | grep -Po 'inet [addr:]*\K[\d.]+')
#    for ip in $ips; do
#        ip_validate $ip $sip $pid
#    done

    for i in $(seq 1 $#); do
        ip_validate ${!i} $sip $pid
    done
done
