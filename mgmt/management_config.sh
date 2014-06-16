#!/bin/bash

# XXX Requirements
# You have to install dsh, expect

# Usage : ./managment_config.sh <option>
#	update_mgmt_sh : update the configuration file management.sh
# 	config_dsh : enable root login, configure dsh machine.list and groups
#	clone_dreamer : download code from $REPO_URL
#   update_dreamer : update remote repo from $REPO_URL
#	setup_nodes : install software required and update configuration files on all nodes
#	setup : download code from $REPO_URL, install software required and update configuration files on all nodes
#	update_cfg_nodes : Update configuration files on all nodes
#	config : configure all nodes
#	clean : clean all nodes
#	all : complete setup and config
#	change_sh_addresses : update remote.cfg on the machines

LOCAL_USER="root"

#XXX Address used for the download of management.sh
MGT_SH_ADDR=https://www.dropbox.com/s/f5lse4stkxrwb6j/management.sh

update_mgmt_sh(){
	if ! [ -n "$MGT_SH_ADDR" ]; then
		echo "MGT_SH_ADDR Not Setted"
		exit 1
	fi
	rm management.sh
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

GENERATED=0

while true; do
    read -p "Generate ssh key (y/n)?" yn 
    case $yn in
        [Yy]* ) ssh-keygen;  GENERATED=1; break;;
        [Nn]* ) break;;
        * ) echo "(y/n)";;
    esac
done

#Enable ssh root access
echo "Enable ssh root access..."

TARGET_KEY="PermitRootLogin"
REPLACEMENT_VALUE="yes"

if [ "$USER" != "root" ]; then

echo "Please specifiy RSA path (empty for /home/$USER/.ssh/id_rsa): "
TEMP=/home/$USER/.ssh/id_rsa

else

echo "Please specifiy RSA path (empty for /$USER/.ssh/id_rsa): "
TEMP=/$USER/.ssh/id_rsa

fi

read RSA_PATH

if [ "$RSA_PATH" = "" ]; then

RSA_PATH=$TEMP

fi 

if [ "$GENERATED" -eq 1 ]; then

ssh-add -D
ssh-add "$RSA_PATH"

fi

for i in ${NODE_LIST[@]}; do
	CONFIGURED=$(./send_root_cmd $i $OFELIA_USER $OFELIA_PASS $ROOT_PASS "cat /root/.ssh/authorized_keys" | grep $USER@$HOSTNAME | wc -l)
	if [ "$CONFIGURED" -eq 0 ] || [ "$GENERATED" -eq 1 ]; then
		# XXX We can have problem if the machine is configured with rsa.pub and it doesn't allow root login
		echo -e "\n$i not properly configured"
		./send_root_cmd $i $OFELIA_USER $OFELIA_PASS $ROOT_PASS "sed -i \"s/\($TARGET_KEY * *\).*/\1$REPLACEMENT_VALUE/\" /etc/ssh/sshd_config"
		./send_root_cmd $i $OFELIA_USER $OFELIA_PASS $ROOT_PASS "/etc/init.d/ssh restart"
		./send_root_cmd $i $OFELIA_USER $OFELIA_PASS $ROOT_PASS "sed -i -e '/$USER@$HOSTNAME/d' /root/.ssh/authorized_keys"
	 	./send_root_cmd $i $OFELIA_USER $OFELIA_PASS $ROOT_PASS "echo $(cat $RSA_PATH.pub) >> /root/.ssh/authorized_keys"
	else
		echo -e "\n$i properly configured"	
	fi
done
echo ""
echo "Configure DSH..."

#DSH configuration file
TARGET_KEY="remoteshell"
REPLACEMENT_VALUE="ssh"

sed -i "s/\($TARGET_KEY *= *\).*/\1$REPLACEMENT_VALUE/" /etc/dsh/dsh.conf

#Configures machines.list
echo "Configure machines.list..."


rm /etc/dsh/machines.list

for i in ${NODE_LIST[@]}; do
	echo $i
	echo $LOCAL_USER@$i >> /etc/dsh/machines.list
done

#Creates groups files in /etc/dsh/group
echo "Creating groups..."
for i in ${DSH_GROUPS[@]}; do
	echo > /etc/dsh/group/$i
	echo $i
	eval group=\${${i}[*]}
	for host in ${group[@]};do
		echo $LOCAL_USER@$host
		echo $LOCAL_USER@$host >> /etc/dsh/group/$i
	done	
done

}

WORK_DIR=/root/

#GITHUB
REPO_DIR=Dreamer-Setup-Scripts
REPO_URL=https://github.com/netgroup/Dreamer-Setup-Scripts

#XXX Operation with this repo could not work (bitbucket requests password)
#BITBUCKET
#REPO_DIR=dreamer-setup-scripts
#REPO_URL=https://pierventre@bitbucket.org/ssalsano/dreamer-setup-scripts.git

TESTBED_SH_ADDR="https://www.dropbox.com/s/smsyctn1qj72kpk/testbed.sh"
LMERULES_SH_ADDR="https://www.dropbox.com/s/vp30krz8vamjoxn/lmerules.sh"


clone_dreamer(){
#git clone on all hosts in NODE_LIST
dsh -M -g all -c rm -r -f $REPO_DIR
dsh -M -g all -c git clone $REPO_URL
}

update_dreamer(){
#git pull origin master on all hosts in NODE_LIST
dsh -M -g all -c "cd ./$REPO_DIR && git pull origin master"
}


for_all_group() {
# Executes $1 command on the deployed machines
for i in ${DSH_GROUPS[@]}; do
        if [ "$i" = "OSHI" ]; then
				echo $i
                dsh -M -g $i -c "cd ./$REPO_DIR/oshi/ && ./$1" 
        elif [ "$i" = "ROUTER" ];then
                echo $i
				dsh -M -g $i -c "cd ./$REPO_DIR/ip_router/ && ./$1"  
        elif [ "$i" = "EUH" ] || [ "$i" = "CTRL" ];then
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
# Change remote.cfg in accordance to $TESTBED_SH_ADDR and $LMERULES_SH_ADDR
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
				dsh -M -g $i -c "cd ./$REPO_DIR/oshi/ && sed -i \"s@\($TARGET_KEY *= *\).*@\1$REPLACEMENT_VALUE@\" ./remote.cfg  && sed -i \"s@\($TARGET_KEY2 *= *\).*@\1$REPLACEMENT_VALUE2@\" ./remote.cfg"
        elif [ "$i" = "ROUTER" ];then
                echo $i
				if ! [ -n "$TESTBED_SH_ADDR" ]; then
					echo "Addresses Not Setted For ROUTER"
					exit 1
				fi
				TARGET_KEY="DREAMERCONFIGSERVER"
				REPLACEMENT_VALUE="$TESTBED_SH_ADDR"
				dsh -M -g $i -c "cd ./$REPO_DIR/ip_router/ && sed -i \"s@\($TARGET_KEY *= *\).*@\1$REPLACEMENT_VALUE@\" ./remote.cfg"
        elif [ "$i" = "EUH" ] || [ "$i" = "CTRL" ];then
				echo $i
				if ! [ -n "$TESTBED_SH_ADDR" ]; then
					echo "Addresses Not Setted For EUH and CTRL"
					exit 1
				fi
				TARGET_KEY="DREAMERCONFIGSERVER"
				REPLACEMENT_VALUE="$TESTBED_SH_ADDR"
				dsh -M -g $i -c "cd ./$REPO_DIR/othernodes/ && sed -i \"s@\($TARGET_KEY *= *\).*@\1$REPLACEMENT_VALUE@\" ./remote.cfg"
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

update_cfg_nodes(){
#Update configuration files on all nodes
for_all_group update_cfg.sh
}

config(){
#Config all nodes 
for_all_group config.sh
}

clean(){
#Clean all nodes
for_all_group clean.sh
}

setup(){
#TODO:ripristinare
#clone_dreamer
setup_nodes
update_cfg_nodes
}

all(){
config_dsh
setup
config
}

USAGE="\n
# 	Usage : ./managment_config.sh <option>\n
#	update_mgmt_sh : update the configuration file management.sh\n
# 	config_dsh : enable root login, configure dsh machine.list and groups\n
#	clone_dreamer : download code from $REPO_URL\n
#   update_dreamer : update remote repo from $REPO_URL\n
#	setup_nodes : install software required and update configuration files on all nodes\n
#	setup : download code from $REPO_URL, install software required and update configuration files on all nodes\n
#	update_cfg_nodes : Update configuration files on all nodes\n
#	config : configure all nodes\n
#	clean : clean all nodes\n
#	all : complete setup and config\n
#	change_sh_addresses : update remote.cfg on the machines\n"

while getopts ":c: " opt; do
    case $opt in
            c) command=$OPTARG
			   shift;;      
			:) echo "Option -$OPTARG requires an argument."
			   echo -e $USAGE
      		   exit 1;;
    esac
	shift
done

if [ -z "$command" ]; then
		echo -e $USAGE
		exit 1
fi


if [ -f management.sh ];
	then
		# If cfg file is present in current folder, use it
		echo "---> File found in current folder. Using local configuration file management.sh"
		source management.sh
elif [ "$command" != "update_mgmt_sh" ];
	then
		echo "Error File Not Found..."
		exit -1
fi

$command
