#!/bin/bash

if [ -z ${HYBRID_NET_ROOT+x} ]; then 
    echo '$HYBRID_NET_ROOT is Unset'
    exit -1
fi

# Host network clean

# Remove Links between OVSs
for i in $(seq 0 6)
do for j in $(seq 0 6)
    do sudo ip link delete patch$i-$j 2> /dev/null;
    done
done

# Remove OVSs
for i in $(seq 0 6)
    do sudo ovs-vsctl del-br br$i 2> /dev/null
done
    
# Remove Host Containers
HOST_CONTAINER=$(docker ps -a | grep host | awk '{print $1}')

# Remove all containers related to project
docker rm -f $HOST_CONTAINER 2> /dev/null

sudo rm -rf /var/run/netns/*

# Controller clean

CTRL_CONTAINER=$(docker ps -a | grep onos | awk '{print $1}')
ATOMIX_CONTAINER=$(docker ps -a | grep atomix | awk '{print $1}')

docker rm -f $CTRL_CONTAINER 2> /dev/null
docker rm -f $ATOMIX_CONTAINER 2> /dev/null

rm -rf $HYBRID_NET_ROOT/gen
