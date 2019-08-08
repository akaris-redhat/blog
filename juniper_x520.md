### How to label interfaces on a Juniper switch with X520 cards ###

Enable console logging on the Juniper switch:
~~~
root@gss-sw02> monitor start messages | match ifOperStatus
~~~

Disable console logging on the Juniper switch:
~~~
root@gss-sw02> monitor stop messages
~~~

Flap server interface:
~~~
[root@gss02 ~]#  ethtool -r p1p3
~~~

This will log the following in the switch:
~~~
root@gss-sw02> Aug  9 05:40:40  gss-sw02 mib2d[2112]: SNMP_TRAP_LINK_DOWN: ifIndex 521, ifAdminStatus up(1), ifOperStatus down(2), ifName xe-0/0/2
Aug  9 05:40:40  gss-sw02 mib2d[2112]: SNMP_TRAP_LINK_UP: ifIndex 521, ifAdminStatus up(1), ifOperStatus up(1), ifName xe-0/0/2
~~~

Now, one can set an interface description:
~~~
root@gss-sw02> edit     
Entering configuration mode

{master:0}[edit]
root@gss-sw02# set interfaces xe-0/0/2 description "gss02 p1p3" 

root@gss-sw02# commit  
configuration check succeeds
commit complete

{master:0}[edit]
root@gss-sw02# exit 
Exiting configuration mode

{master:0}
root@gss-sw02> show interfaces descriptions    
Interface       Admin Link Description
xe-0/0/0        up    up   gss01 p1p3
xe-0/0/1        up    up   gss01 p1p4
xe-0/0/2        up    up   gss02 p1p3
~~~
