#!/bin/bash
# The script reconfigures associations in OVS between OpenVPN TAP interfaces and VI quagga interfaces

echo -e "\n"
echo "#############################################################"
echo "##           DREAMER IP/SDN Hyibrid node config            ##"
echo "##                                                         ##"
echo "## The configuration process can last many minutes. Please ##"
echo "## and do not interrupt the process.                       ##"
echo "#############################################################"

# This script is used if you lost the association on OpenvSwitch between Quagga Virtual interfaces (usually viX) and OpenVPN tap interfaces.
# To run it you need to fill in properly the testbed.sh file contained into /etc/dreamer
# The file is also used to automatically activate mapping rules when the server boot.

# Check if the configuration file is present
if [ ! -f "/etc/dreamer/testbed.sh" ]
	then
		echo "ERROR: Testbed.sh confgiuration file not present in /etc/draemer. Please create or copy it and try again."
		exit
fi

source /etc/dreamer/testbed.sh

# Removing previous bridge
echo -e "\n-Removing existant bridge" &&
OLDBRIDGE=$(ovs-vsctl show | sed -n "2 p" | awk '{split($0,a," "); print a[2]}')
ovs-vsctl del-br $OLDBRIDGE 2> /dev/null &&

echo -e "\n-Creating OpenVSwitch bridge br-dreamer"
ovs-vsctl add-br $BRIDGENAME &&
echo -e "\n-Setting OpenFlow controller ${CTRL[0]}:${CTRL[1]} for bridge ${BRIDGENAME}"
ovs-vsctl set-controller $BRIDGENAME tcp:${CTRL[0]}:${CTRL[1]} &&
ovs-vsctl set-fail-mode $BRIDGENAME secure &&
ovs-vsctl set controller $BRIDGENAME connection-mode=in-band &&

echo -e "\n-Adding interfaces to OpenVSwitch" &&
for i in ${TAP[@]}; do
	ovs-vsctl add-port $BRIDGENAME $i
done

echo -e "\n-Adding internal virtual interfaces to OpenVSwitch" &&
for i in ${QUAGGAINT[@]}; do
	ovs-vsctl add-port $BRIDGENAME $i -- set Interface $i type=internal
done

echo -e "\n-Creating static rules on OpenVSwitch" &&
declare -a ofporttap &&
declare -a ofportquaggaint &&

for i in ${TAP[@]}; do
    OFPORTSTAP[${#OFPORTSTAP[@]}]=$(ovs-vsctl find Interface name=$i | grep ofport | awk -F':' '{print $2}' | awk '{ gsub (" ", "", $0); print}')
done

for i in ${QUAGGAINT[@]}; do
	OFPORTSQUAGGAINT[${#OFPORTSQUAGGAINT[@]}]=$(ovs-vsctl find Interface name=$i | grep ofport | awk -F':' '{print $2}' | awk '{ gsub (" ", "", $0); print}')
done
for (( i=0; i<${#OFPORTSTAP[@]}; i++ )); do
        ovs-ofctl add-flow $BRIDGENAME hard_timeout=0,priority=300,in_port=${OFPORTSTAP[$i]},action=output:${OFPORTSQUAGGAINT[$i]}
        ovs-ofctl add-flow $BRIDGENAME hard_timeout=0,priority=300,in_port=${OFPORTSQUAGGAINT[$i]},action=output:${OFPORTSTAP[$i]}
done

ovs-ofctl add-flow $BRIDGENAME hard_timeout=0,priority=301,dl_type=0x88cc,action=controller &&
ovs-ofctl add-flow $BRIDGENAME hard_timeout=0,priority=301,dl_type=0x8942,action=controller &&

echo -e "\n\nDREAMER IP/SDN hybrid node configuration ended succesfully. Enjoy!\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS