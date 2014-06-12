#!/bin/bash

# requirements dsh, expect
# Usage : ./managment_config.sh <option>
# 	config_dsh : enable root login, configure dsh machine.list and group 
#	setup : download code from git, install software requirements and get testbed.sh
#	tsb_cut_nodes : get testbed.sh on nodes
#	config : configure all nodes
#	clean : clean all nodes
#	all : complete setup and config
#	update_mgmt_sh : update the configuration file management.sh
#	

USER="root"

#XXX Address used for the download of management.sh
MGT_SH_ADDR=https://www.dropbox.com/s/f5lse4stkxrwb6j/management.sh

#TODO : recuperare dal file ()

update_mgmt_sh(){
	if ! [ -n "$MGT_SH_ADDR" ]; then
		echo "MGT_SH_ADDR Not Setted"
		exit 1
	fi
	echo "Updating management.sh from $MGT_SH_ADDR..."
	wget $MGT_SH_ADDR
}

config_dsh(){

echo "Please enter testbed username: "
read OFELIA_USER
echo "Please enter testbed $OFELIA_USER pass: "
read -s OFELIA_PASS
echo
echo "Please enter testbed root pass: "
read -s ROOT_PASS
echo
while true; do
    read -p "Generate ssh key (y/n)?" yn 
    case $yn in
        [Yy]* ) ssh-keygen; break;;
        [Nn]* ) break;;
        * ) echo "(y/n)";;
    esac
done

#Enable ssh root access
echo "Enable ssh root access..."

TARGET_KEY="PermitRootLogin"
REPLACEMENT_VALUE="yes"

for i in ${NODE_LIST[@]}; do
	./send_root_cmd $i $OFELIA_USER $OFELIA_PASS $ROOT_PASS "sed -i \"s/\($TARGET_KEY * *\).*/\1$REPLACEMENT_VALUE/\" /etc/ssh/sshd_config"
	./send_root_cmd $i $OFELIA_USER $OFELIA_PASS $ROOT_PASS "/etc/init.d/ssh restart"
 	./send_root_cmd $i $OFELIA_USER $OFELIA_PASS $ROOT_PASS "echo $(cat /root/.ssh/id_rsa.pub) >/root/.ssh/authorized_keys"
done
echo ""
echo "Configure DSH..."

#DSH configuration file
TARGET_KEY="remoteshell"
REPLACEMENT_VALUE="ssh"

sed -i "s/\($TARGET_KEY *= *\).*/\1$REPLACEMENT_VALUE/" /etc/dsh/dsh.conf

#Configure machines.list
#edit /etc/dsh/machines.list file adding all machines of the testbed

echo "Configure machines.list..."


rm /etc/dsh/machines.list

for i in ${NODE_LIST[@]}; do
	echo $i
	echo $USER@$i >> /etc/dsh/machines.list
done

#Creating groups
#grouped creating files in /etc/dsh/group
echo "Creating groups..."
for i in ${DSH_GROUPS[@]}; do
	echo > /etc/dsh/group/$i
	echo $i
	eval group=\${${i}[*]}
	for host in ${group[@]};do
		echo $USER@$host
		echo $USER@$host >> /etc/dsh/group/$i
	done	
done



## fine configurazione DSH ##

}


#TODO: colonare il repo giusto

WORK_DIR=/root/
REPO_DIR=dreamer-setup-scripts
REPO_URL=https://github.com/netgroup/Dreamer-Setup-Scripts

TESTBED_SH_ADDR="https://www.dropbox.com/s/smsyctn1qj72kpk/testbed.sh"
LMERULES_SH_ADDR="https://www.dropbox.com/s/vp30krz8vamjoxn/lmerules.sh"

clone_dreamer(){
#Install DREAMER installation and management scripts
#git clone su tutti i nodi della lista NODE_LIST
dsh -M -g all -c rm -r -f $REPO_DIR
dsh -M -g all -c git clone $REPO_URL
}


for_all_group() {

for i in ${DSH_GROUPS[@]}; do
        if [ "$i" = "OSHI" ]; then
                #Install OSHI nodes
				echo $i
                dsh -M -g $i -c "cd ./$REPO_DIR/oshi/ && ./$1" 
        elif [ "$i" = "ROUTER" ];then
                #Install IP_ROUTER nodes
                echo $i
				dsh -M -g $i -c "cd ./$REPO_DIR/ip_router/ && ./$1"  
        elif [ "$i" = "EUH" ] || [ "$i" = "CTRL" ];then
				#Install other machines
				echo $i
                dsh -M -g $i -c "cd ./$REPO_DIR/othernodes/ && ./$1" 
		else    
            	#Not Handled
				echo "$i Not Handled"
				exit 1 			 
        fi
done

}

change_sh_addresses(){

for i in ${DSH_GROUPS[@]}; do
        if [ "$i" = "OSHI" ]; then
				echo $i
				if ! [ -n "$TESTBED_SH_ADDR" ] || ! [ -n "$LMERULES_SH_ADDR" ]; then
					echo "Addresses Not Setted For OSHI"
					exit 1
				fi
				TARGET_KEY="DREAMERCONFIGSERVER"
				REPLACEMENT_VALUE="$TESTBED_SH_ADDR"
				TARGET_KEY2="DREAMERCONFIGSERVER2"
				REPLACEMENT_VALUE2="$LMERULES_SH_ADDR"
				dsh -M -g $i -c "cd ./$REPO_DIR/oshi/ && sed -i \"s/\($TARGET_KEY *= *\).*/\1$REPLACEMENT_VALUE/\" ./remote.cfg  && sed -i \"s/\($TARGET_KEY2 *= *\).*/\1$REPLACEMENT_VALUE2/\" ./remote.cfg"
        elif [ "$i" = "ROUTER" ];then
                echo $i
				if ! [ -n "$TESTBED_SH_ADDR" ]; then
					echo "Addresses Not Setted For ROUTER"
					exit 1
				fi
				TARGET_KEY="DREAMERCONFIGSERVER"
				REPLACEMENT_VALUE="$TESTBED_SH_ADDR"
				dsh -M -g $i -c "cd ./$REPO_DIR/ip_router/ && sed -i \"s/\($TARGET_KEY *= *\).*/\1$REPLACEMENT_VALUE/\" ./remote.cfg"
        elif [ "$i" = "EUH" ] || [ "$i" = "CTRL" ];then
				echo $i
				if ! [ -n "$TESTBED_SH_ADDR" ]; then
					echo "Addresses Not Setted For EUH and CTRL"
					exit 1
				fi
				TARGET_KEY="DREAMERCONFIGSERVER"
				REPLACEMENT_VALUE="$TESTBED_SH_ADDR"
				dsh -M -g $i -c "cd ./$REPO_DIR/ip_router/ && sed -i \"s/\($TARGET_KEY *= *\).*/\1$REPLACEMENT_VALUE/\" ./remote.cfg"
		else    
            	#Not Handled
				echo "$i Not Handled"
				exit 1 			 
        fi
done

}

setup_nodes(){
#setup.sh
for_all_group setup.sh
}

tsb_cut_nodes(){
#caricare il testbed.sh (da decidere)
for_all_group tsb_cut.sh
}

config(){
#config.sh su tutti i nodi 
for_all_group config.sh
}

clean(){
#clean su tutti i nodi
for_all_group clean.sh
}

setup(){
#TODO:ripristinare
#clone_dreamer
setup_nodes
tsb_cut_nodes
}

all(){
config_dsh
setup
config
}

if [ -f management.sh ];
	then
		# If cfg file is present in current folder, use it
		echo "---> File found in current folder. Using local configuration file management.sh"
		source management.sh
elif [ "$1" != "update_mgmt_sh" ];
	then
		echo "Error File Not Found..."
		exit -1
fi

$1
