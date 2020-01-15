## Prerequisites ##

### Creating additional OpenStack infrastructure ###

Add an additional port to each of the 3 workers:
~~~
source overcloudrc  # or respective RC file
openstack network create akaris-backend
openstack subnet create --network akaris-backend akaris-backend-subnet --subnet-range 172.31.254.0/24 --no-dhcp
openstack port create --disable-port-security --no-security-group --no-fixed-ip --network akaris-backend akaris-backend-port-0
openstack port create --disable-port-security --no-security-group --no-fixed-ip --network akaris-backend akaris-backend-port-1
openstack port create --disable-port-security --no-security-group --no-fixed-ip --network akaris-backend akaris-backend-port-2
openstack server add port akaris-osc-r4gsx-worker-6x48k akaris-backend-port-0
openstack server add port akaris-osc-r4gsx-worker-9nk25 akaris-backend-port-1
openstack server add port akaris-osc-r4gsx-worker-qz5g6 akaris-backend-port-2
~~~

### Making sure that additional ports work in the workers ###

Connect to the master node:
~~~
[akaris@linux clouds]$ ssh core@<API URL> -A
~~~

From there, connect to each worker and configure the new interface (in this case, ens6):
~~~
ssh core@akaris-osc-r4gsx-worker-9nk25
~~~

Enable ports with nmcli:
~~~
nmcli connection # this shows a 'Wired conection 2' that is connected to ens6

# I prefer a different name, so delete this one:
nmcli connection delete 'Wired connection 2'

# add a new connection
nmcli connection add type ethernet ifname ens6 con-name ens6

# assign a static IP
nmcli connection modify ens6 ipv4.addresses 172.31.254.12/24 
nmcli connection modify ens6 ipv4.method manual
nmcli connection up ens6
~~~

Once you repeated these steps on all workers, ping between the 3 workers to make sure that network and ports work:
~~~
ip a ls dev ens6
ping 172.31.254.11
ping 172.31.254.10
~~~

## Testing multus ##

* [https://docs.openshift.com/container-platform/4.2/networking/multiple-networks/configuring-ipvlan.html](https://docs.openshift.com/container-platform/4.2/networking/multiple-networks/configuring-ipvlan.html)
* [https://docs.openshift.com/container-platform/4.2/networking/multiple-networks/attaching-pod.html](https://docs.openshift.com/container-platform/4.2/networking/multiple-networks/attaching-pod.html)
