#!/bin/bash
# The configure a DREAMER node - after running setup.sh included in DREAMER node package

echo -e "\n"
echo "#############################################################"
echo "##           			DREAMER node config            		 ##"
echo "##                                                         ##"
echo "## The configuration process can last many minutes. Please ##"
echo "## and do not interrupt the process.                       ##"
echo "#############################################################"

echo -e "\n-Looking for a valid configuration file..."
echo -e "---> Looking for configuration file in current directory ($(pwd))..."
if [ -f testbed.sh ];
	then
		# If cfg file is present in current folder, use it
		echo "---> File found in $(pwd). Using local configuration file testbed.sh"
		source testbed.sh
	else
		# If cfg file is not present in current folder, try to look into /etc/dreamer
		echo -e "--> Local configuration file not found in $(pwd).\n---> Looking for configuration file in /etc/dreamer..."
		if [ -f /etc/dreamer/testbed.sh ];
			then
				# If file is present in /etc/dreamer use it
				echo "---> File found in /etc/dreamer. Using local configuration file testbed.sh"
				source /etc/dreamer/testbed.sh
			else
				# If file is not present both in current directory and into /etc/dreamer, try to look for a remote.cfg file in current directory and read from
				# it the variable dreamerconfigserver (link to the file on internet - http)
				echo -e "--> Local configuration file not found in /etc/dreamer.\n---> Looking online for an updated configuration file. Looking for a remote.cfg file in current directory ($(pwd))..."
				if [ -f /etc/dreamer/remote.cfg ];
					then
						echo -e "\n---> remote.cfg file found in /etc/dreamer. Trying to read the file... "
						source /etc/dreamer/remote.cfg
						if [ -n $DREAMERCONFIGSERVER ];
							then
								echo -e "---> DREAMERCONFIGSERVER variable found in remote.cfg. Trying to download the configuration file from $DREAMERCONFIGSERVER"
								wget $DREAMERCONFIGSERVER 2> /dev/null
								if [ -f testbed.sh  ];
									then
										# Get the management IP address (IPv4 set on eth0)
										MNGMTADDR=$(ifconfig eth0 | grep -e "inet addr" | awk '{split($0,a," "); print a[2]}' | awk '{split($0,a,":"); print a[2]}')
										wget -O- -q $DREAMERCONFIGSERVER | awk ' /'"# $MNGMTADDR - start"'/ {flag=1;next} /'"# $MNGMTADDR - end"'/{flag=0} flag { print }' /dev/stdin > /etc/dreamer/testbed.sh
										source testbed.sh
										echo "---> Configuration file downloaded in /etc/dreamer."
									else
										echo "---> ERROR: No configuration files found at $DREAMERCONFIGSERVER. Try to upload the file again and make sure that the path is still available."
										EXIT_ERROR=-1
										exit $EXIT_ERROR
								fi
							else
								echo -e "---> ERROR: DREAMERCONFIGSERVER variable not found in remote.cfg file or value not correct. Please, try to correct the value."
								EXIT_ERROR=-1
								exit $EXIT_ERROR
						fi
					else
						echo -e "\n---> ERROR: remote.cfg file not found in /etc/draemer."
						echo -e "\n\n---> ERROR: no configuration files found. Please set either a local or a remote configuration file before starting."
						EXIT_ERROR=-1
                        exit $EXIT_ERROR
				fi
		fi
fi

