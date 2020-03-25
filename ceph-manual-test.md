### Using Ceph with qemu-kvm manually ###

#### Downloading and customizing qcow2 ####



#### Uploading image into Ceph pool ####

~~~
qemu-img convert -f qcow2 -O raw rhel-server-7.8-beta-1-x86_64-kvm.qcow2 rbd:rbd-pool/rhel-server-7.8-beta-1-x86_64-kvm
~~~

#### Booting a VM from the raw Ceph image ####

Start a VM that directly uses the uploaded image from the Ceph pool:
~~~
/usr/libexec/qemu-kvm -drive file=rbd:rbd-pool/rhel-server-7.8-beta-1-x86_64-kvm -nographic -m 1024
~~~

To get out of qemu-kvm, type `CTRL-a x`
