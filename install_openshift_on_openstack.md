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

Create the following directory structure:
~~~
[stack@host clouds]$ ll
total 2247156
-rw-rw-r--. 1 stack stack        322 Oct 30 12:42 clouds.yaml
drwxrwxr-x. 4 stack stack        242 Nov  4 07:45 install-config
drwxrwxr-x. 2 stack stack         48 Oct 30 12:24 openshift-client
-rw-rw-r--. 1 stack stack   24533950 Oct 30 12:23 openshift-client-linux-4.2.0.tar.gz
-rwxr-xr-x. 1 stack stack  293887936 Oct 10 17:49 openshift-install
-rw-rw-r--. 1 stack stack   71492736 Oct 30 12:23 openshift-install-linux-4.2.0.tar.gz
-rw-r--r--. 1 stack stack        706 Oct 10 17:49 README.md
-rw-rw-r--. 1 stack stack 1911160832 Oct 30 11:33 rhcos-4.2.0-x86_64-openstack.qcow2
~~~
