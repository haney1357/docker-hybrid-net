#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 [host_no]"
    exit -1
fi

if [ $1 -eq 0 ]; then
    docker exec -it ctrl /bin/bash
else
    docker exec -it host-$1 /bin/bash
fi
