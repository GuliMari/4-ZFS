#!/bin/bash

sudo yum install -y yum-utils
sudo yum install -y https://zfsonlinux.org/epel/zfs-release-2-2$(rpm --eval "%{dist}").noarch.rpm
yum-config-manager --disable zfs
yum-config-manager --enable zfs-kmod
yum install -y zfs
modprobe zfs
yum install -y wget