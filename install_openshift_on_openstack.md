### Spawning OpenShift on OSP 13 ###

Use the official guide: 
[https://access.redhat.com/documentation/en-us/openshift_container_platform/4.2/html/installing/installing-on-openstack](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.2/html/installing/installing-on-openstack)

#### Prerequisites ####

At time of this writing, the guide isn't entirely exact with regards to several prerequisites.

Create working directory:
~~~
mkdir clouds
cd clouds
~~~

Generate clouds.yaml:
[https://access.redhat.com/documentation/en-us/openshift_container_platform/4.2/html/installing/installing-on-openstack](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.2/html/installing/installing-on-openstack)

Update quotas:
~~~
project=$(openstack project list | awk '/admin/ {print $2}')
openstack --os-cloud openstack quota set \
  --secgroups 10 --secgroup-rules 60 --ports 100 --routers 20 \
  --ram 153600 --cores 50 --gigabytes 500 \
  $project
~~~

Create flavor:
~~~
openstack --os-cloud openstack flavor create --disk 25 --ram 16384 --vcpus 4 m1.openshift
~~~

Download image and create it:
[https://access.redhat.com/downloads/content/290/ver=4.2/rhel---8/4.2.1/x86_64/product-software](https://access.redhat.com/downloads/content/290/ver=4.2/rhel---8/4.2.1/x86_64/product-software)

Note that there's only one coreos image which is based on RHCOREOS 8. Download that. At time of this writing, the file ending is .qcow2, but
it's really a .qcow2.gz. Hence, rename the file to .gz and extract:
~~~
mv rhcos-4.2.0-x86_64-openstack.qcow2{,.gz}
gunzip rhcos-4.2.0-x86_64-openstack.qcow2.gz
~~~


