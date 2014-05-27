#!/bin/bash
# The script installs DREAMER node packages on Linux Debian

echo -e "\n"
echo "############################################################"
echo "##            	  DREAMER node setup           			##"
echo "##                                                        ##"
echo "## The installation process can last many minutes.        ##"
echo "## Plase wait and do not interrupt the setup process.     ##"
echo "############################################################"

echo -e "\n"
if [ $(uname -r) == "3.2.0-4-amd64" ]
	then
echo -e "\n-Changing /etc/apt/source.list to Debian wheezy, kernel 3.2.0"
echo "#
#  /etc/apt/sources.list
#


#
# squeeze
#
deb 	http://ftp.uk.debian.org/debian stable main contrib non-free
deb-src http://ftp.uk.debian.org/debian stable main contrib non-free

#
#  Security updates
#
deb http://security.debian.org/ wheezy/updates main contrib non-free
deb-src http://security.debian.org/ wheezy/updates main contrib non-free" > /etc/apt/sources.list
fi

echo -e "\n-Executing apt-get update"
apt-get update &&

echo -e "\n\nDOWNLOADING PREREQUISITES"

echo -e "\n-Installing ipcalc"
apt-get install -y ipcalc &&

echo -e "\n-Installing VIM"
apt-get install -y vim &&

echo -e "\n-Installing OpenVPN"
apt-get install -y openvpn &&

echo -e "\n-Installing VLAN packages"
apt-get install -y vlan &&

echo -e "-VLAN module setup"
modprobe 8021q &&
# Make 801q module loading permanent
if [ $(cat /etc/modules | grep 8021q | wc -l) -eq 0 ]
	then
		echo "8021q" >> /etc/modules
fi

# Creating folder /etc/dreamer if it doesn't exist
echo -e "\n-Creating /etc/dreamer folder"
mkdir -p /etc/dreamer

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "\n-Copying utilities and configuration files to /etc/dreamer"
# Copying testbed.sh configuration file in /etc/dreamer - if present
if [ -f $DIR/testbed.sh ];
	then
		echo -e "\n---> Copying testbed.sh configuration file into /etc/dreamer"
		cp $DIR/testbed.sh /etc/dreamer/testbed.sh
	else
		echo -e "\n---> WARNING: testbed.sh file is not present. We suggest to copy the original file manually to /etc/dreamer"
fi
# Copying testbed.sh configuration file in /etc/dreamer - if present
if [ -f $DIR/remote.cfg ];
	then
		echo -e "\n---> Copying remote.cfg configuration file into /etc/dreamer"
		cp $DIR/remote.cfg /etc/dreamer/remote.cfg
	else
		echo -e "\n---> WARNING: remote.cfg not found. Creating new /etc/dreamer/remote.cfg file."
		echo -e "# DREAMERCONFIGSERVER parameter is used to fetch the dreamer update server. Put your testbed.sh file there, delete local configuration files, run clean and config utils
# i.e. DREAMERCONFIGSERVER=http://www.yourserver.com/testbed.sh\n
DREAMERCONFIGSERVER=" > /etc/dreamer/remote.cfg
fi
# Copying clean.sh file if present
if [ -f $DIR/clean.sh ];
	then
		echo -e "\n---> Copying clean.sh to /etc/dreamer"
		cp $DIR/clean.sh /etc/dreamer/clean.sh
	else
		echo -e "\n---> WARNING: clean.sh file is not present. We suggest to copy the original file manually to /etc/dreamer"
fi
# Copying config.sh file if present
if [ -f $DIR/config.sh ];
	then
		echo -e "\n---> Copying config.sh to /etc/dreamer"
		cp $DIR/config.sh /etc/dreamer/config.sh
	else
		echo -e "\n---> WARNING: config.sh file is not present. We suggest to copy the original file manually to /etc/dreamer"
fi
# Copying clean-config.sh file if present
if [ -f $DIR/clean-config.sh ];
	then
		echo -e "\n---> Copying clean-config.sh to /etc/dreamer"
		cp $DIR/clean-config.sh /etc/dreamer/clean-config.sh
	else
		echo -e "\n---> WARNING: clean-config.sh file is not present. We suggest to copy the original file manually to /etc/dreamer"
fi

echo -e "\n\nDREAMER node setup ended succesfully. Enjoy!\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS