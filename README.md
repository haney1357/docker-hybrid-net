# docker-hybrid-net
Containerized host environment with virtual and physical switches

# Instruction
1. Run install/ovs-install.sh to install Open vSwitch

    ./install/ovs-install.sh

2. Run install/docker-install.sh to install Docker

    ./install/docker-install.sh

3. Modify /etc/network/interface to configure interfaces for the control and data planes

4. Change directory to image and run dockerImg.sh to create a docker image for hosts

    cd image
    ./dockerImg.sh
    cd ..

# Requirments
Host network is optimized for Ubuntu 18.04
Controller is optimized for Centos8
To be added...
