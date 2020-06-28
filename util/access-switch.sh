#!/bin/bash
PS3="Please choose a switch:"
select option in 1 2 3 4 exit
do
    case $option in
        1)
            ssh admin@192.168.0.51 
            break;;
        2)
            ssh admin@192.168.0.52
            break;;
        3)
            ssh admin@192.168.0.53
            break;;
        4)
            ssh admin@192.168.0.54
            break;;
        exit)
            exit
    esac
done
