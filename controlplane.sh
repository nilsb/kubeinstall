#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [[ -z $1 ]]; then
  echo "..Error getting local ip"
  exit 0
fi

if [[ -z $2 ]]; then
  echo "..Error getting hostname"
  exit 0
fi

if [[ -z $3 ]]; then
  echo "..Error getting name of cluster"
  exit 0
fi

#Create kubeadm config
INTERNAL_IP=$1
NAME=$2
CLUSTERNAME=$3

echo "..Install kubernetes bootstrap tools"
echo "...Create kubeadm config"
tee ~/kubeadm-config.yaml >./controlplane.log 2>&1 <<EOF
# kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v1.23.0
networking:
  serviceSubnet: "10.96.0.0/16"
  dnsDomain: "cluster.local"
clusterName: ${CLUSTERNAME}
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${INTERNAL_IP}
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  imagePullPolicy: IfNotPresent
  name: ${NAME}
  taints: null
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF

echo "...Init kubernetes controlplane"
kubeadm init --config ~/kubeadm-config.yaml

echo "...Set config file for kubectl"
mkdir -p $HOME/.kube >>./controlplane.log 2>&1
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config >>./controlplane.log 2>&1
chown $(id -u):$(id -g) $HOME/.kube/config >>./controlplane.log 2>&1
