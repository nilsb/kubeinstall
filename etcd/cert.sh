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
  echo "..Error getting organization name"
  exit 0
fi

if [[ -z $4 ]]; then
  echo "..Error getting country code"
  exit 0
fi

#Generate etcd ca certificates
echo "..Generate etcd certifiates"
echo "...Generate ca certificates"
kubeadm init phase certs all >>../etcd.log 2>&1

echo "...Set temporary permissions for certificate folders"
chmod -R o+rw /etc/kubernetes/pki >>../etcd.log 2>&1

INTERNAL_IP=$1
NAME=$2
ORGNAME=$3
COUNTRY=$4
ROOT="$(pwd)"
PASSFILE="${ROOT}/dev.password"
PASSOPT="file:${ROOT}/dev.password"
CAFILE="/etc/kubernetes/pki/etcd/ca.crt"
CAKEY="/etc/kubernetes/pki/etcd/ca.key"

echo "...Remove old request files"
rm -rf ${PASSFILE}
rm -rf ${ROOT}/ca.srl
rm -rf ${ROOT}/openssl-${NAME}.cnf
rm -rf ${ROOT}/${NAME}-req.csr${ROOT}/${NAME}-req.csr

echo "...Create client request configuration file"
cat <<EOF > ${ROOT}/openssl-${NAME}.cnf
[req]
default_bits  = 2048
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
countryName = ${COUNTRY}
stateOrProvinceName = N/A
localityName = Kubernetes
organizationalUnitName = ${NAME}
organizationName = ${ORGNAME}
commonName = ${NAME}
[req_ext]
subjectAltName = @alt_names
[v3_req]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
extendedKeyUsage = clientAuth,serverAuth
subjectAltName = @alt_names
[alt_names]
IP.1 = 127.0.0.1
IP.2 = ${INTERNAL_IP}
EOF

echo "...Create passfile"
if [ ! -f "${PASSFILE}" ]; then
  touch ${PASSFILE}
  chmod 600 ${PASSFILE}
  # "If the same pathname argument is supplied to -passin and -passout arguments then the first
  # line will be used for the input password and the next line for the output password."
  cat /dev/random | head -c 128 | base64 | sed -n '{p;p;}' >> ${PASSFILE}
fi

SERIALOPT=""
echo "...Create ca.srl"
if [ ! -f "${ROOT}/ca.srl" ]; then
  SERIALOPT="-CAcreateserial"
else
  SERIALOPT="-CAserial ${ROOT}/ca.srl"
fi

echo "...Create client certifiate key"
openssl genrsa -des3 \
    -passout ${PASSOPT} \
    -out /etc/kubernetes/pki/apiserver-etcd-client.key 2048  >>../etcd.log 2>&1

echo "...Create client certificate request"
openssl req -subj "/CN=${NAME}" -new \
    -batch \
    -passin ${PASSOPT} \
    -key /etc/kubernetes/pki/apiserver-etcd-client.key \
    -passout ${PASSOPT} \
    -out ${ROOT}/${NAME}-req.csr \
    -config ${ROOT}/openssl-${NAME}.cnf >>../etcd.log 2>&1

echo "...Create client certificate file"
openssl x509 -req -days 7300 \
    -passin ${PASSOPT} \
    -in ${ROOT}/${NAME}-req.csr \
    -CA ${CAFILE} \
    -CAkey ${CAKEY} \
    ${SERIALOPT} \
    -extensions v3_req \
    -extfile ${ROOT}/openssl-${NAME}.cnf \
    -out /etc/kubernetes/pki/apiserver-etcd-client.crt >>../etcd.log 2>&1

echo "...Remove passfile from key"
openssl rsa \
    -passin ${PASSOPT} \
    -in /etc/kubernetes/pki/apiserver-etcd-client.key \
    -out /etc/kubernetes/pki/apiserver-etcd-client.key >>../etcd.log 2>&1

echo "...Set permissions for certificate folders"
chmod -R o-w /etc/kubernetes/pki >>../etcd.log 2>&1
