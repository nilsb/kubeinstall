#!/bin/bash

NONROOT=${USER}
echo -e "Please run \n sudo apt autoremove -y --purge docker-ce docker docker.io etcd-server kubeadm kubelet kubectl helm glusterfs-client --allow-change-held-packages \n and reboot before running this script again."

sudo -s ./main.sh ${NONROOT}
