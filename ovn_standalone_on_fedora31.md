## Base setup ##

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

## Adding virtual network ##

### Adding logical switch and ports ###

On ovn1, configure a logical switch and port:
~~~
ovn-nbctl ls-add sw0
ovn-nbctl lsp-add sw0 port0
ovn-nbctl lsp-add sw0 port1
~~~

Now, "real" ports need to be wired to the above ports. Note that the logical port name has to match the `external_ids:iface-id` identifier. If we added  `ovn-nbctl lsp-add sw0 foo` instead of `port0`, then we would have to set `ovs-vsctl set Interface port0 external_ids:iface-id=foo` on ovn2.

On ovn2, execute:
~~~
ip link add name veth0 type veth peer name port0
ip netns add ns0
ip link set dev veth0 netns ns0
ip netns exec ns0 ip link set dev lo up
ip netns exec ns0 ip link set dev veth0 up
ip netns exec ns0 ip address add 192.168.123.1/24 dev veth0
ip link set dev port0 up
ovs-vsctl add-port br-int port0 
ovs-vsctl set Interface port0 external_ids:iface-id=port0
~~~

On ovn3, execute:
~~~
ip link add name veth1 type veth peer name port1
ip netns add ns1
ip link set dev veth1 netns ns1
ip netns exec ns1 ip link set dev lo up
ip netns exec ns1 ip link set dev veth1 up
ip netns exec ns1 ip address add 192.168.123.2/24 dev veth1
ip link set dev port1 up
ovs-vsctl add-port br-int port1 external_ids:iface-id=port1
ovs-vsctl set Interface port1 external_ids:iface-id=port1
~~~

Verify the new configuration:
~~~
[root@ovn1 ~]# ovn-nbctl show
switch 440ff3f7-0405-481b-af89-8def80542886 (sw0)
    port port0
    port port1
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
    Port_Binding port0
Chassis "51cb9682-520e-4160-8b1d-1893741a6b93"
    hostname: ovn3
    Encap geneve
        ip: "192.168.122.28"
        options: {csum="true"}
    Encap vxlan
        ip: "192.168.122.28"
        options: {csum="true"}
    Port_Binding port`
~~~
> **Note:** The southbound database now shows port bindings.
