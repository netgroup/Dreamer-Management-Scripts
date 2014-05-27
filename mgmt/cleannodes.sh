#!/bin/bash
# The resets to the default state a group of DREAMER nodes

echo -e "\n"
echo "############################################################"
echo "##          	DREAMER node distributed cleaning        	##"
echo "##                                                        ##"
echo "## The cleaning process can last many minutes.       		##"
echo "## Plase wait and do not interrupt the cleaning process.  ##"
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
		dsh -M -a -c "bash /etc/dreamer/clean.sh"
	else
		dsh -M -g $1 -c "bash /etc/dreamer/clean.sh"
fi

echo -e "\nDREAMER nodes cleaned successfully.\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS