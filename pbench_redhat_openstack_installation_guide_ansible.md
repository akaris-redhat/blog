### Pbench installation guide for Red Hat OpenStack Platform / RDO - with Ansible ###

> The following guide contains instructions for enabling pbench in Red Hat OpenStack Platform environments or RDO. This guide is not complete, may introduce security risks and could potentially harm the cloud environment. Install and test in developement environments and never run this in a production environment unless you know exactly what you are doing.

#### Prerequisites: Clone pbench_openstack.git repository ####

Install git and clone the repository as user stack. Also, source stackrc:
~~~
su - stack
. stackrc
~~~

~~~
sudo yum install git -y
git clone https://github.com/andreaskaris/pbench_openstack.git
cd pbench_openstack
~~~

#### Prerequisite: Enable login from user root to user root on all overcloud nodes. ####

The undercloud root user needs to be able to log into the overcloud nodes, as user root.

Execute this as user stack on the undercloud / Director node. Modify the `hosts:` field in the playbook if need:
~~~
ansible-playbook -i /usr/bin/tripleo-ansible-inventory enable_root_to_root_login.yml
~~~
> Note: This will permit root login and is a potential security risk.

Now, become the root user and verify that you can log into the overcloud nodes:
~~~
sudo -i
hostlist=$(nova list | awk -F '[ \t]+|=' '/ACTIVE/ {print $(NF-1)}')  # all overcloud nodes, change for less
for host in $hostlist; do 
  ssh $host hostname
done
~~~

#### Installing pbench-agent on each node ####

On the undercloud, and on each node that needs to be monitored, install pbench-agent. Run this as user
stack from the pbench_openstack directory. Adjust the list of `hosts:` in the script if needed. Then, execute:
~~~
ansible-playbook -i /usr/bin/tripleo-ansible-inventory install_pbench.yml
~~~

If nodes aren't registered yet, execute with:
~~~
ansible-playbook -i /usr/bin/tripleo-ansible-inventory install_pbench.yml \
     --extra-vars "(...) do_register=true org=<org-id> --activationkey=<activation key> (...)"
~~~

#### Registering overcloud nodes with the undercloud ####

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

#### Run the benchmark ####

The following will run a 300 second benchmark:
~~~
pbench-user-benchmark -- sleep 300
~~~
> Note: This will run sleep for 300 seconds and return after this. However, at the same time, this will run and collect data for all registered tools.

In order to run a long-lasting benchmark, run it from within a screen.

Note that collected data can become quite large quite quickly. The above 300 second run consumed 18 MB:
~~~
(undercloud) [root@undercloud-r430 ~]# du -sh /var/lib/pbench-agent/pbench-user-benchmark__2019.01.03T00.13.26
18M	/var/lib/pbench-agent/pbench-user-benchmark__2019.01.03T00.13.26
~~~
Make sure to have sufficient disk space on all nodes.

> Note: The most common problem is if someone kills pbench-user-benchmark abnormally, and the tool collection does not stop, and that can fill up disk space if left to continue.  So just be sure that does not happen or use 
~~~
pbench-kill-tools
~~~

#### Collecting the data ####
The data will be under `/var/lib/pbench-agent/` in a directory with pattern `pbench-user-benchmark__.*`:
~~~
(undercloud) [root@undercloud-r430 ~]# ls /var/lib/pbench-agent/
pbench.log  pbench-user-benchmark__2019.01.03T00.13.26  tmp  tools-default
(undercloud) [root@undercloud-r430 ~]# ls  /var/lib/pbench-agent/pbench-user-benchmark__2019.01.03T00.13.26/1/reference-result/tools-default
overcloud-computesriov-0  overcloud-controller-0
~~~

tar the folder to send it to a remote system for analysis:
~~~
tar -czf /root/pbench-user-benchmark__2019.01.03T00.13.26.tar.gz /var/lib/pbench-agent/pbench-user-benchmark__2019.01.03T00.13.26
~~~

### Setting up pbench-webserver to view results ###

> Note: Work in progress
> Note: The following was configured on the undercloud for testing purposes. However, do not do this. The web server should be configured on another host!

Install the pbench-web-server:
~~~
subscription-manager repos --enable=rhel-7-server-rhoar-nodejs-10-rpms
yum install pbench-web-server.noarch -y
~~~

In order to visualize results:
~~~
ln -sf /opt/pbench-web-server/html/static /var/www/html
ln -sf /var/lib/pbench-agent /var/www/html
~~~

And browse to:
~~~
http://localhost/pbench-agent
~~~
> Note: Appropriate firewall rules need to be opened.