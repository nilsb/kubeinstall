#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ -z $1 ]
  then echo "Missing nonroot user"
  exit 0
fi

NONROOT=$1

echo "Installing kubernetes controlplane"
echo -n "Please enter kubernetes cluster name: "
read CLUSTERNAME
echo -n "Please enter ip address of controlplane: "
read INTERNAL_IP
#echo -n "Please enter hostname of controlplane: "
#read NAME
echo -n "Please enter the name of your organization: "
read ORGNAME
echo -n "Please enter the two charcter country code for certificates: "
read COUNTRY
echo -n "What are you installing? (controlplane/node):"
read TYPE

if ! [[ ${TYPE}="controlplane" || ${TYPE}="node" ]]
then
  echo "Type of install must be controlplane or node"
  exit 0
fi

echo ""
NAME=${HOSTNAME}
echo ".Installing prerequisites"
PREREQ=""
cd prereq
./enable_bridged_traffic.sh
./disable_swap.sh
apt-get upgrade -y >>./prereq.log 2>&1
./install_docker.sh ${NONROOT}
./install_kubetools.sh
./verify.sh
source "./checks.log"
cd ..

if [[ ${TYPE}="controlplane" && ${PREREQ}=1 ]]; then
echo ".Installing etcd server"
cd etcd
./cert.sh ${INTERNAL_IP} ${NAME} ${ORGNAME} ${COUNTRY}
./install.sh ${INTERNAL_IP}
cd ..

echo ".Installing controlplane"
./controlplane.sh ${INTERNAL_IP} ${NAME} ${CLUSTERNAME}
fi
