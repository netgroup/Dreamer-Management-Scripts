#!/bin/bash
# The configure a DREAMER node - after running setup.sh included in DREAMER node package

echo -e "\n"
echo "#############################################################"
echo "##           			DREAMER node config            		 ##"
echo "##                                                         ##"
echo "## The configuration process can last many minutes. Please ##"
echo "## and do not interrupt the process.                       ##"
echo "#############################################################"

TUNL_BRIDGE=br-tun

plain_node_vxlan () {
        
        ii=0
        ovs-vsctl add-br $TUNL_BRIDGE
        echo -e "\n-Adding interfaces to bridge $TUNL_BRIDGE"

        for i in ${TAP[@]}; do
                eval remoteport=\${${i}[0]} 
                eval remoteaddr=\${!$i[1]}
                ovs-vsctl add-port $TUNL_BRIDGE  $i -- set Interface $i type=vxlan options:remote_ip=$remoteaddr options:key=$remoteport
        done

        echo -e "\n-Adding internal virtual interfaces to OpenVSwitch"

        y=0
        for i in ${VI[@]}; do
            ovs-vsctl add-port $TUNL_BRIDGE $i -- set Interface $i type=internal
            eval ip=\${${VI[$y]}[0]}
            echo $ip
            ip a a $ip  dev $i
			ifconfig $i up            
			y=$((y+1))
        done

        declare -a port_tap &&
        declare -a port_vi_tap &&
        for i in ${TAP[@]}; do
            PORT_TAP[${#PORT_TAP[@]}]=$(ovs-vsctl find Interface name=$i | grep -m 1 ofport | awk -F':' '{print $2}' | awk '{ gsub (" ", "", $0); print}')
            # PORT_VI_TAP[${#PORT_VI_TAP[@]}]=$(ovs-vsctl find Interface name=vi-$i | grep -m 1 ofport | awk -F':' '{print $2}' | awk '{ gsub (" ", "", $0); print}')
        done
        for i in ${VI[@]}; do
            PORT_VI_TAP[${#PORT_VI_TAP[@]}]=$(ovs-vsctl find Interface name=$i | grep -m 1 ofport | awk -F':' '{print $2}' | awk '{ gsub (" ", "", $0); print}')
        done
        for (( i=0; i<${#PORT_TAP[@]}; i++ )); do
                ovs-ofctl add-flow $TUNL_BRIDGE hard_timeout=0,priority=300,in_port=${PORT_TAP[$i]},action=output:${PORT_VI_TAP[$i]}
                ovs-ofctl add-flow $TUNL_BRIDGE hard_timeout=0,priority=300,in_port=${PORT_VI_TAP[$i]},action=output:${PORT_TAP[$i]}
        done
        ii=$((ii+1))
}

setup_interfaces () {
    ii=0
    for j in ${INTERFACES[@]}; do
            echo -e "\n-Creating OpenVSwitch bridge $TUNL_BRIDGE"
            eval interface_ip=\${${j}[0]}
            eval interface_netmask=\${${j}[1]}
        	echo $interface_ip
        	echo $interface_netmask
            ip link set ${INTERFACES[$ii]} up
            vconfig add ${INTERFACES[$ii]} $SLICEVLAN
            ip link set ${INTERFACES[$ii]}.$SLICEVLAN up
            ifconfig $j.$SLICEVLAN $interface_ip netmask $interface_netmask
            ii=$((ii+1))
    done
    # set static routes
    declare -a ENDIPS
    for i in ${TAP[@]}; do
            if [ "$TUNNELING" = "OpenVPN" ]; then
                eval ELEMENT=\${${i}[3]}
            else
                eval ELEMENT=\${${i}[1]} 
	        fi
            if [ $(echo ${ENDIPS[@]} | grep -o $ELEMENT | wc -w) -eq 0 ];then
                    ENDIPS[${#ENDIPS[@]}]=$ELEMENT
            fi
    done
    for (( i=0; i<${#ENDIPS[@]}; i++ )); do
            eval remoteaddr=\${${ENDIPS[$i]}[0]}
            eval interface=\${${ENDIPS[$i]}[1]}
	    #echo  $remoteaddr
            ip r a $remoteaddr dev $interface.$SLICEVLAN 
    done
}

echo -e "\n-Looking for a valid configuration file..."
echo -e "---> Looking for configuration file in current directory ($(pwd))..."
if [ -f testbed.sh ];
	then
		# If cfg file is present in current folder, use it
		echo "---> File found in $(pwd). Using local configuration file testbed.sh"
		source testbed.sh
	else
		# If cfg file is not present in current folder, try to look into /etc/dreamer
		echo -e "--> Local configuration file not found in $(pwd).\n---> Downloading from Server address contained in remote.cfg..."
		./update_cfg.sh
		if ! [ -f testbed.sh ]; then
			echo -e "--> Update Failed...Check address in remote.cfg"
			exit 1
		fi
		source testbed.sh
fi

setup_interfaces

service avahi-daemon stop &&

echo -e "\n-Setting hostname"
# setting hostname in /etc/hostname
echo "$HOST" > /etc/hostname &&
# setting hostname in /etc/hosts
sed -i '2d' /etc/hosts
sed -i "1a\127.0.0.1\t$HOST" /etc/hosts &&
hostname $HOST &&

if [ "$TUNNELING" = "OpenVPN" ]; then

echo -e "\n-Configuring OpenVPN"
# writing *.conf OpenVPN files in /etc/openvpn
for i in ${TAP[@]}; do 
	eval localport=\${${i}[0]}
    eval remoteport=\${${i}[1]}
	eval remoteaddr=\${!$i[3]}
	echo "dev ${i}
mode p2p
port $localport
remote $remoteaddr $remoteport
script-security 3 system
up \"bash /etc/openvpn/${i}.sh\"" > /etc/openvpn/$i.conf
done

for i in ${TAP[@]}; do
	eval IPADDRESS=\${${i}[2]}
	echo "#!/bin/bash
ip addr add ${IPADDRESS} dev ${i}
ip link set ${i} up" > /etc/openvpn/$i.sh
done

echo -e "\n-Starting OpenVPN service"
/etc/init.d/openvpn start 

else

plain_node_vxlan

fi

echo -e "\n-Adding static routes for ${STATICROUTE[3]} device"
if [ "$TESTBED" = "OFELIA" ]; then
    route add -net ${MGMTNET[0]} netmask ${MGMTNET[1]} gw ${MGMTNET[2]} dev ${MGMTNET[3]} 
fi
route add -net ${STATICROUTE[0]} netmask ${STATICROUTE[1]} gw ${STATICROUTE[2]} dev ${STATICROUTE[3]}

echo -e "\n\nDREAMER node configuration process ended succesfully. Enjoy!\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS
