### About the different bonding options in Linux ###

Populat bonding options and drivers are:

* Linux bonding kernel driver
  To verify: `cat /proc/net/bonding/<bond name>`
* Teaming driver where only the essential stuff is in kernel, the rest is userspace
* OVS (where I guess the same is the case, but I don't know) and well the 4th one would be OVS DPDK
  [http://docs.openvswitch.org/en/latest/topics/bonding/](http://docs.openvswitch.org/en/latest/topics/bonding/)
  To verify: `ovs-appctl bond/show ; ovs-appctl lacp/show`
