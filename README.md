# docker-hybrid-net
Containerized host environment with virtual and physical switches

# Instruction
1. For both host-net and controller machine
    1-1. Run install/docker-install.sh to install Docker

        ./install/docker-install.sh

    1-2. Export path to project root

        export PJ_HOME=$(pwd) 

2. For host-net machine
    2-1. Run host-net/install/ovs-install.sh to install Open vSwitch

        ./install/ovs-install.sh

    2-2. Modify /etc/network/interface to configure interfaces for the control and data planes

        # TODO

    2-3. Change directory to image and run host-img.sh to create a docker image for hosts

        cd image
        ./host-img.sh
        cd ..
    
    2-4. Run setup

        ./script/host-setup.sh

3. For controller machine
    3-1. Run setup

        ./script/ctrl-setup.sh

# Requirments
Host network is optimized for Ubuntu 18.04
Controller is optimized for Centos8
To be added...
