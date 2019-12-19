Install Open vSwitch and OVN:
~~~
yum install ovn -y
yum install ovn-central -y
yum install ovn-host -y
~~~

Enable Open vSwitch and ovn-controller on all hosts and start right away:
~~~
systemctl enable --now openvswitch
systemctl enable --now ovn-controller
~~~

On the master nodes that are to hold the ovn-northd "control plane", execute:
~~~
systemctl enable --now ovn-northd
~~~

On master node ovn1 (called ovn1 in this case):
~~~
[root@ovn1 ~]# ovs-vsctl set open . external-ids:ovn-remote=unix:/var/run/ovn/ovnsb_db.sock
[root@ovn1 ~]# ovs-vsctl set open . external-ids:ovn-encap-type=geneve
[root@ovn1 ~]# ovs-vsctl set open . external-ids:ovn-encap-ip=ovn1
[root@ovn1 ~]# ovs-vsctl set open . external-ids:ovn-bridge=br-int
~~~

On slave node ovn2:
~~~
[root@ovn2 ~]# ovs-vsctl set open . external-ids:ovn-remote=tcp:ovn1:6642
[root@ovn2 ~]# ovs-vsctl set open . external-ids:ovn-encap-ip=ovn2
[root@ovn2 ~]# ovs-vsctl set open . external-ids:ovn-encap-type=geneve
[root@ovn2 ~]# ovs-vsctl set open . external-ids:ovn-bridge=br-int
~~~

On slave node ovn3:
~~~
[root@ovn3 ~]# ovs-vsctl set open . external-ids:ovn-remote=tcp:ovn1:6642
[root@ovn3 ~]# ovs-vsctl set open . external-ids:ovn-encap-ip=ovn3
[root@ovn3 ~]# ovs-vsctl set open . external-ids:ovn-encap-type=geneve
[root@ovn3 ~]# ovs-vsctl set open . external-ids:ovn-bridge=br-int
~~~

Add provider bridge mapping on all 3 nodes:
~~~
ovs-vsctl set open . external-ids:ovn-bridge-mappings=provider:br-provider
ovs-vsctl --may-exist add-br br-provider
ovs-vsctl --may-exist add-port br-provider eth1
~~~
