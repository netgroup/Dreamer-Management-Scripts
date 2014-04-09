#!/bin/bash
# The script cleans and configures a DREAMER node

echo -e "\n"
echo "############################################################"
echo "##  			DREAMER node clean and config process  		##"
echo "## The installation and configuration processes can last  ##"
echo "## many minutes. Plase, wait and do not interrupt	 		##"
echo "## the process.                   				 	    ##"
echo "############################################################"

echo "The script will automatically clear and re-configure the DREAMER node."
echo "If you DO NOT have filled in the testbed file, please exit now with CTRL + C. Otherwise, if"
echo "you are ready, press ENTER to continue."

read

bash clean.sh &&
bash config.sh &&

EXIT_SUCCESS=0
exit $EXIT_SUCCESS