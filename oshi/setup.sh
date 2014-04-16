#!/bin/bash
# The script installs OSHI packages on Linux Debian

echo -e "\n"
echo "############################################################"
echo "##            DREAMER IP/SDN Hyibrid node setup           ##"
echo "##                                                        ##"
echo "## The installation process can last many minutes.        ##"
echo "## Plase wait and do not interrupt the setup process.     ##"
echo "############################################################"

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

echo -e "\n-Installing VIM"
apt-get install -y vim &&

echo -e "\n-Installing python-simplejson"
apt-get install -y python-simplejson &&

echo -e "\n-Installing Python-QT4"
apt-get install -y python-qt4 &&

echo -e "\n-Installing Python Zope Interface"
apt-get install -y python-zopeinterface &&

echo -e "\n-Installing Python-Twisted-Conch"
apt-get install -y python-twisted-conch &&

echo -e "\n-Installing pkg-config"
apt-get install -y pkg-config &&

echo -e "\n-Installing dh-autoreconf"
apt-get install -y dh-autoreconf &&

echo -e "\n-Installing ipcalc"
apt-get install -y ipcalc &&

echo -e "\n-Installing Linux Headers for Linux kernel `uname -r`"
apt-get install -y linux-headers-`uname -r` &&

echo -e "\n-Installing OpenVPN"
apt-get install -y openvpn &&

echo -e "\n-Installing VLAN packages"
apt-get install -y vlan &&

echo -e "\n-Installing Quagga router services"
apt-get install -y quagga

echo -e "-VLAN module setup"
modprobe 8021q &&
# Make 801q module loading permanent
if [ $(cat /etc/modules | grep 8021q | wc -l) -eq 0 ]
	then
		echo "8021q" >> /etc/modules
fi

echo -e "\n-Installing OpenVSwitch"
# Creating folder for OVS under /opt/ovs
mkdir -p /opt/ovs &&
# Downloading
wget -P/opt/ovs http://openvswitch.org/releases/openvswitch-1.10.0.tar.gz &&
# Extracting
tar -xvzf /opt/ovs/openvswitch-1.10.0.tar.gz -C /opt/ovs &&
cd  /opt/ovs/openvswitch-1.10.0/ &&
# Boot up and configuring sources
./boot.sh &&
./configure --with-linux=/lib/modules/`uname -r`/build &&
# Make
make &&
make install &&
# OVS module installation
make modules_install &&
mkdir -p /lib/modules/`uname -r`/kernel/openvswitch
cp /opt/ovs/openvswitch-1.10.0/datapath/linux/openvswitch.ko /lib/modules/`uname -r`/kernel/openvswitch/openvswitch.ko
depmod -a &&
# Making module loading permanent
modprobe openvswitch &&
if [ $(cat /etc/modules | grep openvswitch | wc -l) -eq 0 ]
	then
		echo "openvswitch" >> /etc/modules
fi
# Create and initialize the database
mkdir -p /usr/local/etc/openvswitch &&
ovsdb-tool create /usr/local/etc/openvswitch/conf.db /opt/ovs/openvswitch-1.10.0/vswitchd/vswitch.ovsschema &&
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
                     --remote=db:Open_vSwitch,manager_options \
                     --private-key=db:SSL,private_key \
                     --certificate=db:SSL,certificate \
                     --bootstrap-ca-cert=db:SSL,ca_cert \
                     --pidfile --detach &&
ovs-vsctl --no-wait init &&
# Starting OVS
echo -e "\n-Starting OpenVSwitch"
ovs-vswitchd --pidfile --detach &&
# Adding OVS as a service
echo -e "\n-Adding OpenVSwitch service"
echo -e '#!/bin/bash
#
# start/stop openvswitch
### BEGIN INIT INFO
# Provides: openvswitchd
# Required-start: $remote_fs $syslog
# Required-stop: $remote_fs $syslog
# Default-start: 2 3 4 5
# Default-stop: 0 1 6
# Short-description: OpenVSwitch daemon
# chkconfig: 2345 9 99
# description: Activates/Deactivates all Open vSwitch to start at boot time.
# processname: openvswitchd
# config: /usr/local/etc/openvswitch/conf.db
# pidfile: /usr/local/var/run/openvswitch/ovs-vswitchd.pid
### END INIT INFO\n

PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin
export PATH\n

# Source function library. . /etc/rc.d/init.d/functions
. /lib/lsb/init-functions\n

stop()
{
echo "
Stopping openvswitch..."\n

if [ -e /usr/local/var/run/openvswitch/ovs-vswitchd.pid ]; then
pid=$(cat /usr/local/var/run/openvswitch/ovs-vswitchd.pid)
/usr/local/bin/ovs-appctl -t /usr/local/var/run/openvswitch/ovs-vswitchd.$pid.ctl exit
rm -f /usr/local/var/run/openvswitch/ovs-vswitchd.$pid.ctl
fi\n

if [ -e /usr/local/var/run/openvswitch/ovsdb-server.pid ]; then
pid=$(cat /usr/local/var/run/openvswitch/ovsdb-server.pid)
/usr/local/bin/ovs-appctl -t /usr/local/var/run/openvswitch/ovsdb-server.$pid.ctl exit
rm -f /usr/local/var/run/openvswitch/ovsdb-server.$pid.ctl
fi\n

rm -f /var/lock/subsys/openvswitchd
echo "OK"
}\n

start()
{
echo "
Starting openvswitch..."
/usr/local/sbin/ovsdb-server /usr/local/etc/openvswitch/conf.db \
--remote=punix:/usr/local/var/run/openvswitch/db.sock \
--remote=db:Open_vSwitch,manager_options \
--private-key=db:SSL,private_key \
--certificate=db:SSL,certificate \
--bootstrap-ca-cert=db:SSL,ca_cert \
--pidfile --detach\n

/usr/local/bin/ovs-vsctl --no-wait init
/usr/local/sbin/ovs-vswitchd unix:/usr/local/var/run/openvswitch/db.sock --pidfile --detach\n

mkdir -p /var/lock/subsys
touch /var/lock/subsys/openvswitchd
echo "
OpenVSwitch started succesfully!"
}\n

# See how we were called.
case $1 in
start)
start
;;
stop)
stop
;;
restart)
stop
start
;;
status)
status ovs-vswitchd
;;
*)
echo "Usage: openvswitchd {start|stop|status|restart}."
exit 1
;;
esac\n
exit 0' > /etc/init.d/openvswitchd &&
chmod +x /etc/init.d/openvswitchd &&
update-rc.d openvswitchd defaults &&

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
# Copying reconfig-device.sh file if present
if [ -f $DIR/reconfig-device.sh ];
	then
		echo -e "\n---> Copying reconfig-device.sh to /etc/dreamer"
		cp $DIR/reconfig-device.sh /etc/dreamer/reconfig-device.sh
	else
		echo -e "\n---> WARNING: reconfig-device.sh file is not present. We suggest to copy the original file manually to /etc/dreamer"
fi

echo -e "\n\nDREAMER IP/SDN hybrid node (OSHI) setup ended succesfully. Enjoy!\n"

EXIT_SUCCESS=0
exit $EXIT_SUCCESS