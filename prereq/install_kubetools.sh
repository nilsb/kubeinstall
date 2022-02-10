#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

echo "..Installing kubeadm, kubelet, kubectl and etcd-server"
echo "**********************************************" >>../prereq.log
echo "***   Install kubernetes bootstrap tools   ***" >>../prereq.log
echo "**********************************************" >>../prereq.log
echo "...Removing old versions"
rm -rf /var/lib/etcd >>../prereq.log 2>&1
rm -rf /etc/kubernetes >>../prereq.log 2>&1
rm -rf /etc/default/etcd >>../prereq.log 2>&1

#Install kubeadm, kubelet, kubectl and etcd
echo "...Installing new versions"
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" > /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update >>../prereq.log 2>&1
apt-get install -y kubelet kubeadm kubectl helm >>../prereq.log 2>&1
apt-mark hold kubelet kubeadm kubectl >>../prereq.log 2>&1
systemctl enable kubelet >>../prereq.log 2>&1
echo "...Adding basic helm repos"
helm repo add bitnami https://charts.bitnami.com/bitnami >>../prereq.log 2>&1
helm repo add cilium https://helm.cilium.io/ >>../prereq.log 2>&1
helm repo update >>../prereq.log 2>&1

echo "" >>../prereq.log
echo "" >>../prereq.log
