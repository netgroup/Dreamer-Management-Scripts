#!/bin/bash
# The script cleans and configure a DREAMER IP/SDN hybrid node (OSHI) 

echo -e "\n"
echo "############################################################"
echo "##     DREAMER IP/SDN Hyibrid reconfiguration process     ##"
echo "##                                                        ##"
echo "## The installation can last many minutes. Plase wait and ##"
echo "## do not interrupt the setup process.                    ##"
echo "############################################################"

echo "The script will automatically clear and re-configure the DREAMER IP/SDN Hybrid node (OSHI)."
echo "If you DO NOT have filled in the testbed file, please exit now with CTRL + C. Otherwise, if"
echo "you are ready, press ENTER to continue."

read

bash clean.sh &&
bash config.sh &&

EXIT_SUCCESS=0
exit $EXIT_SUCCESS