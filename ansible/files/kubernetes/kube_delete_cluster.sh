#!/bin/bash

function log {
  message=$1
  white=$(tput setaf 7)
  normal=$(tput sgr0)
  printf "\n###\n# %s\n###\n\n" "${white}${message}${normal}"
}


set -e


log "Deleting Kubernetes Cluster"
START_TIME=$SECONDS


sudo rm -rf /tmp/kubeadmin.log


# reset both because we don't know what is currently running
# with Docker
log "kubeadm reset (with docker)"
sudo kubeadm reset | tee /tmp/kubeadmin.log
# with CRIO
log "kubeadm reset (with crio)"
sudo kubeadm reset --cri-socket=/var/run/crio/crio.sock | tee /tmp/kubeadmin.log


ELAPSED_TIME=$(($SECONDS - $START_TIME))
log "Deleting Kubernetes Cluster took $ELAPSED_TIME seconds"