#!/bin/bash
# The script conigures a group of specified DREAMER nodes

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
                dsh -M -a -c "rm -f testbed.sh 2> /dev/null && bash /etc/dreamer/config.sh"
        else
                dsh -M -g $1 -c "rm -f testbed.sh 2> /dev/null && bash /etc/dreamer/config.sh"
fi

echo -e "\nDREAMER nodes configured successfully.\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS