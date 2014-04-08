#!/bin/bash
# The script setups a group of specified DREAMER nodes (non-OSHI nodes)

echo -e "\n"
echo "############################################################"
echo "##             DREAMER nodes distributed setup            ##"
echo "##                                                        ##"
echo "## The installation process can last many minutes.        ##"
echo "## Plase wait and do not interrupt the setup process.     ##"
echo "############################################################"

if [ $USER != "root" ]
  then
    echo -e "\nLog in as user root before executing the script.\n"
        exit
fi

if [[ -z "$1" ]]; then
        echo -e "\nERROR: DSH group file name needed as first parameter."
        exit
fi

declare -a HOSTS
declare -a USERS
counter=1
endofcounter=$(($(cat /etc/dsh/group/$1 | wc -l) + 1))
while [ $counter -lt $endofcounter ]; do
        arraycounter=$(($counter-1))
        USERS[$arraycounter]=$(cat /etc/dsh/group/$1 | sed -n "$counter p" | awk '{split($0,a,"@"); print a[1]}')
        HOSTS[$arraycounter]=$(cat /etc/dsh/group/$1 | sed -n "$counter p" | awk '{split($0,a,"@"); print a[2]}')
        let counter=counter+1
done

for (( i=0; i<${#HOSTS[@]}; i++ )); do
        scp dreamernodes.tar.gz ${USERS[$i]}@${HOSTS[$i]}:/ofelia/users/${USERS[$i]}/
done

dsh -M -g $1 -c "sudo tar -xvzf /ofelia/users/${USERS[0]}/dreamernodes.tar.gz && sudo bash /ofelia/users/${USERS[0]}/dreamernodes/setup.sh"

echo -e "\nDREAMER nodes installed successfully.\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS