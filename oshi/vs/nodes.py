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
# Implementation of Nodes.
#
# @author Pier Luigi Ventre <pl.ventre@gmail.com>
# @author Giuseppe Siracusano <a_siracusano@tin.it>
# @author Stefano Salsano <stefano.salsano@uniroma2.it>
#
#

# This code has been taken from mininet's example bind.py, but we had to fix some stuff
# because some thing don't work properly (for example xterm)

import shutil
import os
import re
import sys
from subprocess import Popen,PIPE

from mininet.node import Host, Node, HostWithPrivateDirs
from mininet.log import info, error

class VSF(HostWithPrivateDirs):

	ovs_initd = "/etc/init.d/openvswitchd"
	baseDIR = "/tmp"
	
	def __init__(self, name, *args, **kwargs ):
		dirs = ['/var/log/', '/var/run', '/var/run/openvswitch']
		HostWithPrivateDirs.__init__(self, name, privateDirs=dirs, *args, **kwargs )
		self.path_ovs = "%s/%s/ovs" %(self.baseDIR, self.name)
	
		
	def start( self, pws_data=[]):
		info("%s " % self.name)

		if len(pws_data) == 0:
			error("ERROR PW configuration is not possibile for %s\n" % self.name)
			exit(-2)

		self.initial_configuration()
		self.configure_ovs(pws_data)

	def initial_configuration(self):
		
		shutil.rmtree("%s/%s" %(self.baseDIR, self.name), ignore_errors=True)
		os.mkdir("%s/%s" %(self.baseDIR, self.name))

		os.mkdir(self.path_ovs)
		self.cmd("ovsdb-tool create %s/conf.db" % self.path_ovs)
		self.cmd("ovsdb-server %s/conf.db --remote=punix:%s/db.sock --remote=db:Open_vSwitch,Open_vSwitch,manager_options --no-chdir --unixctl=%s/ovsdb-server.sock --detach" %(self.path_ovs, self.path_ovs, self.path_ovs))
		self.cmd("ovs-vsctl --db=unix:%s/db.sock --no-wait init" % self.path_ovs)
		self.cmd("ovs-vswitchd unix:%s/db.sock -vinfo --log-file=%s/ovs-vswitchd.log --no-chdir --detach" %(self.path_ovs, self.path_ovs))
		self.cmd("ovs-vsctl --db=unix:%s/db.sock --no-wait add-br %s" %(self.path_ovs, self.name))
	
	def configure_ovs(self, pws_data):

		rules = []
		
		for pw in pws_data:
		
			eth = pw['eth']
			remoteip = pw['remoteip']
			v_eth = pw['v_eth']	
			temp = 	remoteip.split('/')
			remoteip = temp[0]
			remotemac = pw['remotemac']
			gre = "gre%s" %(self.strip_number(eth))
			
			self.cmd("ifconfig %s 0" % eth)
			self.cmd( 'arp', '-s', remoteip, remotemac, '-i', v_eth)
			self.cmd( 'ip', 'r', 'a', remoteip, 'dev', v_eth)
			self.cmd("ovs-vsctl --db=unix:%s/db.sock --no-wait add-port %s %s" %(self.path_ovs, self.name, eth))
			self.cmd("ovs-vsctl --db=unix:%s/db.sock --no-wait add-port %s %s -- set Interface %s type=gre options:remote_ip=%s" %(self.path_ovs, 
			self.name, gre, gre, remoteip))
			
			rules.append('ovs-ofctl add-flow %s "table=0,hard_timeout=0,priority=%s,in_port=%s,action=output:%s"'%(self.name, 32768, eth, 
			gre))
			rules.append('ovs-ofctl add-flow %s "table=0,hard_timeout=0,priority=%s,in_port=%s,action=output:%s"'%(self.name, 32768, gre, 
			eth))			

		for rule in rules:
			rule = self.translate_rule(rule)
			self.cmd(rule)

	def get_if_index(self, in_if_name):
		output = self.cmd('ovs-vsctl --db=unix:%s/db.sock --no-wait find Interface name=%s' %(self.path_ovs, in_if_name))
		if output != None and output != "" :
			return re.search( r'ofport(.*): (\d*)', output).group(2)
		else:
			error("ERROR port not available\n")
			sys.exit(-2)

	def translate_rule(self, rule):
		# ports reg exp
		out_port = re.compile('output:(.*?),')
		in_port = re.compile('in_port=(.*?),')
		out_port_end = ","
	
		#test if rule has in_port
		if 'in_port' in rule and not re.search(in_port, rule):
			error("ERROR wrong format for in_port\n")
			sys.exit(-2)	
		elif 'in_port' in rule and re.search(in_port, rule):
			in_if_name = in_port.search(rule).group(1)
			in_if_index = self.get_if_index(in_if_name)
			rule = re.sub(in_port, "in_port="+in_if_index+",", rule)

		#test if rule has output_port
		if 'output' in rule and not re.search(out_port, rule):
			#print "output: not followed by comma, retry.."
			out_port = re.compile('output:(.*?)\"(\Z)')
			out_port_end = "\""
			if not re.search(out_port, rule):
				error("ERROR wrong format for out_put port\n")
				sys.exit(-2)
			out_if_name = out_port.search(rule).group(1)
			out_if_index = self.get_if_index(out_if_name)	
			rule = re.sub(out_port, "output:"+out_if_index+out_port_end, rule)
		elif 'output' in rule and re.search(out_port, rule):	
			out_if_name = out_port.search(rule).group(1)
			out_if_index = self.get_if_index(out_if_name)
			rule = re.sub(out_port, "output:"+out_if_index+out_port_end, rule)

		return rule

	def terminate( self ):
		Host.terminate(self)
		shutil.rmtree("%s/%s" %(self.baseDIR, self.name), ignore_errors=True)

	def strip_number(self, intf):
		intf = str(intf)
		intf_pattern = re.search(r'%s-eth\d+$' %(self.name), intf)
		if intf_pattern is None:
			error("ERROR bad name for intf\n")
			exit(-2)
		data = intf.split('-')
		return int(data[1][3:])

class OSHIroot(Node):

	def __init__(self, name, *args, **kwargs ):
		Node.__init__( self, name, inNamespace=False, *args, **kwargs )
		self.brname = "br-dreamer"
		self.OF_V = "OpenFlow13"

	def start( self, table, pws_data=[]):
	
		rules = []

		for pw_data in pws_data:

			eth = pw_data['cer_intf']
			v_eth1 = pw_data['vsf_intf1']
			v_eth2 = pw_data['vsf_intf2']

			if v_eth1:
				self.cmd("ifconfig %s 0" % v_eth1)
			self.cmd("ifconfig %s 0" % v_eth2)

			if v_eth1:			
				self.cmd("ovs-vsctl --no-wait add-port %s %s" %(self.brname, v_eth1))
			self.cmd("ovs-vsctl --no-wait add-port %s %s" %(self.brname, v_eth2))

			if eth and v_eth1:
				rules.append('ovs-ofctl -O %s add-flow %s "table=%s,hard_timeout=0,priority=%s,in_port=%s,action=output:%s"' %(self.OF_V, self.brname,
				table, 32768, eth, v_eth1))
				rules.append('ovs-ofctl -O %s add-flow %s "table=%s,hard_timeout=0,priority=%s,in_port=%s,action=output:%s"' %(self.OF_V, self.brname, 
				table, 32768, v_eth1, eth))
				for rule in rules:
					rule = self.translate_rule(rule)
					self.cmd(rule)

	def get_if_index(self, in_if_name):
		output = self.cmd('ovs-vsctl --no-wait find Interface name=%s' %(in_if_name))
		if output != None and output != "" :
			return re.search( r'ofport(.*): (\d*)', output).group(2)
		else:
			error("ERROR port not available\n")
			sys.exit(-2)

	def translate_rule(self, rule):
		# ports reg exp
		out_port = re.compile('output:(.*?),')
		in_port = re.compile('in_port=(.*?),')
		out_port_end = ","
	
		#test if rule has in_port
		if 'in_port' in rule and not re.search(in_port, rule):
			error("ERROR wrong format for in_port\n")
			sys.exit(-2)	
		elif 'in_port' in rule and re.search(in_port, rule):
			in_if_name = in_port.search(rule).group(1)
			in_if_index = self.get_if_index(in_if_name)
			rule = re.sub(in_port, "in_port="+in_if_index+",", rule)

		#test if rule has output_port
		if 'output' in rule and not re.search(out_port, rule):
			#print "output: not followed by comma, retry.."
			out_port = re.compile('output:(.*?)\"(\Z)')
			out_port_end = "\""
			if not re.search(out_port, rule):
				error("ERROR wrong format for out_put port\n")
				sys.exit(-2)
			out_if_name = out_port.search(rule).group(1)
			out_if_index = self.get_if_index(out_if_name)	
			rule = re.sub(out_port, "output:"+out_if_index+out_port_end, rule)
		elif 'output' in rule and re.search(out_port, rule):	
			out_if_name = out_port.search(rule).group(1)
			out_if_index = self.get_if_index(out_if_name)
			rule = re.sub(out_port, "output:"+out_if_index+out_port_end, rule)

		return rule

