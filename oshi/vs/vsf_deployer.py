#!/usr/bin/python

##############################################################################################
# Copyright (C) 2014 Pier Luigi Ventre - (Consortium GARR and University of Rome "Tor Vergata")
# Copyright (C) 2014 Giuseppe Siracusano, Stefano Salsano - (CNIT and University of Rome "Tor Vergata")
# www.garr.it - www.uniroma2.it/netgroup - www.cnit.it
#
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# VS deployer.
#
# @author Pier Luigi Ventre <pl.ventre@gmail.com>
# @author Giuseppe Siracusano <a_siracusano@tin.it>
# @author Stefano Salsano <stefano.salsano@uniroma2.it>
#
#

# This code has been taken from mininet's example bind.py, but we had to fix some stuff
# because some thing don't work properly (for example xterm)

# Utility function to read from configuration file the VLL to create

import os
import json
import sys

from mininet.node import Node
from mininet.log import lg, info, error

from net import MininetVS

deployer_cfg = {}
mgt_ip = ""
vsfs_deployed = []

def read_conf_file():

    global deployer_cfg

    info("*** Read Configuration File For VS deployer\n")
    path = "vsf.cfg"
    if os.path.exists(path):
            conf = open(path,'r')
            deployer_cfg = json.load(conf)
            conf.close()
    else:
        error("No Configuration File Find In %s\n" % path)
        exit(-2)

if __name__ == '__main__':
	lg.setLogLevel('info')
	read_conf_file()
	root = Node( 'root', inNamespace=False )	
	mgt_ip = (root.cmd("ip -4 addr show dev eth0 | grep -m 1 \"inet \" | awk '{print $2}' | cut -d \"/\" -f 1")[:-1])
	mgt_ip = mgt_ip.strip(' \t\n\r')
	vsfs = []
	for vsf in deployer_cfg["vsfs"]:
		vm = vsf['vm'].strip(' \t\n\r')
		if mgt_ip == vm:
			vsfs = vsf['vsfs']

	if len(vsfs) > 0:
		info("*** Create %s vsfs\n" % len(vsfs))
		net = MininetVS(deployer_cfg['tableIP'])
		i = 0
		for vsf in vsfs:
			vsfname = str(vsf['name'])
			info("*** Create %s\n" % vsfname)
			net.addVSF(vsfname)
			info("*** Create %s pws\n" %len(vsf['pws']))
			for pw in vsf['pws']:
				net.addPW(vsfname, pw)
			i = i + 1
		net.start()
	else:
		info("*** No VSF to deploy\n")
		
		





	
