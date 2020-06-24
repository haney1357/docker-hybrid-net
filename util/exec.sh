#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 [image name <onos|atomix>] [container number]"
    exit -1
fi

if [ x$1 == x"atomix" ]; then
    docker exec -it atomix-$2 /bin/bash
elif [ x$1 == x"onos" ]; then
    docker exec -it onos-$2 /bin/bash
elif [ x$1 == x"host" ]; then
    docker exec -it host-$2 /bin/bash
else
    echo "Usage: $0 [image name <onos|atomix|host>] [container number]"
    exit -1
fi
