Red Hat OpenShift 4.2, Red Hat OpenStack Platform 13

### Create overcloud configuration ###

Create overcloud images including octavia:
~~~
openstack overcloud container image prepare \
  --namespace=registry.access.redhat.com/rhosp13 \
  --prefix=openstack- \
  -e /usr/share/openstack-tripleo-heat-templates/environments/services-docker/octavia.yaml \
  --tag-from-label {version}-{release} \
  --output-env-file=${template_base_dir}/overcloud_images.yaml
~~~

Create openstack overcloud deploy command:
~~~
openstack overcloud deploy --templates \
-e ${template_base_dir}/overcloud_images.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services-docker/octavia.yaml \
-e ${template_base_dir}/network-environment.yaml \
-e ${template_base_dir}/node-count.yaml \
-e ${template_base_dir}/novnc.yaml \
-e ${template_base_dir}/octavia-env.yaml \
--log-file /home/stack/overcloud_install.log
~~~

In this example, OpenShift is installed in the `admin` project with UUID `1bb14f515f0945a4891fe3fa2372a795`:

Create `octavia-env.yaml` according to [https://docs.openshift.com/container-platform/4.2/installing/installing_openstack/installing-openstack-installer-kuryr.html](https://docs.openshift.com/container-platform/4.2/installing/installing_openstack/installing-openstack-installer-kuryr.html):
~~~
(undercloud) [stack@undercloud-0 ~]$ cat octavia/octavia-env.yaml 
# https://docs.openshift.com/container-platform/4.2/installing/installing_openstack/installing-openstack-installer-kuryr.html
parameter_defaults:
  OctaviaTimeoutClientData: 1800000
  OctaviaTimeoutMemberData: 1800000
  ControllerExtraConfig:
    octavia::config::octavia_config:
      controller_worker/amp_secgroup_allowed_projects:
        value: "1bb14f515f0945a4891fe3fa2372a795"
  NeutronOVSFirewallDriver: openvswitch
~~~
> **Note:** The project UUID for `controller_worker/amp_secgroup_allowed_projects` cannot be known beforehand. 
> Hence, this UUID needs to be changed after a first deployment and the `openstack overcloud deploy (...) command needs to be run again.

Set secgroups after deployment:
~~~
source overcloudrc
openstack quota set --secgroups 250 --secgroup-rules 1000 --ports 1500 --subnets 250 --networks 250 admin
openstack quota set --routers 40 --ram 307200 --cores 100 --gigabytes 500 admin
~~~

Create flavor:
~~~
openstack --os-cloud openstack flavor create --disk 25 --ram 32768 --vcpus 8 m1.openshift
~~~

Create image:
~~~
openstack image create --container-format=bare --disk-format=qcow2 --file rhcos-4.2.0-x86_64-openstack.qcow2 rhcos
~~~

Create networks, subnets, routers:
~~~
PROVIDER_SEGMENTATION_ID_PRIVATE=106
PROVIDER_PHYSICAL_NETWORK="tenant"
PROVIDER_PHYSICAL_NETWORK_EXTERNAL="external"
neutron net-create private1 --provider:network_type vlan --provider:physical_network $PROVIDER_PHYSICAL_NETWORK --provider:segmentation_id $PROVIDER_SEGMENTATION_ID_PRIVATE --shared --router:external
neutron net-create provider1 --provider:network_type flat --provider:physical_network $PROVIDER_PHYSICAL_NETWORK_EXTERNAL --shared --router:external
neutron subnet-create --name private1-subnet private1 192.168.0.0/24 --allocation-pool start=192.168.0.100,end=192.168.0.150
neutron subnet-create --gateway 172.16.0.1 --allocation-pool start=172.16.0.100,end=172.16.0.150 --dns-nameserver 10.11.5.4 --name provider1-subnet provider1 172.16.0.0/24
neutron router-create router
neutron router-gateway-set router provider1
neutron router-interface-add router private1-subnet
~~~

Create 2 floating IPs:
~~~
openstack floating ip create provider1
openstack floating ip create provider1
~~~

Modify /etc/hosts on Director node:
~~~

~~~

Configure OpenShift's install-config.yaml:
~~~
apiVersion: v1
baseDomain: redhat.local
compute:
- hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 3
controlPlane:
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 3
metadata:
  creationTimestamp: null
  name: osc
networking:
  clusterNetwork:
  - cidr: 172.20.0.0/14
    hostPrefix: 23
  machineCIDR: 172.31.0.0/16
  networkType: Kuryr
  serviceNetwork:
  - 172.30.0.0/16
platform:
  openstack:
    cloud: overcloud
    computeFlavor: m1.openshift
    externalNetwork: provider1
    lbFloatingIP: 172.16.0.112
    octaviaSupport: "1"
    region: ""
    trunkSupport: "1"
pullSecret: '(...)'
sshKey: |
  ssh-rsa (...)
  ~~~
