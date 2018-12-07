### Summary ###
The summit was really interesting, but for somebody like me working more with the top-level OpenStack components many times lacked some high-level overview of what a specific talk was actually about. Understandably, the further up a presentation was on the stack, the easier it was for me to follow along with it. The OVS presentations, particularly of the first day, hence were far easier to follow than the DPDK presentations.

In this document, I annotate some of the presentations that seemed interesting **to me** with clarifying documents and quotes.

### DPDK summit ###

Agenda: [https://events.linuxfoundation.org/events/dpdknorthamerica2018/dpdk-na-program/agenda/](https://events.linuxfoundation.org/events/dpdknorthamerica2018/dpdk-na-program/agenda/)

#### SW Assisted vDPA for Live Migration - Xiao Wang, Intel ####

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

#### NFF-Go: Bringing DPDK to the Cloud - Areg Melik-Adamyan, Intel #####

#### Enabing P4 in DPDK - Cristian Dumitrescu, Intel & Antonin Bas, Barefoot Networks #### 

#### Accelerating DPDK via P4-programmable FPGA-based Smart NICs - Petr Kastovsky, Netcope Technologies ####

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
