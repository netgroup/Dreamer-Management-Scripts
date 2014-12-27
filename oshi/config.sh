#!/bin/bash
# The configure a DREAMER node - after running setup.sh included in DREAMER package

echo -e "\n"
echo "#############################################################"
echo "##           DREAMER IP/SDN Hyibrid node config            ##"
echo "##                                                         ##"
echo "## The configuration process can last many minutes. Please ##"
echo "## and do not interrupt the process.                       ##"
echo "#############################################################"

TUNL_BRIDGE=br-tun

oshi () {

	echo -e "\n-Configuring OpenVSwitch fo OSHI"
	echo -e "\n-Creating OpenVSwitch bridge $BRIDGENAME"
	
	ovs-vsctl add-br $BRIDGENAME &&
	echo -e "\n-Setting OpenFlow controller for bridge ${BRIDGENAME}"
	let CONTROLLERS
	for (( i=0; i<${#CTRL[@]}; i++ )); do
		eval CONTROLLER=\${${CTRL[$i]}[0]}
		eval CONTROLLERPORT=\${${CTRL[$i]}[1]}
		if [ $i -eq 0 ];
			then
				CONTROLLERS="tcp:$CONTROLLER:$CONTROLLERPORT"
			else
				CONTROLLERS="$CONTROLLERS tcp:$CONTROLLER:$CONTROLLERPORT"
		fi
	done

	ovs-vsctl set-controller $BRIDGENAME $CONTROLLERS &&
	ovs-vsctl set-fail-mode $BRIDGENAME secure &&

	CTRLS=( $(ovs-vsctl find controller | grep _uuid |awk -F':' '{print $2}' | awk '{ gsub (" ", "", $0); print}')  )
    for i in ${CTRLS[@]}; do
            echo $i
            ovs-vsctl set controller $i connection_mode=out-of-band 
    done

	ovs-vsctl set bridge $BRIDGENAME other-config:datapath-id=$DPID

	if [ "$TUNNELING" = "VXLAN" ];then

		echo -e "\n-Adding interfaces to bridge $BRIDGENAME"
		for i in ${TAP[@]}; do
    		eval remoteport=\${${i}[0]}  
			eval remoteaddr=\${!$i[1]}
			ovs-vsctl add-port $BRIDGENAME $i -- set Interface $i type=vxlan options:remote_ip=$remoteaddr options:key=$remoteport
		done

		echo -e "\n-Adding pw interfaces to bridge $BRIDGENAME"
		for i in ${PWTAP[@]}; do
    		eval remoteport=\${${i}[0]}  
			eval remoteaddr=\${!$i[1]}
			ovs-vsctl add-port $BRIDGENAME $i -- set Interface $i type=vxlan options:remote_ip=$remoteaddr options:key=$remoteport
		done
	else
		echo -e "\n-Adding interfaces to bridge $BRIDGENAME"
		for i in ${TAP[@]}; do
			ovs-vsctl add-port $BRIDGENAME $i
		done

		echo -e "\n-Adding pw interfaces to bridge $BRIDGENAME"
		for i in ${PWTAP[@]}; do
    		ovs-vsctl add-port $BRIDGENAME $i
		done
	fi

	echo -e "\n-Adding internal virtual interfaces to OpenVSwitch"
	for i in ${VI[@]}; do
		ovs-vsctl add-port $BRIDGENAME $i -- set Interface $i type=internal
		ifconfig $i up	
	done

	echo -e "\n-Adding internal virtual tap interfaces to OpenVSwitch"
	for i in ${VITAP[@]}; do
		ovs-vsctl add-port $BRIDGENAME $i -- set Interface $i type=internal
		ifconfig $i up	
	done
	
	echo -e "\n-Creating static rules on OpenVSwitch"
	python lme.py
	echo -e "\n-Deploying VSF"
	cd vs/
	python vsf_deployer.py
	cd ..

}

setup_interfaces () {

	ii=0
	for j in ${INTERFACES[@]}; do
		eval interface_ip=\${${j}[0]}
		eval interface_netmask=\${${j}[1]}
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
    			eval ELEMENT=\${${i}[2]}
    		else
            	eval ELEMENT=\${${i}[1]} 
            fi
            if [ $(echo ${ENDIPS[@]} | grep -o $ELEMENT | wc -w) -eq 0 ];then
                    ENDIPS[${#ENDIPS[@]}]=$ELEMENT
            fi
    done

	for i in ${PWTAP[@]}; do
    		if [ "$TUNNELING" = "OpenVPN" ]; then
    			eval ELEMENT=\${${i}[2]}
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


echo -e "\n-Setting up physical interfaces"

setup_interfaces

if [ $(ps aux | grep avahi-daemon | wc -l) -gt 1 ]; then
	/etc/init.d/avahi-daemon stop
fi

echo -e "\n-Setting hostname"
# setting hostname in /etc/hostname
echo "$HOST" > /etc/hostname &&
# setting hostname in /etc/hosts
sed -i '2d' /etc/hosts
sed -i "1a\127.0.0.1\t$HOST" /etc/hosts &&
hostname $HOST &&


if [ "$TUNNELING" = "OpenVPN" ];then

echo -e "\n-Configuring OpenVPN"
# writing *.conf OpenVPN files in /etc/openvpn
for i in ${TAP[@]}; do
	eval localport=\${${i}[0]}
    eval remoteport=\${${i}[1]}
	eval remoteaddr=\${!$i[2]}
	echo "dev ${i}
mode p2p
port $localport
remote $remoteaddr $remoteport
script-security 3 system
up \"bash /etc/openvpn/${i}.sh\"" > /etc/openvpn/$i.conf
done

for i in ${PWTAP[@]}; do
	eval localport=\${${i}[0]}
    eval remoteport=\${${i}[1]}
	eval remoteaddr=\${!$i[2]}
	echo "dev ${i}
mode p2p
port $localport
remote $remoteaddr $remoteport
script-security 3 system
up \"bash /etc/openvpn/${i}.sh\"" > /etc/openvpn/$i.conf
done

for i in ${TAP[@]}; do
	echo "#!/bin/bash
ip link set ${i} up" > /etc/openvpn/$i.sh
done

for i in ${PWTAP[@]}; do
	echo "#!/bin/bash
ip link set ${i} up" > /etc/openvpn/$i.sh
done

echo -e "\n-Starting OpenVPN service"
/etc/init.d/openvpn start 

fi

echo -e "\n-Configuring Quagga"
# ZEBRA.CONF
echo -e "
! -*- zebra -*-
log file /var/log/quagga/zebra.log\n
hostname $HOST
password ${ROUTERPWD}
enable password ${ROUTERPWD}

interface lo
ip address $LOOPBACK
link-detect" > /etc/quagga/zebra.conf &&
for i in ${VI[@]}; do
eval VIaddr=\${${i}[0]}

if [ "${COEX[0]}" = "COEXA" ];then

echo -e "
interface ${i}.${COEX[1]}
ip address $VIaddr
link-detect" >> /etc/quagga/zebra.conf

else

echo -e "
interface ${i}
ip address $VIaddr
link-detect" >> /etc/quagga/zebra.conf

fi

done

# OSPFD.CONF
echo -e "! -*- ospf -*-
!
hostname $HOST
password $ROUTERPWD
log file /var/log/quagga/ospfd.log\n
interface lo
ospf cost ${LOOPBACK[1]}
ospf hello-interval ${LOOPBACK[2]}\n" > /etc/quagga/ospfd.conf &&
for i in ${VI[@]}; do
eval quaggaospfcost=\${${i}[1]}
eval quaggahellointerval=\${${i}[2]}

if [ "${COEX[0]}" = "COEXA" ];then

echo -e "interface $i.${COEX[1]}
ospf cost $quaggaospfcost
ospf hello-interval $quaggahellointerval\n" >> /etc/quagga/ospfd.conf

else

echo -e "interface $i
ospf cost $quaggaospfcost
ospf hello-interval $quaggahellointerval\n" >> /etc/quagga/ospfd.conf

fi

done

echo -e "router ospf\n" >> /etc/quagga/ospfd.conf
for i in ${OSPFNET[@]}; do
	eval quaggaannouncednet=\${${i}[0]}
	eval quaggarouterarea=\${${i}[1]}
	echo "network $quaggaannouncednet area $quaggarouterarea" >> /etc/quagga/ospfd.conf
done

# QUAGGA DAEMONS
sed -i -e 's/zebra=no/zebra=yes/g' /etc/quagga/daemons &&
sed -i -e 's/ospfd=no/ospfd=yes/g' /etc/quagga/daemons &&
echo "babeld=no" >> /etc/quagga/daemons &&

# QUAGGA DEBIAN.CONF
sed -i -e 's/zebra_options=" --daemon -A 127.0.0.1"/zebra_options=" --daemon"/g' /etc/quagga/debian.conf &&
echo -e "babeld_options=\" --daemon -A 127.0.0.1\"\n
# The list of daemons to watch is automatically generated by the init script.
watchquagga_enable=no
watchquagga_options=\"--daemon\"" >> /etc/quagga/debian.conf &&

# QUAGGA VTYSH.CONF
echo "!
!service integrated-vtysh-config
hostname $HOST
username root $ROUTERPWD
!"> /etc/quagga/vtysh.conf &&

# QUAGGA CONF FILE PERMISSIONS
chown quagga:quaggavty /etc/quagga/*.conf &&
chmod 640 /etc/quagga/*.conf &&

# DO NOT DISPLY END SIGN AFTER EACH QUAGGA COMMAND
VTYSH_PAGER=more > /etc/environment &&

# ENABLE LINUX FORWARDING
echo -e "\n-Enabling Linux forwarding"
echo "1" > /proc/sys/net/ipv4/ip_forward &&
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf &&

# DISABLE LINUX RPF
echo -e "\n-Disabling Linux RPF"
sysctl -w "net.ipv4.conf.all.rp_filter=0" &&

echo -e "\n-Starting Quagga daemon"
/etc/init.d/quagga start

echo -e "\n-Configuring OpenVSwitch"

oshi

if [ "${COEX[0]}" = "COEXA" ];then

echo -e "\nCOEXA...Setting UP vi.${COEX[1]} interface"

for i in ${VI[@]}; do

ip link set ${i} up
vconfig add ${i} ${COEX[1]} 1> /dev/null
ip link set ${i}.${COEX[1]} up 2> /dev/null

done

elif [ "${COEX[0]}" = "COEXH" ];then

echo -e "\nCOEXH...Switching to OpenFlow13"
ovs-vsctl set bridge $BRIDGENAME protocols=OpenFlow13

fi



echo -e "\n\nDREAMER IP/SDN hybrid node configuration ended succesfully. Enjoy!\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS
