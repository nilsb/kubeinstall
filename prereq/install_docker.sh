#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ -z $1 ]; then
  echo "Missing non root user parameter"
  exit 0
fi

#Install docker-ce
echo "**********************************************" >>../prereq.log
echo "***            Install Docker-ce           ***" >>../prereq.log
echo "**********************************************" >>../prereq.log
echo "..Installing docker-ce"
apt-get update >>../prereq.log 2>&1

echo "...Installing docker dependencies"
apt-get install -y apt-transport-https ca-certificates curl software-properties-common golang rpcbind glusterfs-client >>../prereq.log 2>&1

echo "...Adding docker gpg key and repository"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable" >>../prereq.log 2>&1
apt-cache policy docker-ce >>../prereq.log 2>&1
apt-get update >>../prereq.log 2>&1

echo "...Removing older versions"
systemctl stop docker >>../prereq.log 2>&1
systemctl disable docker >>../prereq.log 2>&1
systemctl daemon-reload >>../prereq.log 2>&1
rm -rf /lib/systemd/system/docker.service
apt-get purge -y docker docker-engine docker.io docker-ce >>../prereq.log 2>&1
apt-get autoremove -y --purge docker docker-engine docker.io docker-ce >>../prereq.log 2>&1
rm -rf /var/lib/containerd >>../prereq.log 2>&1
rm -rf /var/lib/docker >>../prereq.log 2>&1
rm -rf /etc/docker >>../prereq.log 2>&1
rm -rf /etc/apparmor-d/docker >>../prereq.log 2>&1
rm -rf /var/run/docker.sock >>../prereq.log 2>&1
groupdel docker >>../prereq.log 2>&1

echo "...Installing"
apt-get install -y docker-ce >>../prereq.log 2>&1

echo "...Add docker group"
groupadd docker >>../prereq.log 2>&1

echo "...Add logged on user to docker group"
usermod -aG docker $1
echo "...Add root user to docker group"
usermod -aG docker root

echo "...Set cgroupdriver of docker"
if ! $(grep -q "native.cgroupdriver" "/lib/systemd/system/docker.service"); then
systemctl stop docker >>../prereq.log 2>&1
  if [ -f /var/run/docker/docker.sock ]; then
    rm /var/run/docker/docker.sock
  fi
sed -i 's+ExecStart=/usr/bin/dockerd+ExecStart=/usr/bin/dockerd --exec-opt native.cgroupdriver=systemd +g' /lib/systemd/system/docker.service
systemctl daemon-reload >>../prereq.log 2>&1
systemctl enable docker >>../prereq.log 2>&1
systemctl start docker >>../prereq.log 2>&1
fi

echo "...Set cgroupdriver enabled for containerd"
systemctl stop containerd >>../prereq.log 2>&1
if ! $(grep -q "systemd_cgroup = true" "/etc/containerd/config.toml"); then
containerd config default | tee /etc/containerd/config.toml
sed -i 's+systemd_cgroup = false+systemd_cgroup = true+g' /etc/containerd/config.toml
systemctl enable containerd >>../prereq.log 2>&1
systemctl start containerd >>../prereq.log 2>&1
fi

echo "...Restart docker"
  systemctl start docker >>../prereq.log 2>&1
if curl -s --unix-socket /var/run/docker.sock http/_ping 2>&1 >/dev/null
then
  echo "....Running"
else
  echo "....There was an error starting docker"
fi

echo "" >>../prereq.log
echo "" >>../prereq.log
