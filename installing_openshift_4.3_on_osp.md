### Documentation ###

* [https://access.redhat.com/documentation/en-us/openshift_container_platform/4.3/html/installing_on_openstack/installing-on-openstack](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.3/html/installing_on_openstack/installing-on-openstack)

### Create jump server ###

~~~
source <rc file>
openstack server create --key-name akaris_id_rsa --flavor m1.small --image rhel-7.7-server-x86_64-latest --network provider_net_quicklab akaris_jump_server
openstack security group rule create akaris-jump-server --protocol tcp --dst-port 22
openstack server add security group akaris_jump_server akaris-jump-server                             
~~~

Connect to jump server:
~~~
ssh cloud-user@<jump server IP>
~~~

### Prepare jump server ###

~~~
subscription-manager register (...)
subscription-manager repos --enable=rhel-7-server-openstack-13-tools-rpms
yum install screen vim python2-openstackclient
~~~

Prepare directory structure:
~~~
[cloud-user@akaris-jump-server openshift]$ ls -l
total 427864
-rw-rw-r--. 1 cloud-user cloud-user       922 Jan 24 16:28 clouds.yaml
drwxrwxr-x. 2 cloud-user cloud-user        33 Jan 24 16:33 install_backup
drwxrwxr-x. 2 cloud-user cloud-user        63 Jan 24 16:42 install_config
-rw-rw-r--. 1 cloud-user cloud-user  27177324 Jan 24 16:32 oc-4.3.0-linux.tar.gz
-rwxr-xr-x. 1 cloud-user cloud-user 329097376 Jan 21 14:47 openshift-install
-rw-rw-r--. 1 cloud-user cloud-user  81833577 Jan 24 16:31 openshift-install-linux-4.3.0.tar.gz
-rw-rw-r--. 1 cloud-user cloud-user      2735 Jan 24 16:28 pull_secret.txt
~~~

### OpenShift installation ###

~~~
screen
./openshift-install create cluster --dir=install_config/ --log-level=debug
~~~
