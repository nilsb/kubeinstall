#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#Make sure IPTABLES can see bridged traffic
echo "..Making sure IPTABLES can see bridged traffic"
echo "**********************************************" >../prereq.log
echo "*** Enable IPTABLES to see bridged traffic ***" >>../prereq.log
echo "**********************************************" >>../prereq.log
tee /etc/modules-load.d/k8s.conf >>../prereq.log 2>&1 <<EOF
br_netfilter
EOF

tee /etc/sysctl.d/k8s.conf >>../prereq.log 2>&1 <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system >>../prereq.log 2>&1

echo "" >>../prereq.log
echo "" >>../prereq.log
