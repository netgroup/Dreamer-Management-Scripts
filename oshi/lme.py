#!/usr/bin/python

import re
import sys
import os
from subprocess import Popen,PIPE


def get_if_index(in_if_name):
	output = Popen(['ovs-vsctl find Interface name=%s' % in_if_name], shell=True, stdout=PIPE).communicate()[0]
	if output != None and output != "" :
		return re.search( r'ofport(.*): (\d*)', output).group(2)
	else:
		print "Error Port Not Available"
		sys.exit(-2)

def add_flow(rule):
	output = Popen([rule], shell=True, stdout=PIPE).communicate()[0]

def translate_rule(rule):
	# ports reg exp
	out_port = re.compile('output:(.*?),')
	in_port = re.compile('in_port=(.*?),')
	out_port_end = ","
	
	#test if rule has in_port
	if 'in_port' in rule and not re.search(in_port, rule):
		print "Error Wrong In Port"
		sys.exit(-2)	
	elif 'in_port' in rule and re.search(in_port, rule):
		in_if_name = in_port.search(rule).group(1)
		in_if_index = get_if_index(in_if_name)
		rule = re.sub(in_port, "in_port="+in_if_index+",", rule)

	#test if rule has output_port
	if 'output' in rule and not re.search(out_port, rule):
		#print "output: not followed by comma, retry.."
		out_port = re.compile('output:(.*?)\"(\Z)')
		out_port_end = "\""
		if not re.search(out_port, rule):
			print "Error Wrong Output Port"
			sys.exit(-2)
		out_if_name = out_port.search(rule).group(1)
		out_if_index = get_if_index(out_if_name)	
		rule = re.sub(out_port, "output:"+out_if_index+out_port_end, rule)
	elif 'output' in rule and re.search(out_port, rule):	
		out_if_name = out_port.search(rule).group(1)
		out_if_index = get_if_index(out_if_name)
		rule = re.sub(out_port, "output:"+out_if_index+out_port_end, rule)

	return rule

def push_rules():
	path = "lmerules.sh"
	if os.path.exists(path) == False:
		print "Error Rules File Not Exists"
		sys.exit(-2)
	filesh = open(path, 'r')
	lines = filesh.readlines()
	for line in lines:
		if "start" not in line and "end" not in line:
			rule = line[:-1]
			rule = translate_rule(rule)
			add_flow(rule)
			

if __name__ == '__main__':
	push_rules()	

	







