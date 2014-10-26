#!/bin/bash
rm testbed.sh 2> /dev/null
rm lmerules.sh 2> /dev/null
rm vs/vsf.cfg 2> /dev/null

if ! [ -f remote.cfg ]; then
	echo -e "remote.cfg not found...exit"
	exit 1
fi

source remote.cfg

if ! [ -n "$DREAMERCONFIGSERVER" ] || ! [ -n "$DREAMERCONFIGSERVER2" ] || ! [ -n "$DREAMERCONFIGSERVER3" ]; then
	echo "Addresses Not Setted For OSHI...exit"
	exit 1
fi

wget $DREAMERCONFIGSERVER

MANAGMENT_IP=$( ip -4 addr show dev eth0 | grep -m 1 "inet " | awk '{print $2}' | cut -d "/" -f 1 )

START_END=( $(grep -F general testbed.sh -n | cut -d ":" -f 1) )
sed "${START_END[0]},${START_END[1]}!d" testbed.sh > tbs.sh

START_END=( $(grep -F "$MANAGMENT_IP" testbed.sh -n | cut -d ":" -f 1) )
sed "${START_END[0]},${START_END[1]}!d" testbed.sh >> tbs.sh

mv tbs.sh testbed.sh

wget $DREAMERCONFIGSERVER2

START_END=( $(grep -F "$MANAGMENT_IP" lmerules.sh -n | cut -d ":" -f 1) )
sed "${START_END[0]},${START_END[1]}!d" lmerules.sh >> rules.sh

mv rules.sh lmerules.sh

wget $DREAMERCONFIGSERVER3 -O vs/vsf.cfg

