#!/bin/bash
# The script remove the testbed.sh configuration file from all or a group of specified DREAMER nodes.

echo -e "\n"
echo "############################################################"
echo "##          DREAMER node distributed configuration        ##"
echo "##                                                        ##"
echo "## The configuration process can last many minutes.       ##"
echo "## Plase wait and do not interrupt the configprocess.     ##"
echo "############################################################"

if [ $USER != "root" ]
  then
    echo -e "\nLog in as user root before executing the script.\n"
        exit
fi

if [[ -z "$1" ]];
	then
        echo -e "\nWARNING: Without specifying as first parameter a DSH group the change will be applied to all host. Are you sure you want to continue? If you want to exit now, please press CTRL + C. Otherwise, if you are ready, press ENTER to continue."
        read
		dsh -M -a -c "sudo rm -f testbed.sh 2> /dev/null && sudo rm /etc/dreamer/testbed.sh"
	else
		dsh -M -g $1 -c "sudo rm -f testbed.sh 2> /dev/null && sudo rm /etc/dreamer/testbed.sh"
fi

echo -e "\nDREAMER testbed.sh file correctly deleted from dir /etc/dreamer.\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS