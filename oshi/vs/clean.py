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
# Asynchronous clean.
#
# @author Pier Luigi Ventre <pl.ventre@gmail.com>
# @author Giuseppe Siracusano <a_siracusano@tin.it>
# @author Stefano Salsano <stefano.salsano@uniroma2.it>
#
#

import subprocess


from mininet.node import Node
from mininet.log import lg, info

from nodes import OSHIroot, VSF
from utility import unmountAll

if __name__ == '__main__':

		lg.setLogLevel('info')

		info("*** Clean environment\n")
		subprocess.call(["sudo", "mn", "-c"], stdout=None, stderr=None)
		
		root = Node( 'root', inNamespace=False )
		
		info("*** Kill all processes started\n")
		root.cmd('killall ovsdb-server')
		root.cmd('killall ovs-vswitchd')

		info("*** Open vSwitch\n")	
		root.cmd('/etc/init.d/openvswitchd start')

		info('*** Unmounting host bind mounts\n')
		unmountAll()	
