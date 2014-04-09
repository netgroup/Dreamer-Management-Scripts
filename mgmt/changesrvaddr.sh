#!/bin/bash
# The script change the update server configuration address included in the remote.cfg file from all or a specified group of DREAMERR nodes.

echo -e "\n"
echo "############################################################"
echo "##      DREAMER configuration server address update       ##"
echo "##                                                        ##"
echo "## The configuration process can last many minutes.       ##"
echo "## Plase wait and do not interrupt the setup process.     ##"
echo "############################################################"

if [ $USER != "root" ]
  then
    echo -e "\nLog in as user root before executing the script.\n"
        exit
fi

if [[ -z "$1" ]];
	then
		echo -e "\nERROR: Please, specify as first parameter a valid testbed.sh HTTP address (i.e. DropBox public folder)"
		exit
fi

if [[ -z "$2" ]];
	then
        echo -e "\nWARNING: Without specifying as first parameter a DSH group the change will be applied to all host. Are you sure you want to continue? If you want to exit now, please press CTRL + C. Otherwise, if you are ready, press ENTER to continue."
        read
		dsh -M -a -c "sudo bash -c \"echo \# DREAMERCONFIGSERVER parameter is used to fetch the dreamer update server. Put your testbed.sh file there, delete local configuration files, run clean and config utils\
\# i.e. DREAMERCONFIGSERVER\=http\:\/\/www\.yourserver\.com\/testbed\.sh > /etc/dreamer/remote.cfg\""
		dsh -M -a -c "sudo bash -c \"echo DREAMERCONFIGSERVER=$1 >> /etc/dreamer/remote.cfg\""
	else
		dsh -M -g $2 -c "sudo bash -c \"echo \# DREAMERCONFIGSERVER parameter is used to fetch the dreamer update server. Put your testbed.sh file there, delete local configuration files, run clean and config utils\
\# i.e. DREAMERCONFIGSERVER\=http\:\/\/www\.yourserver\.com\/testbed\.sh > /etc/dreamer/remote.cfg\""
		dsh -M -g $2 -c "sudo bash -c \"echo DREAMERCONFIGSERVER=$1 >> /etc/dreamer/remote.cfg\""
fi

echo -e "\nDREAMER nodes update server address changed successfully in remote.cfg files.\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS