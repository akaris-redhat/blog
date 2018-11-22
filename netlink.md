### Resources ###
[https://en.wikipedia.org/wiki/Netlink](https://en.wikipedia.org/wiki/Netlink)
[https://tools.ietf.org/html/rfc3549](https://tools.ietf.org/html/rfc3549)

### What is Netlink? ###
A means to exchange networking information between kernel and userspace:
~~~
The Netlink socket family is a Linux kernel interface used for inter-process communication (IPC) between both the kernel and userspace processes, and between different userspace processes, in a way similar to the Unix domain sockets. Similarly to the Unix domain sockets, and unlike INET sockets, Netlink communication cannot traverse host boundaries. However, while the Unix domain sockets use the file system namespace, Netlink processes are usually addressed by process identifiers (PIDs). [3]

Netlink is designed and used for transferring miscellaneous networking information between the kernel space and userspace processes. Networking utilities, such as the iproute2 family and the utilities used for configuring mac80211-based wireless drivers, use Netlink to communicate with the Linux kernel from userspace. Netlink provides a standard socket-based interface for userspace processes, and a kernel-side API for internal use by kernel modules. Originally, Netlink used the AF_NETLINK socket family. 
~~~
[https://en.wikipedia.org/wiki/Netlink](https://en.wikipedia.org/wiki/Netlink)

Netlink is defined and thoroughly described in [RFC3549](https://tools.ietf.org/html/rfc3549)

### Who uses Netlink? Examples ###

Just a few examples:
* iproute2 
~~~
[root@dell-r430-30 ~]# strace -e trace=network /usr/sbin/ip route
socket(AF_NETLINK, SOCK_RAW|SOCK_CLOEXEC, NETLINK_ROUTE) = 3
setsockopt(3, SOL_SOCKET, SO_SNDBUF, [32768], 4) = 0
setsockopt(3, SOL_SOCKET, SO_RCVBUF, [1048576], 4) = 0
bind(3, {sa_family=AF_NETLINK, pid=0, groups=00000000}, 12) = 0
getsockname(3, {sa_family=AF_NETLINK, pid=161345, groups=00000000}, [12]) = 0
sendto(3, "(\0\0\0\32\0\1\3\330A\367[\0\0\0\0\2\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"..., 40, 0, NULL, 0) = 40
recvmsg(3, {msg_name(12)={sa_family=AF_NETLINK, pid=0, groups=00000000}, msg_iov(1)=[{"4\0\0\0\30\0\2\0\330A\367[Av\2\0\2\0\0\0\376\3\0\1\0\0\0\0\10\0\17\0"..., 32768}], msg_controllen=0, msg_flags=0}, 0) = 1312
socket(AF_LOCAL, SOCK_DGRAM|SOCK_CLOEXEC, 0) = 4
default via 10.10.99.254 dev br-redhat 
socket(AF_LOCAL, SOCK_DGRAM|SOCK_CLOEXEC, 0) = 4
10.10.96.0/22 dev br-redhat proto kernel scope link src 10.10.96.194 
socket(AF_LOCAL, SOCK_DGRAM|SOCK_CLOEXEC, 0) = 4
169.254.0.0/16 dev br-redhat scope link metric 1008 
socket(AF_LOCAL, SOCK_DGRAM|SOCK_CLOEXEC, 0) = 4
169.254.0.0/16 dev br-provis scope link metric 1009 
socket(AF_LOCAL, SOCK_DGRAM|SOCK_CLOEXEC, 0) = 4
169.254.0.0/16 dev br-trunk1 scope link metric 1010 
socket(AF_LOCAL, SOCK_DGRAM|SOCK_CLOEXEC, 0) = 4
169.254.0.0/16 dev br-stonith scope link metric 1011 
socket(AF_LOCAL, SOCK_DGRAM|SOCK_CLOEXEC, 0) = 4
169.254.0.0/16 dev br-trunk2 scope link metric 1012 
socket(AF_LOCAL, SOCK_DGRAM|SOCK_CLOEXEC, 0) = 4
192.168.111.0/24 dev br-stonith proto kernel scope link src 192.168.111.1 
socket(AF_LOCAL, SOCK_DGRAM|SOCK_CLOEXEC, 0) = 4
192.168.122.0/24 dev virbr0 proto kernel scope link src 192.168.122.1 
recvmsg(3, {msg_name(12)={sa_family=AF_NETLINK, pid=0, groups=00000000}, msg_iov(1)=[{"\24\0\0\0\3\0\2\0\330A\367[Av\2\0\0\0\0\0", 32768}], msg_controllen=0, msg_flags=0}, 0) = 20
+++ exited with 0 +++
~~~

* OVS

### How to use Netlink - programming example ###
