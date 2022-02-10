# kubeinstall
Facilitate install and bootstrap of kubernetes using kubeadm

On controlplane run install.sh

On worker nodes you need to manually run prerequisite scripts in the following order:
enable_bridged_traffic.sh
disable_swap.sh
install_docker.sh
install_kubetools.sh
verify.sh

make sure the docker daemon is running before you run kubeadm join on the worker nodes.
