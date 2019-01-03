### Pbench installation guide for Red Hat OpenStack Platform ###

#### Prerequisite: Enable login from user root to user root on all overcloud nodes. ####

The undercloud root user needs to be able to log into the overcloud nodes, as user root.

Execute this as user stack on the undercloud / Director node. Replace hostlist with the list over overcloud nodes.
~~~
source stackrc
pubkey=$(sudo cat /root/.ssh/id_rsa.pub)
hostlist=$(nova list | awk -F '[ \t]+|=' '/ACTIVE/ {print $(NF-1)}')  # all overcloud nodes, change for less
for host in $hostlist; do 
  ssh heat-admin@${host} "hostname ; echo '$pubkey' | sudo tee -a /root/.ssh/authorized_keys ; echo 'PermitRootLogin yes' | sudo tee -a /etc/ssh/sshd_config ; sudo systemctl restart sshd"
done
~~~
> Note: This will permit root login and is a potential security risk.

Now, become the root user and verify that you can log into the overcloud nodes:
~~~
for host in $hostlist; do 
  ssh $host hostname
done
~~~

### Installing pbench-agent on each node ###

On the undercloud, and on each node that needs to be monitored, install pbench-agent.

~~~
subscription-manager repos --enable=rhel-7-server-optional-rpms 
yum install yum-plugin-copr -y
yum copr enable ndokos/pbench -y
yum install pbench-agent -y
~~~

### Registering overcloud nodes with the undercloud ###

Log out of the undercloud and log back in, or start a new shell, e.g. `bash`, to reload the environment's `PATH`. 
Once that's done, you should be able to run the `pbench-*` commands.

~~~
source stackrc
hostlist=$(nova list | awk -F '[ \t]+|=' '/ACTIVE/ {print $(NF-1)}')
toollist="sar iostat mpstat pidstat proc-vmstat proc-interrupts turbostat"
for host in $hostlist; do
  for tool in $toollist; do
    pbench-register-tool --name=$tool --remote=$host
  done
done
~~~

Verify the configuration with `pbench-list-tools`, e.g.:
~~~
(undercloud) [root@undercloud-r430 ~]# pbench-list-tools 
default: 192.168.24.14[iostat,mpstat,perf,pidstat,proc-interrupts,proc-vmstat,sar,turbostat],192.168.24.6[iostat,mpstat,pidstat,proc-interrupts,proc-vmstat,sar,turbostat]
~~~

### Run the benchmark ###

The following will run a 300 second benchmark:
~~~
pbench-user-benchmark -- sleep 300
~~~

In order to run a long-lasting benchmark, run it from within a screen.

### Collecting the data ###
(...)
