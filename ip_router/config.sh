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

plain_ip_router_vxlan () {
	
	# setup_interfaces
	ovs-vsctl add-br $TUNL_BRIDGE
	echo -e "\n-Adding interfaces to bridge $TUNL_BRIDGE"
	
	for i in ${TAP[@]}; do
		eval remoteport=\${${i}[0]}
		eval remoteaddr=\${!$i[1]}
		# ovs-vsctl add-port $TUNL_BRIDGE  $i -- set Interface $i type=vxlan options:remote_ip=$remoteaddr options:dst_port=$remoteport
		ovs-vsctl add-port $TUNL_BRIDGE  $i -- set Interface $i type=vxlan options:remote_ip=$remoteaddr options:key=$remoteport

	done

	echo -e "\n-Adding internal virtual interfaces to bridge $TUNL_BRIDGE"
	for i in ${VI[@]}; do
		ovs-vsctl add-port $TUNL_BRIDGE $i -- set Interface $i type=internal
		ifconfig $i up	
	done
	declare -a ofporttap &&
	declare -a ofportVI &&

	for i in ${TAP[@]}; do
	    OFPORTSTAP[${#OFPORTSTAP[@]}]=$(ovs-vsctl find Interface name=$i | grep -m 1 ofport | awk -F':' '{print $2}' | awk '{ gsub (" ", "", $0); print}')
	done

	for i in ${VI[@]}; do
		OFPORTSVI[${#OFPORTSVI[@]}]=$(ovs-vsctl find Interface name=$i | grep -m 1 ofport | awk -F':' '{print $2}' | awk '{ gsub (" ", "", $0); print}')
	done
	for (( i=0; i<${#OFPORTSTAP[@]}; i++ )); do
	        ovs-ofctl add-flow $TUNL_BRIDGE hard_timeout=0,priority=300,in_port=${OFPORTSTAP[$i]},action=output:${OFPORTSVI[$i]}
	        ovs-ofctl add-flow $TUNL_BRIDGE hard_timeout=0,priority=300,in_port=${OFPORTSVI[$i]},action=output:${OFPORTSTAP[$i]}
	done
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
    			eval ELEMENT=\${${i}[5]}
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
	eval remoteaddr=\${!$i[5]}
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

if [ "$TUNNELING" = "OpenVPN" ];then

for i in ${TAP[@]}; do
eval VIaddr=\${${i}[2]}
echo -e "
interface ${i}
ip address $VIaddr
link-detect" >> /etc/quagga/zebra.conf
done

elif [ "$TUNNELING" = "VXLAN" ];then

for i in ${VI[@]}; do
eval VIaddr=\${${i}[0]}
echo -e "
interface ${i}
ip address $VIaddr
link-detect" >> /etc/quagga/zebra.conf
done

fi
# OSPFD.CONF
echo -e "! -*- ospf -*-
!
hostname $HOST
password $ROUTERPWD
log file /var/log/quagga/ospfd.log\n
interface lo
ospf cost ${LOOPBACK[1]}
ospf hello-interval ${LOOPBACK[2]}\n" > /etc/quagga/ospfd.conf &&

if [ "$TUNNELING" = "OpenVPN" ];then

for i in ${TAP[@]}; do
eval quaggaospfcost=\${${i}[3]}
eval quaggahellointerval=\${${i}[4]}
echo -e "interface $i
ospf cost $quaggaospfcost
ospf hello-interval $quaggahellointerval\n" >> /etc/quagga/ospfd.conf
done

elif [ "$TUNNELING" = "VXLAN" ];then

for i in ${VI[@]}; do
eval quaggaospfcost=\${${i}[1]}
eval quaggahellointerval=\${${i}[2]}
echo -e "interface $i
ospf cost $quaggaospfcost
ospf hello-interval $quaggahellointerval\n" >> /etc/quagga/ospfd.conf
done

fi

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


if [ "$TUNNELING" = "VXLAN" ];then
	echo -e "\n-Configuring OpenVSwitch"
	plain_ip_router_vxlan
fi

echo -e "\n\nDREAMER IP/SDN hybrid node configuration ended succesfully. Enjoy!\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS
