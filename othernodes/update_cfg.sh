#!/bin/bash
rm testbed.sh

if ! [ -f remote.cfg ]; then
	echo -e "remote.cfg not found...exit"
	exit 1
fi

source remote.cfg

if ! [ -n "$DREAMERCONFIGSERVER" ]; then
	echo "Addresses Not Setted For Dreamer Nodes...exit"
	exit 1
fi

wget $DREAMERCONFIGSERVER

MANAGMENT_IP=$( ip -4 addr show dev eth0 | grep -m 1 "inet " | awk '{print $2}' | cut -d "/" -f 1 )

START_END=( $(grep -F general testbed.sh -n | cut -d ":" -f 1) )
sed "${START_END[0]},${START_END[1]}!d" testbed.sh > tbs.sh

START_END=( $(grep -F "$MANAGMENT_IP" testbed.sh -n | cut -d ":" -f 1) )
sed "${START_END[0]},${START_END[1]}!d" testbed.sh >> tbs.sh

mv tbs.sh testbed.sh

