#!/bin/bash
# The script reset a DREAMER node to the default state

echo -e "\n"
echo "#############################################################"
echo "##  			DREAMER node configuration cleaning     	 ##"
echo "##                                                         ##"
echo "## The cleaning process can last many minutes. Please,     ##"
echo "## do not interrupt the process.                           ##"
echo "#############################################################"

# Restoring default root folder after login, in .bashrc
sed -i -e 's/cd \/etc\/dreamer//g' /root/.bashrc &&

# OpenVPN
if [ $(ip link show | grep tap | wc -l) -gt 0 ]; then
	echo -e "\n-Turning off OpenVPN tap interfaces"
	declare -a tap
	counter=1
	endofcounter=$(($(ip link show | grep tap | wc -l) + 1))
	while [ $counter -lt $endofcounter ]; do
			arraycounter=$(($counter-1))
			tap[$arraycounter]=$(ip link show | grep tap | sed -n "$counter p" | awk '{split($0,a," "); print a[2]}' | awk '{split($0,a,":"); print a[1]}')
			let counter=counter+1
	done
	for (( i=0; i<${#tap[@]}; i++ )); do
		ip link set ${tap[$i]} down
	done
fi
if [ $(ps aux | grep openvpn | wc -l) -gt 1 ]; then
	echo -e "\n-Turning off OpenVPN service"
	/etc/init.d/openvpn stop
fi

echo -e "\n-Removing configuration files"
rm /etc/openvpn/*.conf 2> /dev/null
rm /etc/openvpn/*.sh 2> /dev/null

# Reset static routes
declare -a remoteaddr
declare -a interfaces
counter=1
endofcounter=$(($(route -n | grep UH | wc -l) + 1))
while [ $counter -lt $endofcounter ]; do
        arraycounter=$(($counter-1))
        interfaces[$arraycounter]=$(route -n | grep UH | sed -n "$counter p" | awk '{split($0,a," "); print a[8]}')
        remoteaddr[$arraycounter]=$(route -n | grep UH | sed -n "$counter p" | awk '{split($0,a," "); print a[1]}')
		let counter=counter+1
done

echo -e "\n-Removing static routes"
for (( i=0; i<${#interfaces[@]}; i++ )); do
	route del -host ${remoteaddr[$i]} dev ${interfaces[$i]}
done
unset interfaces

# Reset VLAN interfaces
declare -a vlan
declare -a interfaces
counter=1
endofcounter=$(($(ip link show | grep -e "eth[0-9]\." | wc -l) + 1))
while [ $counter -lt $endofcounter ]; do
        arraycounter=$(($counter-1))
        interfaces[$arraycounter]=$(ip link show | grep -e "eth[0-9]\." | sed -n "$counter p" | awk '{split($0,a,":"); print a[2]}' | awk '{split($0,a,"@"); print a[1]}' |  awk '{split($0,a,"."); print a[1]}')
        vlan[$arraycounter]=$(ip link show | grep -e "eth[0-9]\." | sed -n "$counter p" | awk '{split($0,a,":"); print a[2]}' | awk '{split($0,a,"@"); print a[1]}' |  awk '{split($0,a,"."); print a[2]}')
        let counter=counter+1
done

echo -e "\n-Turning off VLAN interfaces"
for (( i=0; i<${#interfaces[@]}; i++ )); do
        ip link set $(echo "${interfaces[$i]}.${vlan[$i]}") down
done

echo -e "\n-Removing VLAN settings on all interfaces"
for (( i=0; i<${#interfaces[@]}; i++ )); do
	vconfig rem ${interfaces[$i]}.${vlan[$i]}
done

# deleting lines related to the interfaces involved in /etc/network/interfaces
sed -i -e '/auto eth[^0]./,/\n/d' /etc/network/interfaces &&

# Reset Hostname to default (dreamernode)
echo -e "\n-Setting hostname"
# setting hostname in /etc/hostname
echo "dreamernode" > /etc/hostname &&
# removing second line from /etc/hosts
sed -i '2d' /etc/hosts
# adding new line to /etc/hosts with 127.0.0.1 oshi
sed -i "1a\127.0.0.1\tdreamernode" /etc/hosts &&
# setting up hostname
hostname dreamernode &&

# Deactivating unuseful interfaces (except management interface eth0) with ip link set ethX down
unset interfaces
declare -a interfaces
counter=1
endofcounter=$(($(ip link show | grep -e "eth[^0e]" | wc -l) + 1))
while [ $counter -lt $endofcounter ]; do
        arraycounter=$(($counter-1))
        interfaces[$arraycounter]=$(ip link show | grep -e "eth[^0e]" | sed -n "$counter p" | awk '{split($0,a," "); print a[2]}' | awk '{split($0,a,":"); print a[1]}')
        let counter=counter+1
done
echo -e "\n-Deactivating physical interfaces"
for (( i=0; i<${#interfaces[@]}; i++ )); do
	ip link set ${interfaces[$i]} down
done

echo -e "\n-Cleaning up physical interfaces configuration"
# deleting lines related to the interfaces involved in /etc/network/interfaces
sed -i -e '/auto eth[^0]/,/\n/d' /etc/network/interfaces &&
sed -i -e '/^$/d' /etc/network/interfaces &&

echo -e "\n-Restarting network services"
/etc/init.d/networking restart &&
/etc/init.d/avahi-daemon start &&

echo -e "\n\nDREAMER node cleaning process ended succesfully. Enjoy!\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS