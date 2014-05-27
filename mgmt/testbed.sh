#!/bin/bash
############################################################
##            		DREAMER node parameters           	  ##
##                                                        ##
##   Parameters to be set by the user for config process  ##
##                                                        ##
############################################################
# HowTO
#
# In this file a user can add the configuration of the all DREAMER nodes.
# Each node configuration is delimited by a start string (# MGMTADDRESS_OF_NODE - start) and by an end string (# MGMTADDRESS_OF_NODE - end)
# Please, follow the instructions below to write correct configurations for your nodes.
#
# PLEASE, DO NOT USE WHITE SPACES
#
######### ISTRUCTIONS (ONLY FOR OSHI NODES) #################################################################
#
# MGMTNET - mgmt testbed network, netmask, gateway, management interface
# OFELIA default: 10.216.0.0 255.255.0.0 10.216.32.1 eth0
#
# HOST - machine and router hostname - i.e. oshi
#
# ROUTERPWD - Machine password and quagga router password - i.e. dreamer
#
# DPID - 16Hex digids to specify the OVS DPID - i.e. 0000000000000001
#
# SLICEVLAN - testbed slice VLAN - i.e. 200
#
# BRIDGENAME - OVS bridge name - i.e. br-dreamer
#
# CTRL - Specify a list of OpenFlow controllers - i.e. declare -a CTRL=(CTRL1 CTRL2 CTRL3)
#
# CTRLX - Parameters to reach the OpenFlow controller
# First parameter -> OpenFlow controller IP address
# Second parameter -> OpenFlow controller TCP port
# i.e. CTRL=(192.168.0.100 6633)
#
# LOOPBACK - Loopback interface address and subnet, ospf cost, ospf helo interval - i.e. LOOPBACK=(192.168.100.1/32 1 1)
#
# INTERFACES - List of physical interface to be used by the oshi node - Do not specify eth0 (the mngmt interface)
# i.e. INTERFACES=(eth1 eth2 eth3 eth4)
#
# ethX - IP address and netmask to be assigned to each interface specified above into INTERFACES
# i.e. eth1=(192.168.1.1/24)
#
# TAP - List of tap interfaces used to create point-to-point tunnels between end-hosts
# i.e. TAP=(tap1 tap2 tap3 tap4)
#
# tapX - tap interface details. Local tap port, remote tap port, name of variable indicating the ip address to reach and the interface to use (see endipX below)
# i.e. tapX=(1191 1194 endip1)
#
# endipX - express the ip address to connect to with a specific tap interface and the local ethernet interface to use to make the connection
# i.e. endipX=(192.168.0.1 eth1)
#
# Quagga interfaces - Define quagga virtual interfaces, used for the connection with OVS. They must be the same number of tap interfaces.
# i.e. QUAGGAINT=(vi1 vi2 vi3 vi4)
#
# viX - For each interface specify ip address/netmask, ospf cost and the helo interval
# i.e. vi1=(10.0.0.1/24 15 2)
#
# OSPFNET - List of OSPF networks to be announced (specified below) - i.e. OSPFNET=(NET1 NET2 NET3 NET4)
#
# NETX - Details of networks (named and listed above) to be anounced. Specify the network to be announced, the netmask and the OSPF area
# i.e. declare -a net1 - net1=(192.168.0.0/24 0.0.0.0)
#
######### ISTRUCTIONS (FOR ALL OTHER DREAMER NODES) #################################################################
#
# HOST - machine and router hostname - i.e. oshi
#
# SLICEVLAN - testbed slice VLAN - i.e. 200
#
# INTERFACES - List of physical interface to be used by the oshi node - Do not specify eth0 (the mngmt interface)
# i.e. INTERFACES=(eth1 eth2 eth3 eth4)
#
# ethX - IP address and netmask to be assigned to each interface specified above into INTERFACES
# i.e. eth1=(192.168.1.1/24)
#
# TAP - List of tap interfaces used to create point-to-point tunnels between end-hosts
# i.e. TAP=(tap1)
#
# tapX - tap interface details. Local tap port, remote tap port, tap interface IP address,
# name of variable indicating the ip address to reach and the interface to use (see endipX below)
# i.e. declare -a tapX=(1191 1191 10.0.10.2/24 ENDIP1)
#
# STATICROUTE Overlay network address and subnet and both the overlay network default gateway and the interface card (usually tap1) to reach
# other overlay nets - i.e. declare -a STATICROUTE=(10.0.0.0 255.0.0.0 10.0.10.1 tap1)
#
# endipX - express the ip address to connect to with a specific tap interface and the local ethernet interface to use to make the connection
# i.e. endipX=(192.168.0.1 eth1)
#
######### ISTRUCTIONS END ###########################################################################################
# 10.216.33.133 - start
HOST=OSHI01
ROUTERPWD=dreamer
DPID=0000000000000001
SLICEVLAN=107
BRIDGENAME=br-dreamer
declare -a MGMTNET=(10.216.0.0 255.255.0.0 10.216.32.1 eth0)
declare -a CTRL=(CTRL1)
declare -a CTRL1=(10.0.10.2 6633)
declare -a LOOPBACK=(10.0.100.1/32 1 1)
declare -a INTERFACES=(eth1)
declare -a eth1=(192.168.1.11 255.255.0.0)
declare -a TAP=(tap1 tap2 tap3)
declare -a tap1=(1191 1191 ENDIP1)
declare -a tap2=(1192 1191 ENDIP2)
declare -a tap3=(1193 1193 ENDIP3)
declare -a ENDIP1=(192.168.1.21 eth1)
declare -a ENDIP2=(192.168.2.31 eth1)
declare -a ENDIP3=(192.168.1.31 eth1)
declare -a QUAGGAINT=(vi1 vi2 vi3)
declare -a vi1=(10.0.1.1/30 15 2)
declare -a vi2=(10.0.3.1/30 15 2)
declare -a vi3=(10.0.10.1/30 15 2)
declare -a OSPFNET=(NET1 NET2 NET3 NET4)
declare -a NET1=(10.0.1.0/30 0.0.0.0)
declare -a NET2=(10.0.3.0/30 0.0.0.0)
declare -a NET3=(10.0.10.0/30 0.0.0.0)
declare -a NET4=(10.0.100.1/32 0.0.0.0)
# 10.216.33.133 - end
# 10.216.33.134 - start
HOST=OSHI02
ROUTERPWD=dreamer
DPID=0000000000000002
SLICEVLAN=107
BRIDGENAME=br-dreamer
declare -a MGMTNET=(10.216.0.0 255.255.0.0 10.216.32.1 eth0)
declare -a CTRL=(CTRL1)
declare -a CTRL1=(10.0.10.2 6633)
declare -a LOOPBACK=(10.0.100.2/32 1 1)
declare -a INTERFACES=(eth1)
declare -a eth1=(192.168.1.21 255.255.0.0)
declare -a TAP=(tap1 tap2 tap3)
declare -a tap1=(1191 1191 ENDIP1)
declare -a tap2=(1192 1192 ENDIP2)
declare -a tap3=(1193 1191 ENDIP3)
declare -a ENDIP1=(192.168.1.11 eth1)
declare -a ENDIP2=(192.168.2.31 eth1)
declare -a ENDIP3=(192.168.2.21 eth1)
declare -a QUAGGAINT=(vi1 vi2 vi3)
declare -a vi1=(10.0.1.2/30 15 2)
declare -a vi2=(10.0.2.1/30 15 2)
declare -a vi3=(10.0.20.1/24 15 2)
declare -a OSPFNET=(NET1 NET2 NET3 NET4)
declare -a NET1=(10.0.1.0/30 0.0.0.0)
declare -a NET2=(10.0.2.0/30 0.0.0.0)
declare -a NET3=(10.0.20.0/24 0.0.0.0)
declare -a NET4=(10.0.100.2/32 0.0.0.0)
# 10.216.33.134 - end
# 10.216.33.90 - start
HOST=OSHI03
ROUTERPWD=dreamer
DPID=0000000000000003
SLICEVLAN=107
BRIDGENAME=br-dreamer
declare -a MGMTNET=(10.216.0.0 255.255.0.0 10.216.32.1 eth0)
declare -a CTRL=(CTRL1)
declare -a CTRL1=(10.0.10.2 6633)
declare -a LOOPBACK=(10.0.100.3/32 1 1)
declare -a INTERFACES=(eth1)
declare -a eth1=(192.168.2.31 255.255.0.0)
declare -a TAP=(tap1 tap2 tap3)
declare -a tap1=(1191 1192 ENDIP1)
declare -a tap2=(1192 1191 ENDIP2)
declare -a tap3=(1193 1191 ENDIP3)
declare -a ENDIP1=(192.168.1.11 eth1)
declare -a ENDIP2=(192.168.2.21 eth1)
declare -a ENDIP3=(192.168.2.11 eth1)
declare -a QUAGGAINT=(vi1 vi2 vi3)
declare -a vi1=(10.0.3.2/30 15 2)
declare -a vi2=(10.0.2.2/30 15 2)
declare -a vi3=(10.0.30.1/24 15 2)
declare -a OSPFNET=(NET1 NET2 NET3 NET4)
declare -a NET1=(10.0.3.0/30 0.0.0.0)
declare -a NET2=(10.0.2.0/30 0.0.0.0)
declare -a NET3=(10.0.30.0/24 0.0.0.0)
declare -a NET4=(10.0.100.3/32 0.0.0.0)
# 10.216.33.90 - end
# 10.216.33.142 - start
HOST=dreamerofctrl
SLICEVLAN=107
declare -a MGMTNET=(10.216.0.0 255.255.0.0 10.216.32.1 eth0)
declare -a INTERFACES=(eth1)
declare -a eth1=(192.168.1.31 255.255.0.0)
declare -a TAP=(tap1)
declare -a tap1=(1193 1192 10.0.10.2/24 ENDIP1)
declare -a STATICROUTE=(10.0.0.0 255.0.0.0 10.0.10.1 tap1)
declare -a ENDIP1=(192.168.1.11 eth1)
# 10.216.33.142 - end
# 10.216.33.79 - start
HOST=endusernode01
SLICEVLAN=107
declare -a MGMTNET=(10.216.0.0 255.255.0.0 10.216.32.1 eth0)
declare -a INTERFACES=(eth1)
declare -a eth1=(192.168.2.11 255.255.0.0)
declare -a TAP=(tap1)
declare -a tap1=(1191 1193 10.0.30.2/24 ENDIP1)
declare -a STATICROUTE=(10.0.0.0 255.0.0.0 10.0.30.1 tap1)
declare -a ENDIP1=(192.168.2.31 eth1)
# 10.216.33.79 - end
# 10.216.33.80 - start
HOST=endusernode02
SLICEVLAN=107
declare -a MGMTNET=(10.216.0.0 255.255.0.0 10.216.32.1 eth0)
declare -a INTERFACES=(eth1)
declare -a eth1=(192.168.2.21 255.255.0.0)
declare -a TAP=(tap1)
declare -a tap1=(1191 1193 10.0.20.2/24 ENDIP1)
declare -a STATICROUTE=(10.0.0.0 255.0.0.0 10.0.20.1 tap1)
declare -a ENDIP1=(192.168.1.21 eth1)
# 10.216.33.80 - end