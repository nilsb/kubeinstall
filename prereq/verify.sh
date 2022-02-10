echo ".Verifying prerequisites"

echo -n "..Checking if bridged traffic is enabled"
if $(grep -q "br_netfilter" "/etc/modules-load.d/k8s.conf"); then
  if $(grep -q "net.bridge.bridge-nf-call-iptables = 1" "/etc/sysctl.d/k8s.conf"); then
    echo -e ": \e[1;32mverified\033[0m"
    echo "BRIDGED_TRAFFIC=1" >./checks.log
  else
    echo -e ": \e[1;31mfailed!\033[0m"
    echo "BRIDGED_TRAFFIC=0" >./checks.log
  fi
else
  echo -e ": \e[1;31mfailed!\033[0m"
    echo "BRIDGED_TRAFFIC=0" >./checks.log
fi

echo -n "..Checking if swap is disabled"
if $(grep -q "#/swap.img" "/etc/fstab"); then
  echo -e ": \e[1;32mverified\033[0m"
  echo "SWAP=1" >>./checks.log
else
  echo -e ": \e[1;31mfailed!\033[0m"
  echo "SWAP=0" >>./checks.log
fi

echo -n "..Verifying docker install"
if $(docker -v | grep -q "Docker version"); then
  echo -e ": \e[1;32mverified\033[0m"
  echo "DOCKER=1" >>./checks.log
else
  echo -e ": \e[1;31mfailed!\033[0m"
  echo "DOCKER=0" >>./checks.log
fi

echo -n "..Verifying cgroupdriver"
if $(grep -q "cgroupdriver=systemd" "/lib/systemd/system/docker.service"); then
  if $(grep -q "systemd_cgroup = true" "/etc/containerd/config.toml"); then
    echo -e " (systemd): \e[1;32mverified\033[0m"
    echo "CGROUP=1" >>./checks.log
  else
    echo -e ": \e[1;31mfailed!\033[0m"
    echo "CGROUP=0" >>./checks.log
  fi
else
  echo -e ": \e[1;31mfailed!\033[0m"
    echo "CGROUP=0" >>./checks.log
fi

echo -n "..Verifying that kubeadm is installed"
if $(kubeadm version | grep -q "kubeadm version"); then
  echo -e ": \e[1;32mverified\033[0m"
  echo "KUBEADM=1" >>./checks.log
else
  echo -e ": \e[1;31mfailed!\033[0m"
  echo "KUBEADM=0" >>./checks.log
fi

if [[ ${BRIDGED_TRAFFIC}=1 && ${SWAP}=1 && ${DOCKER}=1 && ${CGROUP}=1 && ${KUBEADM}=1 ]]
then
  echo "PREREQ=1" >>./checks.log
else
  echo "PREREQ=0" >>./checks.log
fi
