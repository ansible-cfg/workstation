#!/bin/bash

set -e

## fix for nodeports
sudo sed -i 's/::1/#::1/g' /etc/hosts
sudo echo "127.0.0.1 minikube" | sudo tee -a /etc/hosts

# Disable selinux temporarily
#sudo setenforce 0
# Disable selinux permanently
sudo sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux

cat <<EOF >  /tmp/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo mv /tmp/k8s.conf /etc/sysctl.d/k8s.conf
sudo sysctl --system

# Disable swap for now (permanently doesn't work immediately (?))
sudo swapoff -a
# Disable swap permanently
if [ ! -f /etc/fstab.bak ]; then
    sudo cp /etc/fstab /etc/fstab.bak
fi
sudo sed -i 's/\/swapfile/#\/swapfile/g' /etc/fstab
