#!/bin/bash
# Usage: ./virt-customize.sh fedora.qcow2 fedora-clone.qcow2 30G

BASE=$1
CLONE=$2
SIZE=$3

cp $BASE $CLONE
qemu-img resize $CLONE +${SIZE}

virt-customize -a $CLONE --run-command 'sed -i -e "s/PasswordAuthentication no/PasswordAuthentication yes/g"  /etc/ssh/sshd_config'
virt-customize -a $CLONE --run-command 'yum remove cloud-init* -y'
virt-customize -a $CLONE --root-password password:password
