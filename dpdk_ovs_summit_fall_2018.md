### Summary ###
The summit was really interesting, but for somebody like me working more with the top-level OpenStack components many times lacked some high-level overview of what a specific talk was actually about. Understandably, the further up a presentation was on the stack, the easier it was for me to follow along with it. The OVS presentations, particularly of the first day, hence were far easier to follow than the DPDK presentations.

In this document, I annotate some of the presentations that seemed interesting **to me** with clarifying documents and quotes.

### DPDK summit ###

Agenda: [https://events.linuxfoundation.org/events/dpdknorthamerica2018/dpdk-na-program/agenda/](https://events.linuxfoundation.org/events/dpdknorthamerica2018/dpdk-na-program/agenda/)

#### SW Assisted vDPA for Live Migration - Xiao Wang, Intel ####

Presentation PDF: [https://schd.ws/hosted_files/dpdksummitnorthamerica2018/8f/XiaoWang-DPDK-US-Summit-SW-assisted-VDPA-for-LM-v2.pdf](https://schd.ws/hosted_files/dpdksummitnorthamerica2018/8f/XiaoWang-DPDK-US-Summit-SW-assisted-VDPA-for-LM-v2.pdf)
~~~
Key Takeaways
• VDPA combines SW Flex & HW Perf
• SW assisted VDPA could further simplify HW design
• A generic zero copy framework for all NICs with VDPA
~~~

##### What is vDPA? #####

vDPA: vhost Data Path Acceleration

Brand new patch to the kernel: [https://lwn.net/Articles/750770/](https://lwn.net/Articles/750770/)
~~~
This patch introduces a mdev (mediated device) based hardware
vhost backend. This backend is an abstraction of the various
hardware vhost accelerators (potentially any device that uses
virtio ring can be used as a vhost accelerator). Some generic
mdev parent ops are provided for accelerator drivers to support
generating mdev instances.
(...)
Difference between vDPA and PCI passthru
========================================

The key difference between vDPA and PCI passthru is that, in
vDPA only the data path of the device (e.g. DMA ring, notify
region and queue interrupt) is pass-throughed to the VM, the
device control path (e.g. PCI configuration space and MMIO
regions) is still defined and emulated by QEMU.

The benefits of keeping virtio device emulation in QEMU compared
with virtio device PCI passthru include (but not limit to):

- consistent device interface for guest OS in the VM;
- max flexibility on the hardware design, especially the
  accelerator for each vhost backend doesn't have to be a
  full PCI device;
- leveraging the existing virtio live-migration framework;
~~~

The important take-away is that we'll hopefully soon have a means to get the performance of SR-IOV with the flexibility of virtio, especially with regards to live-migration.

##### What is mdev? #####

mdev is "a common interface for mediated device management that can be used by drivers of different devices." and allows to "query and configure mediated devices in a hardware-agnostic fashion". The key point is that it's the hardware abstraction technology which enables vDPA.

[https://www.kernel.org/doc/Documentation/vfio-mediated-device.txt](https://www.kernel.org/doc/Documentation/vfio-mediated-device.txt)
~~~
Virtual Function I/O (VFIO) Mediated devices[1]
===============================================

The number of use cases for virtualizing DMA devices that do not have built-in
SR_IOV capability is increasing. Previously, to virtualize such devices,
developers had to create their own management interfaces and APIs, and then
integrate them with user space software. To simplify integration with user space
software, we have identified common requirements and a unified management
interface for such devices.

The VFIO driver framework provides unified APIs for direct device access. It is
an IOMMU/device-agnostic framework for exposing direct device access to user
space in a secure, IOMMU-protected environment. This framework is used for
multiple devices, such as GPUs, network adapters, and compute accelerators. With
direct device access, virtual machines or user space applications have direct
access to the physical device. This framework is reused for mediated devices.

The mediated core driver provides a common interface for mediated device
management that can be used by drivers of different devices. This module
provides a generic interface to perform these operations:

* Create and destroy a mediated device
* Add a mediated device to and remove it from a mediated bus driver
* Add a mediated device to and remove it from an IOMMU group
(...)
Mediated Device Management Interface Through sysfs
==================================================

The management interface through sysfs enables user space software, such as
libvirt, to query and configure mediated devices in a hardware-agnostic fashion.
This management interface provides flexibility to the underlying physical
device's driver to support features such as:

* Mediated device hot plug
* Multiple mediated devices in a single virtual machine
* Multiple mediated devices from different physical devices
(...)
~~~

#### Using nDPI over DPDK to Classify and Block Unwanted Network Traffic ####

#### Thread Quiescent State (TQS) Library - Honnappa Nagarahalli, Arm ####

#### A Hierarchical SW Load Balancing Solution for Cloud Deployment - Hongjun Ni, Intel #### 

#### DPDK Based L4 Load Balancer - M Jayakumar, Intel ####

#### Accelerating Telco NFV Deployments with DPDK and Smart NIC - Kalimani Venkatesan Govindarajan, Aricent & Barak Perlman , Ethernity Network ####

##### What is a vBNG ####
virtual Broadband Network Gateway
~~~
A broadband remote access server (BRAS, B-RAS or BBRAS) routes traffic to and from broadband remote access devices such as digital subscriber line access multiplexers (DSLAM) on an Internet service provider's (ISP) network.[1][2] BRAS can also be referred to as a Broadband Network Gateway (BNG).[3]

The BRAS sits at the edge of an ISP's core network, and aggregates user sessions from the access network. It is at the BRAS that an ISP can inject policy management and IP Quality of Service (QoS). 
(...)
By acting as the network termination point, the BRAS is responsible for assigning network parameters such as IP addresses to the clients. The BRAS is also the first IP hop from the client to the Internet.
~~~
[https://en.wikipedia.org/wiki/Broadband_remote_access_server](https://en.wikipedia.org/wiki/Broadband_remote_access_server)

#### NFF-Go: Bringing DPDK to the Cloud - Areg Melik-Adamyan, Intel #####

#### Enabing P4 in DPDK - Cristian Dumitrescu, Intel & Antonin Bas, Barefoot Networks | Accelerating DPDK via P4-programmable FPGA-based Smart NICs - Petr Kastovsky, Netcope Technologies ####

##### P4 #####

Website: [http://www.p4.org](http://www.p4.org)

P4 is a high-level, imperative, domain specific language. As an Open Source project, it intends to be protocol and device independent. The default file extension is `.p4`.
Source: `p4-tutorial.pdf`

Backend targets of P4 are software switches, NICs, packet processors, FPGAS, GPUS, ASICs, etc. Because it is a high-level language, it prevents vendor lockin. 

P4 allows to easily program the dataplane of Smartnics. P4 is not intended to implement the control plane.
Source: `p4-tutorial.pdf`
Source: `file:///home/akaris/blog/dpdksummit/P4%20(programming%20language)%20-%20Wikipedia.html`

P4 syntax is similar to python, however on purpose the language is not Turing complete. P4 can easily be translated into a JSON representation.

Runtime changes to the device's configuration are possible.

P4 is protocol independent, meaning that the programmer needs to define header fields for any protocol, such as VLAN or TCP.
Source: `file:///home/akaris/blog/dpdksummit/P4%20(programming%20language)%20-%20Wikipedia.html`

#### RTE_FLOW ####
[https://doc.dpdk.org/guides/prog_guide/rte_flow.html](https://doc.dpdk.org/guides/prog_guide/rte_flow.html)


#### DPDK Tunnel Offloading  - Yongseok Koh & Rony Efraim, Mellanox ####

#### DPDK on F5 BIG-IP Virtual ADCs - Brent Blood, F5 Networks ####

#### Arm’s Efforts for DPDK and Optimization Plan - Gavin Hu & Honnappa Nagarahalli, Arm ####

#### DPDK Flow Classification and Traffic Profiling & Measurement  - Ren Wang & Yipeng Wang, Intel Labs ####

#### Projects using DPDK - Stephen Hemminger, Microsoft ####

#### DPDK Open Lab Performance Continious Integration - Jeremy Plsek, University of New Hampshire InterOperability Laboratory ####

#### Fast Prototyping DPDK Apps in Containernet - Andrew Wang, Comcast ####

#### Implementing DPDK Based Application Container Framework with SPP - Yasufumi Ogawa, NTT ####

#### Shaping the Future of IP Broadcasting with Cisco's vMI and DPDK on Windows - Harini Ramakrishnan, Microsoft & Michael O'Gorman, Cisco ####

#### Improving Security and Flexibility within Windows DPDK Networking Stacks - Ranjit Menon, Intel Corporation & Omar Cardona, Microsoft ####

#### Use DPDK to Accelerate Data Compression for Storage Applications - Fiona Trahe & Paul Luse, Intel ####

#### Fine-grained Device Infrastructure for Network I/O Slicing in DPDK - Cunming Liang & John Mangan, Intel ####

#### Embracing Externally Allocated Memory - Yongseok Koh, Mellanox ####

#### Accelerating DPDK Para-Virtual I/O with DMA Copy Offload Engine - Jiayu Hu, Intel ####

#### Revise 4K Pages Performance Impact for DPDK Applications - Lei Yao & Jiayu Hu, Intel ####

#### DPDK IPsec Library - Declan Doherty, Intel ####

#### Tungsten Fabric Performance Optimization by DPDK - Lei Yao, Intel ####

#### DPDK Based Vswitch Upgrade - Yuanhan Liu, Tencent ####

#### Using New DPDK Port Representor by Switch Application like OVS - Rony Efraim, Mellanox ####

### OVS summit ###

[http://www.openvswitch.org/support/ovscon2018/](http://www.openvswitch.org/support/ovscon2018/)

#### Running OVS-DPDK Without Hugepages, Busy Loop, and Exclusive Cores (Yi Yang, Inspur) 	####
#### Enabling TSO in OvS-DPDK (Tiago Lam, Intel) 	####
#### OVS-DPDK Memory Management and Debugging (Kevin Traynor, Red Hat, and Ian Stokes, Intel) 	####
#### Empowering OVS with eBPF (Yi-Hung Wei, William Tu, and Yifeng Sun, VMware) 	####
#### Open vSwitch Extensions with BPF (Paul Chaignon, Orange Labs) 	####
#### Fast Userspace OVS with AF_XDP (William Tu, VMware) ####
#### OVS with DPDK Community Update (Ian Stokes, Intel) 	####
#### Why use DPDK LTS? (Kevin Traynor, Red Hat) ####
#### Flow Monitoring in OVS (Ashish Varma, VMware) ####
#### OVS and PVP testing (Eelco Chaudron, Red Hat) ####
#### Testing the Performance Impact of the Exact Match Cache (Andrew Theurer, Red Hat) ####
#### Applying SIMD Optimizations to the OVS Datapath Classifier (Harry van Haaren, Intel) 	####
#### PMD Auto Load Balancing (Nitin Katiyar, Jan Scheurich, and Venkatesan Pradeep, Ericsson) 	####
#### All or Nothing: The Challenge of Hardware Offload (Dan Daly, Intel) 	####
#### Reprogrammable Packet Processing Pipeline in FPGA for OVS Offloading (Debashis Chatterjee, Intel) ####
#### Offloading Linux LAG Devices Via Open vSwitch and TC (John Hurley, Netronome) ####
#### Connection Tracing Hardware Offload via TC (Rony Efraim, Yossi Kuperman, and Guy Shattah, Mellanox) ####
#### Bleep bloop! A robot workshop. (Aaron Conole, Red Hat) 	####
#### Comparison Between OVS and Tungsten Fabric vRouter (Yi Yang, Inspur) 	####
#### The Discrepancy of the Megaflow Cache in OVS (Levente Csikor and Gabor Retvari, Budapest University of Technology and Economics) 	####
#### Elmo: Source-Routed Multicast for Public Clouds (Muhammad Shahbaz, Stanford) 	####
#### Sangfor Cloud Security Pool, The First-Ever NSH Use Case in Service Function Chaining Product (XiaoFan Chen, Sangfor and Yi Yang, Inspur) 	####
#### Answering the Open Questions About an OVN/OVS Split (Mark Michelson, Red Hat) 	####
#### OVN performance: past, present, and future (Mark Michelson, Red Hat) ####
#### Unencapsulated OVN: What we have and what we want (Mark Michelson, Red Hat) 	####
#### Connectivity for External Networks on the Overlay (Gregory A Smith, Nutanix) 	####
#### Active-Active load balancing with liveness detection through OVN forwarding group (Manoj Sharma, Nutanix) 	PPTX 	Video
#### Debugging OVS with GDB (macros) (Eelco Chaudron, Red Hat) ####
#### OVN Controller Incremental Processing (Han Zhou, eBay) 	####
#### OVN DBs HA with Scale Test (Aliasgar Ginwala, eBay) 	####
#### Distributed Virtual Routing for VLAN Backed Networks Through OVN (Ankur Sharma, Nutanix) ####
#### Policy-Based Routing in OVS (Mary Manohar, Nutanix) ####
#### Encrypting OVN Tunnels with IPSEC (Qiuyu Xiao, University of North Carolina at Chapel Hill) 	####
#### Windows Community Updates on OVS and OVN (Ionut-Madalin Balutoiu, Cloudbase, and Anand Kumar and Sairam Venugopal, VMware)  ####
