### Documentation ###

* [https://access.redhat.com/documentation/en-us/openshift_container_platform/4.3/html/installing_on_openstack/installing-on-openstack](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.3/html/installing_on_openstack/installing-on-openstack)

### Create jump server ###

~~~
source <rc file>
openstack server create --key-name akaris_id_rsa --flavor m1.small --image ... --network provider_net_quicklab akaris_jump_server
~~~
