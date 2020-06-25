#!/bin/bash

#                             =================================================== $NIC0
#                            ||      ||   ____Your Topology_||__  ||      ||
#    Host-1 --------------   ||      ||   |                 || |  ||      ||
#                          \ ||      ||   |                    |  ||      ||
#      ...                   Edge-1 -||---|                    |  ||      ||
#                          /         ||   |                    |  ||      ||
#    Host-$CONT_PER_EDGE -           ||   |                    |--Core-1 -||----- $NIC1
#                                    ||   |                    |         \||  |
#      ...                     ...   ||   |                    |   ...    ||  |
#                                    ||   |                    |          ||\ |
#    Host-$IDX -----------           ||   |                    |--Core-$CORE _|
#                          \         ||   |                    |         \-----\- $NIC2
#      ...                   Edge-$EDGE --|                    |
#                          /              |                    |                  $NIC3
#    Host-$CONT_NUM ------                |                    |
#                                         |____________________|                  $NIC4

if [ $# -ne 2 ]; then
# TODO: Dynamic configuration of vnet
	echo "Usage: $0 [Machine No] [Controller IP]"
	exit -1
fi

# connect_ovs [br1] [br2] [patch1-2] [patch2-1]
# br1, br2 :            Name of bridge which to be connected
# patch1-2, patch2-1 :  Name to be given for new links
# Connect two bridges ([br1], [br2]) with two links ([patch1-2] and [patch2-1])
function connect_ovs {
    if [ $# -ne 4 ]; then
        echo "function connect_ovs [br1] [br2] [patch1-2] [patch2-1]"
    else
#        sudo ip link delete dev $3 2> /dev/null
#        sudo ip link delete dev $4 2> /dev/null

        sudo ip tuntap add dev $3 mode tap
        sudo ip tuntap add dev $4 mode tap

        sudo ovs-vsctl add-port $1 $3
        sudo ovs-vsctl add-port $2 $4

        sudo ovs-vsctl set interface $3 type=patch
        sudo ovs-vsctl set interface $3 options:peer=$4

        sudo ovs-vsctl set interface $4 type=patch
        sudo ovs-vsctl set interface $4 options:peer=$3
    fi
}

CONTROLLER_IP=$2

# Valid Machine Number Range : 1 ~ 8
# TODO: Restrict number of machine
MACHINE_NO=$1

# Valid Container Number Range : 1 ~ 30
# TODO: Restrict number of container
CONT_NUM=8

# Switch Configuration
# 1                ~ $EDGE          : Edge_Switch 
# $((EDGE+1))      ~ $((EDGE+AGGR)) : Aggr_Swtich
# $((EDGE+AGGR+1)) ~ $OVS_NUM       : Core_Switch
# Warning: Each machine can hold less than 16 switches
EDGE=4
AGGR=0
CORE=2
OVS_NUM=$((EDGE+CORE+AGGR))
CONT_PER_EDGE=$((CONT_NUM/EDGE))

# Interface Configuration
NIC1=enp2s0
NIC2=enp13s0
NIC3=
NIC4=

if [ -z ${HYBRID_NET_ROOT+x} ]; then 
    echo '$HYBRID_NET_ROOT is Unset'
    exit -1
fi

$HYBRID_NET_ROOT/host-net/host-clean.sh 2> /dev/null

sudo mkdir -p /var/run/netns

# Create new Open vSwitch bridges

# Controller IP and Port
# TODO: Distributed Controller Priority
if [ $MACHINE_NO -eq 1 ]; then
#    CONTROLLERS="tcp:$CONTROLLER_IP:6653,tcp:$CONTROLLER_IP:6654,tcp:$CONTROLLER_IP:6655"
    CONTROLLERS="tcp:$CONTROLLER_IP:6653"
else
#    CONTROLLERS="tcp:$CONTROLLER_IP:6655,tcp:$CONTROLLER_IP:6654,tcp:$CONTROLLER_IP:6653"
    CONTROLLERS="tcp:$CONTROLLER_IP:6655"
fi

PROTOCOL=OpenFlow10

# Create OVS Switches
#   For all OVS Switches
for i in $(seq 1 $OVS_NUM)
do
    BR_ID=$(( 1000 + 100 * MACHINE_NO + i ))
#	sudo ovs-vsctl del-br br$i 2> /dev/null
	sudo ovs-vsctl add-br br$i
	sudo ovs-vsctl set-controller br$i $(echo $CONTROLLERS | sed 's/,/ /g')
	sudo ovs-vsctl set-fail-mode br$i secure
	sudo ovs-vsctl -- set bridge br$i protocols=$PROTOCOL
    sudo ovs-vsctl -- set bridge br$i other-config:datapath-id=000000000000$BR_ID
done

echo $(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')": Created Open vSwitch"

# NETWORK(X.X.X).DOCKER($START_IP ~ )
CIDR=16

# Docker Configuration
# Create new container and link to the bridges

# Host
HOST_NAME=host:0.1
for i in $(seq 1 $CONT_NUM)
do
    did=$(docker run -itd --net=none --name host-$i $HOST_NAME /bin/bash)
#    dip=172.16.10.$(( (MACHINE_NO - 1) * 30 + 10 + i ))
#    GATEWAY=172.16.10.1
    dip=172.16.$(( MACHINE_NO - 1 )).$(( 10 + i ))
    GATEWAY=172.16.$(( MACHINE_NO - 1 )).1
    mac=$(python $HYBRID_NET_ROOT/util/create_mac.py $dip)
    pid=$(docker inspect -f '{{.State.Pid}}' $did)
    bridge=$(( (i-1)*EDGE/CONT_NUM+1 ))
    
# Create network ns for app
    sudo ln -s /proc/$pid/ns/net /var/run/netns/$pid
# Create peer veth interface for app, ovs-[bridge]
    sudo ip link add veth-$i type veth peer name veth-a
# Add veth-a interface to ovs-[bridge] and link up
    sudo ovs-vsctl add-port br$bridge veth-$i
    sudo ip link set veth-$i up
# Add veth-a interface to app and link up
    sudo ip link set veth-a netns $pid
    sudo ip netns exec $pid ip link set dev veth-a name eth0
    sudo ip netns exec $pid ip link set eth0 address $mac
    sudo ip netns exec $pid ip link set eth0 up
    sudo ip netns exec $pid ip addr add $dip/$CIDR dev eth0
    sudo ip netns exec $pid ip route add default via $GATEWAY
done

echo $(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')\
    ": Created and connected " $(docker ps -a | grep "$HOST_NAME" | wc -l)" containers"

# Connect ovs base on your topology
# TODO: Composetopology from configuration
# Edge-1 <br1>
#              \
#                Core-1 <br5> -- $NIC1
#              /
# Edge-2 <br2>
#
# Edge-3 <br3>
#              \
#                Core-2 <br6> -- $NIC2
#              /
# Edge-4 <br4>

connect_ovs br1 br5 patch1-5 patch5-1 2> /dev/null
connect_ovs br2 br5 patch2-5 patch5-2 2> /dev/null
connect_ovs br3 br6 patch3-6 patch6-3 2> /dev/null
connect_ovs br4 br6 patch4-6 patch6-4 2> /dev/null

echo $(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')\
    ": connect ovs"

sudo ip link set $NIC1 up
sudo ovs-vsctl add-port br5 $NIC1
sudo ip link set $NIC2 up
sudo ovs-vsctl add-port br6 $NIC2
