### Resources ###
[https://en.wikipedia.org/wiki/Cgroups](https://en.wikipedia.org/wiki/Cgroups)

[https://lwn.net/Articles/679786/](https://lwn.net/Articles/679786/)

### cgroups versions ###

cgroup comes in 2 versions. cgroupsv2 are to replace cgroupsv1 eventually.

[https://lwn.net/Articles/679786/](https://lwn.net/Articles/679786/)
> The cgroup subsystem and associated controllers handle management and accounting of various system resources like CPU, memory, I/O, and more. Together with the Linux namespace subsystem, which is a bit older (having started around 2002) and is considered a bit more mature (apart, perhaps, from user namespaces, which still raise discussions), these subsystems form the basis of Linux containers. Currently, most projects involving Linux containers, like Docker, LXC, OpenVZ, Kubernetes, and others, are based on both of them. The development of the Linux cgroup subsystem started in 2006 at Google, led primarily by Rohit Seth and Paul Menage. Initially the project was called "Process Containers", but later on the name was changed to "Control Groups", to avoid confusion with Linux containers, and nowadays everybody calls them "cgroups" for short. There are currently 12 cgroup controllers in cgroups v1; all—except one—have existed for several years. The new addition is the PIDs controller, developed by Aditya Kali and merged in kernel 4.3. It allows restricting the number of processes created inside a control group, and it can be used as an anti-fork-bomb solution. The PID space in Linux consists of, at a maximum, about four million PIDs (PID_MAX_LIMIT). Given today's RAM capacities, this limit could easily and quite quickly be exhausted by a fork bomb from within a single container. The PIDs controller is supported by both cgroups v1 and cgroups v2.
Over the years, there was a lot of criticism about the implementation of cgroups, which seems to present a number of inconsistencies and a lot of chaos. For example, when creating subgroups (cgroups within cgroups), several cgroup controllers propagate parameters to their immediate subgroups, while other controllers do not. Or, for a different example, some controllers use interface files (such as the cpuset controller's clone_children) that appear in all controllers even though they only affect one.
As maintainer Tejun Heo himself has admitted [YouTube], "design followed implementation", "different decisions were taken for different controllers", and "sometimes too much flexibility causes a hindrance". In an LWN article from 2012, it was said that "control groups are one of those features that kernel developers love to hate." 

#### Which version of cgroups are you running? ####

RHEL 7 uses cgroups v1:
~~~
[root@rhospbl-1 ~]# mount | grep cgroup
tmpfs on /sys/fs/cgroup type tmpfs (ro,nosuid,nodev,noexec,seclabel,mode=755)
cgroup on /sys/fs/cgroup/systemd type cgroup (rw,nosuid,nodev,noexec,relatime,xattr,release_agent=/usr/lib/systemd/systemd-cgroups-agent,name=systemd)
cgroup on /sys/fs/cgroup/net_cls,net_prio type cgroup (rw,nosuid,nodev,noexec,relatime,net_prio,net_cls)
cgroup on /sys/fs/cgroup/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,blkio)
cgroup on /sys/fs/cgroup/devices type cgroup (rw,nosuid,nodev,noexec,relatime,devices)
cgroup on /sys/fs/cgroup/hugetlb type cgroup (rw,nosuid,nodev,noexec,relatime,hugetlb)
cgroup on /sys/fs/cgroup/freezer type cgroup (rw,nosuid,nodev,noexec,relatime,freezer)
cgroup on /sys/fs/cgroup/cpu,cpuacct type cgroup (rw,nosuid,nodev,noexec,relatime,cpuacct,cpu)
cgroup on /sys/fs/cgroup/cpuset type cgroup (rw,nosuid,nodev,noexec,relatime,cpuset)
cgroup on /sys/fs/cgroup/perf_event type cgroup (rw,nosuid,nodev,noexec,relatime,perf_event)
cgroup on /sys/fs/cgroup/memory type cgroup (rw,nosuid,nodev,noexec,relatime,memory)
cgroup on /sys/fs/cgroup/pids type cgroup (rw,nosuid,nodev,noexec,relatime,pids)
[root@rhospbl-1 ~]# uname -a
Linux rhospbl-1.openstack.gsslab.rdu2.redhat.com 3.10.0-693.el7.x86_64 #1 SMP Thu Jul 6 19:56:57 EDT 2017 x86_64 x86_64 x86_64 GNU/Linux
~~~

cgroup2 is not in the kernel:
~~~
[root@rhospbl-1 ~]# mount -t cgroup2 none /mnt/test
mount: unknown filesystem type 'cgroup2'
~~~

### cgroups v1 ###
[https://www.kernel.org/doc/Documentation/cgroup-v1/cgroups.txt](https://www.kernel.org/doc/Documentation/cgroup-v1/cgroups.txt)

> Definitions:

> A *cgroup* associates a set of tasks with a set of parameters for one
or more subsystems.

> A *subsystem* is a module that makes use of the task grouping
facilities provided by cgroups to treat groups of tasks in
particular ways. A subsystem is typically a "resource controller" that
schedules a resource or applies per-cgroup limits, but it may be
anything that wants to act on a group of processes, e.g. a
virtualization subsystem.

> A *hierarchy* is a set of cgroups arranged in a tree, such that
every task in the system is in exactly one of the cgroups in the
hierarchy, and a set of subsystems; each subsystem has system-specific
state attached to each cgroup in the hierarchy.  Each hierarchy has
an instance of the cgroup virtual filesystem associated with it.

> (...)

> On their own, the only use for cgroups is for simple job
tracking. The intention is that other subsystems hook into the generic
cgroup support to provide new attributes for cgroups, such as
accounting/limiting the resources which processes in a cgroup can
access. For example, cpusets (see Documentation/cgroup-v1/cpusets.txt) allow
you to associate a set of CPUs and a set of memory nodes with the
tasks in each cgroup.

#### Listing the cgroups that a process is in ####

[https://www.kernel.org/doc/Documentation/cgroup-v1/cgroups.txt](https://www.kernel.org/doc/Documentation/cgroup-v1/cgroups.txt)
>  Each task under /proc has an added file named 'cgroup' displaying,
for each active hierarchy, the subsystem names and the cgroup name
as the path relative to the root of the cgroup file system.

~~~
[root@rhospbl-1 ~]# cat /proc/$(pidof libvirtd)/cgroup
11:pids:/
10:memory:/system.slice
9:perf_event:/
8:cpuset:/
7:cpuacct,cpu:/system.slice
6:freezer:/
5:hugetlb:/
4:devices:/system.slice/libvirtd.service
3:blkio:/system.slice
2:net_prio,net_cls:/
1:name=systemd:/system.slice/libvirtd.service
~~~

#### notify_on_release ####

> If the notify_on_release flag is enabled (1) in a cgroup, then
whenever the last task in the cgroup leaves (exits or attaches to
some other cgroup) and the last child cgroup of that cgroup
is removed, then the kernel runs the command specified by the contents
of the "release_agent" file in that hierarchy's root directory,
supplying the pathname (relative to the mount point of the cgroup
file system) of the abandoned cgroup.  This enables automatic
removal of abandoned cgroups.  The default value of
notify_on_release in the root cgroup at system boot is disabled
(0).  The default value of other cgroups at creation is the current
value of their parents' notify_on_release settings. The default value of
a cgroup hierarchy's release_agent path is empty.

~~~
[root@overcloud-controller-0 ~]# systemctl status session-c2.scope
● session-c2.scope - Session c2 of user rabbitmq
   Loaded: loaded (/run/systemd/system/session-c2.scope; static; vendor preset: disabled)
  Drop-In: /run/systemd/system/session-c2.scope.d
           └─50-After-systemd-logind\x2eservice.conf, 50-After-systemd-user-sessions\x2eservice.conf, 50-Description.conf, 50-SendSIGHUP.conf, 50-Slice.conf, 50-TasksMax.conf
   Active: active (abandoned) since Wed 2018-11-07 22:40:43 UTC; 2 weeks 5 days ago
   CGroup: /user.slice/user-975.slice/session-c2.scope
           └─22384 /usr/lib64/erlang/erts-7.3.1.4/bin/epmd -daemon

Warning: Journal has been rotated since unit was started. Log output is incomplete or unavailable.
[root@overcloud-controller-0 ~]# cat /sys/fs/cgroup/
blkio/            cpu,cpuacct/      freezer/          net_cls/          perf_event/       
cpu/              cpuset/           hugetlb/          net_cls,net_prio/ pids/             
cpuacct/          devices/          memory/           net_prio/         systemd/          
[root@overcloud-controller-0 ~]# cat /sys/fs/cgroup/
blkio/            cpu,cpuacct/      freezer/          net_cls/          perf_event/       
cpu/              cpuset/           hugetlb/          net_cls,net_prio/ pids/             
cpuacct/          devices/          memory/           net_prio/         systemd/          
[root@overcloud-controller-0 ~]# cat /sys/fs/cgroup/
blkio/            cpu,cpuacct/      freezer/          net_cls/          perf_event/       
cpu/              cpuset/           hugetlb/          net_cls,net_prio/ pids/             
cpuacct/          devices/          memory/           net_prio/         systemd/          
[root@overcloud-controller-0 ~]# cat /sys/fs/cgroup/systemd/
cgroup.clone_children  cgroup.procs           machine.slice/         release_agent          tasks
cgroup.event_control   cgroup.sane_behavior   notify_on_release      system.slice/          user.slice/
[root@overcloud-controller-0 ~]# cat /sys/fs/cgroup/systemd/
cgroup.clone_children  cgroup.procs           machine.slice/         release_agent          tasks
cgroup.event_control   cgroup.sane_behavior   notify_on_release      system.slice/          user.slice/
[root@overcloud-controller-0 ~]# cat /sys/fs/cgroup/systemd/user.slice/user-975.slice/session-c2.scope/
cgroup.clone_children  cgroup.event_control   cgroup.procs           notify_on_release      tasks
[root@overcloud-controller-0 ~]# cat /sys/fs/cgroup/systemd/user.slice/user-975.slice/session-c2.scope/notify_on_release 
1
~~~

### The relationship of containers and cgroup ###

Containers are basically just a bunch of cgroups?
~~~
[root@overcloud-controller-0 cpuset]# cat  system.slice/docker-027ca08b78824b60c243324660df7ed4a7fa7659027209e3f646b70a6a9a3cae.scope/tasks 
167446
[root@overcloud-controller-0 cpuset]# docker exec 027ca08b7882 /bin/dd 
^C
[root@overcloud-controller-0 cpuset]# ps aux | grep dd
(...)
42445     894272  0.3  0.0   4404   356 ?        Ss   04:06   0:00 /bin/dd
(...)
[root@overcloud-controller-0 cpuset]# ps aux | grep 167446
42445     167446  0.0  0.3 163940 26892 ?        Ss   Nov07   0:39 /usr/bin/python2 /usr/bin/swift-object-updater /etc/swift/object-server.conf
root      896151  0.0  0.0 112712   976 pts/0    S+   04:07   0:00 grep --color=auto 167446
[root@overcloud-controller-0 cpuset]# ps aux | grep 894272
42445     894272  0.0  0.0   4404   356 ?        Ss   04:06   0:00 /bin/dd
root      896803  0.0  0.0 112708   976 pts/0    S+   04:07   0:00 grep --color=auto 894272
[root@overcloud-controller-0 cpuset]# docker exec -it 027ca08b7882 /bin/bash
()[swift@overcloud-controller-0 /]$ ps aux | grep [d]d
swift       5617  0.0  0.0   4404   356 ?        Ss   04:06   0:00 /bin/dd
()[swift@overcloud-controller-0 /]$ 
~~~
