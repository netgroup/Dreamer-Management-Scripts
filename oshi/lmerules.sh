# 62.40.110.8 - start
# COEXA - start
ovs-ofctl add-flow br-dreamer "table=0,hard_timeout=0,priority=300,dl_vlan=1,actions=resubmit(,1)"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=tap1,action=output:vi1"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=vi1,action=output:tap1"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=tap2,action=output:vi2"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=vi2,action=output:tap2"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=tap3,action=output:vi3"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=vi3,action=output:tap3"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=tap4,action=output:vi4"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=vi4,action=output:tap4"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=tap5,action=output:vi5"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=vi5,action=output:tap5"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=400,dl_type=0x88cc,action=controller"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=400,dl_type=0x8942,action=controller"
# COEXA - end
# INGRB - start
ovs-ofctl add-flow br-dreamer "table=0,hard_timeout=0,priority=300,in_port=tap3,actions=mod_vlan_vid:1,resubmit(,1)"
ovs-ofctl add-flow br-dreamer "table=1,hard_timeout=0,priority=300,in_port=vi3,actions=strip_vlan,output:tap3"
# INGRB - end
# 62.40.110.8 - end
