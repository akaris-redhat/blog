### Single node DB on ovn1 ###

#### Configuration and installation ####

The following starts an OVN cluster on Fedora 31 with 3 nodes. Non-clustered DB with ovn1 as the DB node, and ovn2 and ovn3 join ovn1's DB.

All nodes have 2 interfaces. One management interface on eth0. DNS names ovn1, ovn2, ovn3 map to the IP addresses on eth0. Interface eth1 has no IP addresses and will be used for the dataplane (attached to br-provider).

Hostname to IP address mapping:
~~~
192.168.122.150 ovn1  # eth0
192.168.122.22  ovn2  # eth0
192.168.122.28  ovn3  # eth0
~~~

Install Open vSwitch and OVN on all nodes:
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
echo 'OVN_NORTHD_OPTS="--db-nb-addr=ovn1 --db-nb-create-insecure-remote=yes --db-sb-addr=ovn1  --db-sb-create-insecure-remote=yes  --db-nb-cluster-local-addr=ovn1 --db-sb-cluster-local-addr=ovn1 --ovn-northd-nb-db=tcp:ovn1:6641 --ovn-northd-sb-db=tcp:ovn1:6642"' >> /etc/sysconfig/ovn
systemctl enable --now ovn-northd
~~~

Note that the above will start a single node cluster. The OVN man page contains an example for a full 3 node clustered DB: [http://www.openvswitch.org/support/dist-docs/ovn-ctl.8.txt](http://www.openvswitch.org/support/dist-docs/ovn-ctl.8.txt)

Now, configure OVS to connect to the OVN DBs. Note that geneve / vxlan tunnel needs IP addresses, DNS entries do not work:

On master node ovn1:
~~~
[root@ovn1 ~]# ovs-vsctl set open . external-ids:ovn-remote=tcp:ovn1:6642
[root@ovn1 ~]# ovs-vsctl set open . external-ids:ovn-encap-type=geneve
[root@ovn1 ~]# ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.122.150
[root@ovn1 ~]# ovs-vsctl set open . external-ids:ovn-bridge=br-int
~~~

On slave node ovn2:
~~~
[root@ovn2 ~]# ovs-vsctl set open . external-ids:ovn-remote=tcp:ovn1:6642
[root@ovn2 ~]# ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.122.22
[root@ovn2 ~]# ovs-vsctl set open . external-ids:ovn-encap-type=geneve
[root@ovn2 ~]# ovs-vsctl set open . external-ids:ovn-bridge=br-int
~~~

On slave node ovn3:
~~~
[root@ovn3 ~]# ovs-vsctl set open . external-ids:ovn-remote=tcp:ovn1:6642
[root@ovn3 ~]# ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.122.28
[root@ovn3 ~]# ovs-vsctl set open . external-ids:ovn-encap-type=geneve
[root@ovn3 ~]# ovs-vsctl set open . external-ids:ovn-bridge=br-int
~~~

Add provider bridge mapping on all 3 nodes:
~~~
ovs-vsctl set open . external-ids:ovn-bridge-mappings=provider:br-provider
ovs-vsctl --may-exist add-br br-provider
ovs-vsctl --may-exist add-port br-provider eth1
~~~

#### Verification ####

Verify on ovn1:
~~~
[root@ovn1 ~]# ovs-vsctl show
19c6fe50-cf4b-4ca1-8e38-bf7e8518fb82
    Bridge br-provider
        Port br-provider
            Interface br-provider
                type: internal
    Bridge br-int
        fail_mode: secure
        Port "ovn-51cb96-1"
            Interface "ovn-51cb96-1"
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.122.28"}
        Port "ovn-96baf9-1"
            Interface "ovn-96baf9-1"
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.122.22"}
        Port br-int
            Interface br-int
                type: internal
    ovs_version: "2.12.0"
[root@ovn1 ~]# ovn-sbctl show
Chassis "7a992c50-4fcb-4e47-ac6f-38a41ba546d0"
    hostname: ovn1
    Encap geneve
        ip: "192.168.122.150"
        options: {csum="true"}
    Encap vxlan
        ip: "192.168.122.150"
        options: {csum="true"}
Chassis "96baf91e-59bc-4a4d-809a-2f16e8055868"
    hostname: ovn2
    Encap vxlan
        ip: "192.168.122.22"
        options: {csum="true"}
    Encap geneve
        ip: "192.168.122.22"
        options: {csum="true"}
Chassis "51cb9682-520e-4160-8b1d-1893741a6b93"
    hostname: ovn3
    Encap geneve
        ip: "192.168.122.28"
        options: {csum="true"}
    Encap vxlan
        ip: "192.168.122.28"
        options: {csum="true"}
        [root@ovn1 ~]# ovn-nbctl show
[root@ovn1 ~]# 
~~~

ovn2:
~~~
[root@ovn2 ~]# ovs-vsctl show
eacb0a18-393a-4894-a427-28dab94e0b16
    Bridge br-provider
        Port br-provider
            Interface br-provider
                type: internal
        Port "eth1"
            Interface "eth1"
    Bridge br-int
        fail_mode: secure
        Port "ovn-51cb96-1"
            Interface "ovn-51cb96-1"
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.122.28"}
        Port "ovn-7a992c-1"
            Interface "ovn-7a992c-1"
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.122.150"}
        Port br-int
            Interface br-int
                type: internal
    ovs_version: "2.12.0"
[root@ovn2 ~]# ovn-sbctl show
[root@ovn2 ~]# ovn-nbctl show
[root@ovn2 ~]# 
~~~

ovn3:
~~~
[root@ovn3 ~]# ovs-vsctl show
9f47b6f7-db2e-4aee-bfa2-0b1d1b8a934c
    Bridge br-int
        fail_mode: secure
        Port br-int
            Interface br-int
                type: internal
        Port "ovn-96baf9-1"
            Interface "ovn-96baf9-1"
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.122.22"}
        Port "ovn-7a992c-1"
            Interface "ovn-7a992c-1"
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.122.150"}
    Bridge br-provider
        Port "eth1"
            Interface "eth1"
        Port br-provider
            Interface br-provider
                type: internal
    ovs_version: "2.12.0"
[root@ovn3 ~]# ovn-sbctl show
[root@ovn3 ~]# ovn-nbctl show
[root@ovn3 ~]# 
~~~
