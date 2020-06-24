#!/usr/bin/python

import sys

docker_ip = sys.argv[1]
ip_bytes = docker_ip.split('.')

mac = [0x00, 0x00, int(ip_bytes[0]), int(ip_bytes[1]), int(ip_bytes[2]), int(ip_bytes[3])]

print ':'.join(map(lambda x: "%02x" % x, mac))