# Check addresses
echo -e "\n-Checking addresses compatibilities between testbed mgmt network and chosen addresses"
MGMTADDR=$(ifconfig eth0 | grep "inet addr" | awk -F' ' '{print $2}' | awk -F':' '{print $2}')
MGMTMASK=$(ifconfig eth0 | grep "inet addr" | awk -F' ' '{print $4}' | awk -F':' '{print $2}')
MGMTNETWORK=$(ipcalc $MGMTADDR $MGMTMASK 2> /dev/null | grep Network | awk '{split($0,a," "); print a[2]}')
for (( i=0; i<${#INTERFACES[@]}; i++ )); do
        eval addr=\${${INTERFACES[$i]}[0]}
        eval netmask=\${${INTERFACES[$i]}[1]}
        CURRENTNET=$(ipcalc $addr $netmask 2> /dev/null | grep Network | awk '{split($0,a," "); print a[2]}')
        if [ $CURRENTNET == $MGMTNETWORK ]
                then
                        echo -e "\nERROR: IP addresses used in testbed.sh conflict with management network. Please choouse other adresses."
                        EXIT_ERROR=-1
                        exit $EXIT_ERROR
        fi
done
for i in ${TAP[@]}; do
        eval LOCALIP=\${${i}[2]}
        CURRENTNET=$(ipcalc $LOCALIP 2> /dev/null | grep Network | awk '{split($0,a," "); print a[2]}')
        if [ $CURRENTNET == $MGMTNETWORK ]
                then
                        echo -e "\nERROR: IP addresses used in testbed.sh conflict with management network. Please choouse other adresses."
                        EXIT_ERROR=-1
                        exit $EXIT_ERROR
        fi
done

echo -e "\n-Setting up physical interfaces"
# deleting white spaces in /etc/network/interfaces
sed -i -e '/^$/d' /etc/network/interfaces &&
# deleting lines related to the interfaces involved in /etc/network/interfaces
sed -i -e 's/auto eth[^0]//g' /etc/network/interfaces &&
# adding configuration for interfaces into /etc/network/interfaces
for i in ${INTERFACES[@]}; do
echo "
auto ${i}
iface ${i} inet manual
up ifconfig ${i} up" >> /etc/network/interfaces
done

# adding configuration for vlan interfaces into /etc/network/interfaces
echo -e "\n-Setting VLAN ${slicevlan} on interfaces"
for (( i=0; i<${#INTERFACES[@]}; i++ )); do
	eval addr=\${${INTERFACES[$i]}[0]}
	eval netmask=\${${INTERFACES[$i]}[1]}
	echo "
auto ${INTERFACES[$i]}.$SLICEVLAN
iface ${INTERFACES[$i]}.$SLICEVLAN inet static
address $addr
netmask $netmask">> /etc/network/interfaces
done

echo -e "\n-Setting static routes"
declare -a ENDIPS
for i in ${TAP[@]}; do
	eval ELEMENT=\${${i}[3]}
	if [ $(echo ${ENDIPS[@]} | grep -o $ELEMENT | wc -w) -eq 0 ]
		then
			ENDIPS[${#ENDIPS[@]}]=$ELEMENT
	fi
done
for (( i=0; i<${#ENDIPS[@]}; i++ )); do
	eval remoteaddr=\${${ENDIPS[$i]}[0]}
	eval interface=\${${ENDIPS[$i]}[1]}
	sed -i "/iface $interface.$SLICEVLAN inet static/a\
up route add -host $remoteaddr dev $interface.$SLICEVLAN
" /etc/network/interfaces
done

echo -e "\n-Restarting network services"
/etc/init.d/networking restart &&
service avahi-daemon stop &&

echo -e "\n-Setting hostname"
# setting hostname in /etc/hostname
echo "$HOST" > /etc/hostname &&
# setting hostname in /etc/hosts
sed -i '2d' /etc/hosts
sed -i "1a\127.0.0.1\t$HOST" /etc/hosts &&
hostname $HOST &&

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
/etc/init.d/openvpn start &&

echo -e "\n-Adding static routes for ${STATICROUTE[3]} device"
route add -net ${MGMTNET[0]} netmask ${MGMTNET[1]} gw ${MGMTNET[2]} dev ${MGMTNET[3]} &&
route add -net ${STATICROUTE[0]} netmask ${STATICROUTE[1]} gw ${STATICROUTE[2]} dev ${STATICROUTE[3]} &&

echo -e "\n-Setting in bash.rc default root folder after login to /etc/dreamer"
echo -e "cd /etc/dreamer" >> /root/.bashrc

echo -e "\n\nDREAMER node configuration process ended succesfully. Enjoy!\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS