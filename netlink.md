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
