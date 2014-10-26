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
# Implementation of fake Net.
#
# @author Pier Luigi Ventre <pl.ventre@gmail.com>
# @author Giuseppe Siracusano <a_siracusano@tin.it>
# @author Stefano Salsano <stefano.salsano@uniroma2.it>
#
#

import sys
import subprocess
import os
import signal
from collections import defaultdict

from mininet.net import Mininet
from mininet.node import Node
from mininet.log import lg, info, error
from mininet.term import cleanUpScreens, makeTerms

from nodes import OSHIroot, VSF

class MininetVS(Mininet):

	def __init__(self, tableIP, verbose=False):

		Mininet.__init__(self, build=False)
		self.tableIP = tableIP
		self.vsfs = []
		self.rootnodes = []
		self.verbose = verbose
		lg.setLogLevel('info')
		self.name_to_root_nodes = {}
		self.node_to_pw_data = defaultdict(list)

	def addVSF(self, name):
		vsf = Mininet.addHost(self, name, cls=VSF)
		rname = "r%s" %name
		root = OSHIroot(rname)
		self.vsfs.append(vsf)
		self.rootnodes.append(root)
		self.name_to_root_nodes[rname] = root

	def addPW(self, vsf, pw_data):
		vsf = self.getNodeByName(vsf)
		rname = "r%s" % vsf.name
		oshi = self.name_to_root_nodes[rname]

		pwtap = pw_data['cer_intf']
		local_ip = pw_data['local_vtep']['ip']
		local_mac = pw_data['local_vtep']['mac']
		remote_ip = pw_data['remote_vtep']['ip']
		remote_mac = pw_data['remote_vtep']['mac']

		vsflink1 = Mininet.addLink(self, oshi, vsf)
		vsflink2 = Mininet.addLink(self, oshi, vsf)
		oshi_data = {'cer_intf':pwtap, 'vsf_intf1':vsflink1.intf1.name, 'vsf_intf2':vsflink2.intf1.name}
		self.node_to_pw_data[oshi.name].append(oshi_data)

		vsf_data = { 'eth': vsflink1.intf2.name, 'remoteip': remote_ip, 'remotemac': remote_mac, 'v_eth':vsflink2.intf2.name}
		vsflink2.intf2.setIP(local_ip)
		vsflink2.intf2.setMAC(local_mac)
		self.node_to_pw_data[vsf.name].append(vsf_data)

	def configHosts( self ):
		"Configure a set of hosts."

		for host in self.hosts:
			info( host.name + ' ' )
			host.cmd( 'ifconfig lo up' )
		info( '\n' )

	def start(self):

		info( '*** Starting %s vsfs\n' % len(self.vsfs) )
		for vsf in self.vsfs:
			vsf.start(self.node_to_pw_data[vsf.name])		
		info( '\n' )

		info( '*** Starting %s rootnodes\n' % len(self.rootnodes) )
		for rootnode in self.rootnodes:
			rootnode.start(self.tableIP, self.node_to_pw_data[rootnode.name])		
		info( '\n' )

		#if 'DISPLAY' not in os.environ:
		#	error( "Error starting terms: Cannot connect to display\n" )
		#	return
		#info( "*** Running ctrls terms on %s\n" % os.environ[ 'DISPLAY' ] )
		#cleanUpScreens()
		#self.terms += makeTerms( self.vsfs, 'vsf' )
