### Resources ###

~~~
[akaris@wks-akaris blog]$ apropos namespace | grep _namespaces
cgroup_namespaces (7) - overview of Linux cgroup namespaces
mount_namespaces (7) - overview of Linux mount namespaces
network_namespaces (7) - overview of Linux network namespaces
pid_namespaces (7)   - overview of Linux PID namespaces
user_namespaces (7)  - overview of Linux user namespaces
~~~

`man 7 namespaces`

### What is a namespace? ###

man 7 namespaces
    (...)
    A  namespace  wraps a global system resource in an abstraction that makes it appear to the processes within the namespace that they have their own isolated instance of the global resource.  Changes to the global resource are visible to other processes that are members of the namespace, but are invisible to other processes.  One use  of namespaces  is  to implement containers.
    (...)

Namespace resources are: Cgroup, IPC, Network, Mount, PID, User, UTS

### cgroup namespaces and their purpose ###

man cgroup_namespaces
(...)
       Among the purposes served by the virtualization provided by cgroup namespaces are the following:

       * It prevents information leaks whereby cgroup directory paths outside of a container would otherwise be visible to processes in the container.  Such leakages could, for example,
         reveal information about the container framework to containerized applications.

       * It eases tasks such as container migration.  The virtualization provided by cgroup namespaces allows containers to be isolated from  knowledge  of  the  pathnames  of  ancestor
         cgroups.  Without such isolation, the full cgroup pathnames (displayed in /proc/self/cgroups) would need to be replicated on the target system when migrating a container; those
         pathnames would also need to be unique, so that they don't conflict with other pathnames on the target system.

       * It allows better confinement of containerized processes, because it is possible to mount the container's cgroup filesystems such that the container processes can't gain  access
         to ancestor cgroup directories.  Consider, for example, the following scenario:

           · We have a cgroup directory, /cg/1, that is owned by user ID 9000.

           · We  have a process, X, also owned by user ID 9000, that is namespaced under the cgroup /cg/1/2 (i.e., X was placed in a new cgroup namespace via clone(2) or unshare(2) with
             the CLONE_NEWCGROUP flag).

         In the absence of cgroup namespacing, because the cgroup directory /cg/1 is owned (and writable) by UID 9000 and process X is also owned by user ID 9000, then process  X  would
         be able to modify the contents of cgroups files (i.e., change cgroup settings) not only in /cg/1/2 but also in the ancestor cgroup directory /cg/1.  Namespacing process X under
         the cgroup directory /cg/1/2, in combination with suitable mount operations for the cgroup filesystem (as shown above), prevents it modifying files in /cg/1,  since  it  cannot
         even  see the contents of that directory (or of further removed cgroup ancestor directories).  Combined with correct enforcement of hierarchical limits, this prevents process X
         from escaping the limits imposed by ancestor cgroups.
(...)

### network namespaces ###

~~~
man ip-netns
(...)
       A network namespace is logically another copy of the network stack, with its own routes, firewall rules, and network devices.

       By default a process inherits its network namespace from its parent. Initially all the processes share the same default network namespace from the init process.

       By convention a named network namespace is an object at /var/run/netns/NAME that can be opened. The file descriptor resulting from opening /var/run/netns/NAME refers to the spec‐
       ified network namespace. Holding that file descriptor open keeps the network namespace alive. The file descriptor can be used with the setns(2) system call to change the network
       namespace associated with a task.
(...)
~~~

Red Hat Enterprise Linux Atomis Host 7 Overview of Containers in Red Hat Systems:
~~~
Network namespaces provide isolation of network controllers, system resources associated
with networking, firewall and routing tables. This allows container to use separate virtual
network stack, loopback device and process space. You can add virtual or real devices to the
container, assign them their own IP Addresses and even full iptables rules. You can view the
different network settings by executing the ip addr command on the host and inside the
container.
~~~

~~~
ip netns add test
[akaris@wks-akaris blog]$ ls /var/run/netns/test 
/var/run/netns/test
[akaris@wks-akaris blog]$ ls /var/run/netns
test
[akaris@wks-akaris blog]$ 
~~~

~~~
[akaris@wks-akaris blog]$ sudo unshare -n  ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
~~~

Compare that to:
~~~
[akaris@wks-akaris blog]$ sudo unshare ip a ls dev lo
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
~~~

### mount_namespaces ###

~~~
man mount_namespaces
(...)
       Mount  namespaces  provide  isolation  of the list of mount points seen by the processes in each namespace instance.  Thus, the processes in each of the mount namespace instances
       will see distinct single-directory hierarchies.

       The views provided by the /proc/[pid]/mounts, /proc/[pid]/mountinfo, and /proc/[pid]/mountstats files (all described in proc(5)) correspond to the mount namespace  in  which  the
       process with the PID [pid] resides.  (All of the processes that reside in the same mount namespace will see the same view in these files.)

       When  a  process  creates a new mount namespace using clone(2) or unshare(2) with the CLONE_NEWNS flag, the mount point list for the new namespace is a copy of the caller's mount
       point list.  Subsequent modifications to the mount point list (mount(2) and umount(2)) in either mount namespace will not (by default) affect the mount point  list  seen  in  the
       other namespace (but see the following discussion of shared subtrees).
(...)
~~~

Red Hat Enterprise Linux Atomis Host 7 Overview of Containers in Red Hat Systems:
~~~
Mount namespaces isolate the set of file system mount points seen by a group of processes so
that processes in different mount namespaces can have different views of the file system
hierarchy. With mount namespaces, the mount() and umount() system calls cease to operate
on a global set of mount points (visible to all processes) and instead perform operations that
affect just the mount namespace associated with the container process. For example, each
container can have its own /tmp or /var directory or even have an entirely different
userspace.
~~~

### PID namespaces ###

~~~
man pid_namespaces
(...)
       PID  namespaces  isolate  the process ID number space, meaning that processes in different PID namespaces can have the same PID.  PID namespaces allow containers to provide func‐
       tionality such as suspending/resuming the set of processes in the container and migrating the container to a new host while the processes inside the container maintain  the  same
       PIDs.

       PIDs in a new PID namespace start at 1, somewhat like a standalone system, and calls to fork(2), vfork(2), or clone(2) will produce processes with PIDs that are unique within the
       namespace.
(...)
       The first process created in a new namespace (i.e., the process created using clone(2) with the CLONE_NEWPID flag, or the first child  created  by  a  process  after  a  call  to
       unshare(2)  using  the CLONE_NEWPID flag) has the PID 1, and is the "init" process for the namespace (see init(1)).  A child process that is orphaned within the namespace will be
       reparented to this process rather than init(1) (unless one of the ancestors of the child in the same PID namespace employed the prctl(2) PR_SET_CHILD_SUBREAPER  command  to  mark
       itself as the reaper of orphaned descendant processes).

       If  the  "init" process of a PID namespace terminates, the kernel terminates all of the processes in the namespace via a SIGKILL signal.  This behavior reflects the fact that the
       "init" process is essential for the correct operation of a PID namespace.  In this case, a subsequent fork(2) into this PID namespace fail with the error ENOMEM; it is not possi‐
       ble  to  create  a new processes in a PID namespace whose "init" process has terminated. 
(...)
~~~

Red Hat Enterprise Linux Atomis Host 7 Overview of Containers in Red Hat Systems:
~~~
PID namespaces allow processes in different containers to have the same PID, so each
container can have its own init (PID1) process that manages various system initialization tasks
as well as containers life cycle. Also, each container has its unique /proc directory. Note that
from within the container you can monitor only processes running inside this container. In
other words, the container is only aware of its native processes and can not "see" the
processes running in different parts of the system. On the other hand, the host operating
system is aware of processes running inside of the container, but assigns them different PID
numbers. For example, run the ps -eZ | grep systemd$ command on host to see all
instances of systemd including those running inside of containers.
~~~

~~~
[akaris@wks-akaris blog]$ sudo unshare -p --fork bash
[sudo] password for akaris: 
[root@wks-akaris blog]# echo $$
1
[root@wks-akaris blog]# echo $$
29
~~~

### user namespaces ###

~~~
man user_namespaces
(...)
       User  namespaces  isolate security-related identifiers and attributes, in particular, user IDs and group IDs (see credentials(7)), the root directory, keys (see keyrings(7)), and
       capabilities (see capabilities(7)).  A process's user and group IDs can be different inside and outside a user namespace.  In particular, a process can have a normal unprivileged
       user ID outside a user namespace while at the same time having a user ID of 0 inside the namespace; in other words, the process has full privileges for operations inside the user
       namespace, but is unprivileged for operations outside the namespace.
(...)
~~~

Red Hat Enterprise Linux Atomis Host 7 Overview of Containers in Red Hat Systems:
~~~
User namespaces are similar to PID
namespaces, they allow you to specify a range of host UIDs dedicated to the container. Consequently, a
process can have full root privileges for operations inside the container, and at the same time be
unprivileged for operations outside the container. For compatibility reasons, user namespaces are
turned off in the current version of Red Hat Enterprise Linux 7, but will be enabled in the near future.
~~~

### IPC namespaces ###

Red Hat Enterprise Linux Atomis Host 7 Overview of Containers in Red Hat Systems:
~~~
IPC namespaces isolate certain interprocess communication (IPC) resources, such as System
V IPC objects and POSIX message queues. This means that two containers can create shared
memory segments and semaphores with the same name, but are not able to interact with other
containers memory segments or shared memory.
~~~

### Listing namespaces ###

[akaris@wks-akaris ~]$ sudo lsns
[sudo] password for akaris: 
        NS TYPE   NPROCS   PID USER   COMMAND
4026531835 cgroup    275     1 root   /usr/lib/systemd/systemd --switched-root --system --deserialize 32
4026531836 pid       273     1 root   /usr/lib/systemd/systemd --switched-root --system --deserialize 32
4026531837 user      275     1 root   /usr/lib/systemd/systemd --switched-root --system --deserialize 32
4026531838 uts       275     1 root   /usr/lib/systemd/systemd --switched-root --system --deserialize 32
4026531839 ipc       275     1 root   /usr/lib/systemd/systemd --switched-root --system --deserialize 32
4026531840 mnt       266     1 root   /usr/lib/systemd/systemd --switched-root --system --deserialize 32
4026531860 mnt         1    33 root   kdevtmpfs
4026532008 net       274     1 root   /usr/lib/systemd/systemd --switched-root --system --deserialize 32
4026532186 mnt         1   791 root   /usr/lib/systemd/systemd-udevd
4026532445 net         1  1051 rtkit  /usr/libexec/rtkit-daemon
4026532508 mnt         1  1051 rtkit  /usr/libexec/rtkit-daemon
4026532509 mnt         1  1084 chrony /usr/sbin/chronyd
4026532510 mnt         1  1244 root   /usr/sbin/NetworkManager --no-daemon
4026532593 pid         2  4924 root   bash
4026532594 mnt         1  1335 colord /usr/libexec/colord
4026532677 mnt         1  2178 root   /usr/libexec/bluetooth/bluetoothd
4026532678 mnt         1  1800 root   /usr/libexec/boltd
4026532752 mnt         1  2751 root   /usr/libexec/fwupd/fwupd
~~~

For example, in CLI 1:
~~~
[akaris@wks-akaris ~]$ sudo lsns | grep net
4026532008 net       276     1 root   /usr/lib/systemd/systemd --switched-root --system --deserialize 32
~~~

In CLI 2:
~~~
4026532445 net         1  1051 rtkit  /usr/libexec/rtkit-daemon
[root@wks-akaris blog]# sudo ip netns add test2
[root@wks-akaris blog]# sudo ip netns exec test2 bash
/bin/basename: missing operand
Try '/bin/basename --help' for more information.
~~~

Again, in CLI 1:
~~~
[akaris@wks-akaris ~]$ sudo lsns | grep net
4026532008 net       277     1 root   /usr/lib/systemd/systemd --switched-root --system --deserialize 32
4026532445 net         1  1051 rtkit  /usr/libexec/rtkit-daemon
4026532607 net         1  5202 root   bash
~~~
