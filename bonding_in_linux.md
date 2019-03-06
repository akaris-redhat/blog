### About the different bonding options in Linux ###

Populat bonding options and drivers are:

* Linux bonding kernel driver
  To verify: `cat /proc/net/bonding/<bond name>`
* Teaming driver where only the essential stuff is in kernel, the rest is userspace ([https://rhelblog.redhat.com/2014/06/23/team-driver/](https://rhelblog.redhat.com/2014/06/23/team-driver/))
* OVS (either bonding PMDs in DPDK or kernel interfaces)
  [http://docs.openvswitch.org/en/latest/topics/bonding/](http://docs.openvswitch.org/en/latest/topics/bonding/)
  To verify: `ovs-appctl bond/show ; ovs-appctl lacp/show`
* DPDK (there is a bonding PMD)

### Questsion ###

* Why can't one port-mirror per port in OVS bonding?
* How stable is OVS bonding (packet loss?)
* Why does port mirroring on OVS bonds show packets 2x?
