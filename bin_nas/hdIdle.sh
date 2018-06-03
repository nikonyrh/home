#!/bin/bash
# ll /dev/disk/by-id/ata-* | grep -v "\-part"

sudo pkill hd-idle
sleep 2

#T=600 # 10 minutes
T=3600 # 1 hour
sudo hd-idle -i 0 -a sdd -i $T -a sde -i $T -a sdf -i $T
