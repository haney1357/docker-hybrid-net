#!/bin/bash

if [ -z ${HYBRID_NET_ROOT+x} ]; then 
    echo '$HYBRID_NET_ROOT is Unset'
    exit -1
fi

if [ $(sudo firewall-cmd --permanent --list-all --zone=public | grep "8181-8183" | wc -l) -eq 0 ]; then
    sudo firewall-cmd --permanent --zone=public --add-port 9876/tcp
    sudo firewall-cmd --permanent --zone=public --add-port 6653-6655/tcp
    sudo firewall-cmd --permanent --zone=public --add-port 8101-8103/tcp
    sudo firewall-cmd --permanent --zone=public --add-port 8181-8183/tcp
    sudo firewall-cmd --permanent --zone=public --add-port 5678-5679/tcp
    sudo firewall-cmd --permanent --zone=trusted --change-interface=docker0
    sudo firewall-cmd --reload
fi

if [ $(sudo semanage port -l | grep "8181-8183" | wc -l) -eq 0 ]; then
    sudo semanage port -a -p tcp -t dccm_port_t 5678
    sudo semanage port -a -p tcp -t sap_port_t 9876
    sudo semanage port -a -p tcp -t openflow_port_t 6653-6655
    sudo semanage port -a -p tcp -t ssh_port_t 8101-8103
    sudo semanage port -a -p tcp -t intermapper_port_t 8181-8183
fi

ATOMIX=atomix/atomix:3.1.5
ATOMIX_NUM=3
CTRL_NUM=3
CTRL_NAME=onosproject/onos

$HYBRID_NET_ROOT/util/clean.sh 2>/dev/null

mkdir -p $HYBRID_NET_ROOT/gen
mkdir -p $HYBRID_NET_ROOT/gen/conf
mkdir -p $HYBRID_NET_ROOT/gen/cluster

ATOMIX_IP=
for i in $(seq 1 $ATOMIX_NUM)
do
    cat $HYBRID_NET_ROOT/conf/atomix.conf | sed -e "s/IDX/$i/g" | sed -e "s/atomix_node/172.17.0.$((i+1))/g" >> $HYBRID_NET_ROOT/gen/conf/atomix$i.conf
    docker run -itd --name atomix-$i -v $HYBRID_NET_ROOT/gen/conf:/etc/atomix/conf  $ATOMIX --config /etc/atomix/conf/atomix$i.conf --ignore-resources
    ATOMIX_IP+="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' atomix-$i) "
done

for i in $(seq 1 $CTRL_NUM)
do
    docker run -itd --name onos-$i -p $(( 6653 + i - 1 )):6653 -p $(( 8101 + i - 1 )):8101 -p $(( 8181 + i - 1 )):8181 $CTRL_NAME
    CTRL_IP=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' onos-$i)
    $HYBRID_NET_ROOT/util/onos-gen-config $CTRL_IP $HYBRID_NET_ROOT/gen/cluster/cluster-$i.json -n $ATOMIX_IP
    docker exec onos-$i mkdir /root/onos/config
    docker cp $HYBRID_NET_ROOT/gen/cluster/cluster-$i.json onos-$i:/root/onos/config/cluster.json
done

echo "$CTRL_NUM controller created"
echo "Initializing ONOS Cluster... It might takes a couple of minutes"
echo "After initializing, Activate essential apps: OpenFlow Provider Suite <onos.onosproject.openflow>, Reactive Forwarding <onos.onosproject.fwd>"
