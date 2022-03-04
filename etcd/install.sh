#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [[ -z $1 ]]; then
  echo "..Error getting local ip"
  exit 0
fi

INTERNAL_IP=$1

echo "..Installing etcd"
echo "...Create Workdir"
mkdir -p /var/lib/etcd >>../etcd.log 2>&1
chmod -R 700 /var/lib/etcd >>../etcd.log 2>&1
chown -R etcd /var/lib/etcd >>../etcd.log 2>&1
chgrp -R etcd /var/lib/etcd >>../etcd.log 2>&1

echo "...Set certificate paths"
tee /lib/systemd/system/etcd.service >>../etcd.log 2>&1 <<EOF
[Unit]
Description=etcd - highly-available key value store
Documentation=https://github.com/coreos/etcd
Documentation=man:etcd
After=network.target
Wants=network-online.target

[Service]
User=etcd
Environment=DAEMON_ARGS=
Environment=ETCD_NAME=%H
EnvironmentFile=-/etc/default/%p
Type=notify
ExecStart=/bin/etcd $DAEMON_ARGS \\
  --cert-file=/etc/kubernetes/pki/apiserver-etcd-client.crt \\
  --key-file=/etc/kubernetes/pki/apiserver-etcd-client.key \\
  --peer-cert-file=/etc/kubernetes/pki/apiserver-etcd-client.crt \\
  --peer-key-file=/etc/kubernetes/pki/apiserver-etcd-client.key \\
  --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --data-dir=/var/lib/etcd
PermissionsStartOnly=true
Restart=on-abnormal
#RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
Alias=etcd2.service
EOF

echo "...Reload and restart service"
systemctl daemon-reload >>../etcd.log 2>&1
systemctl restart etcd >>../etcd.log 2>&1
systemctl restart kubelet >>../etcd.log 2>&1
