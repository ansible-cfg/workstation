#!/bin/bash

set -e

CERT_FOLDER=/home/fedora/opt/kubernetes/certs

mkdir -p $CERT_FOLDER
cd $CERT_FOLDER

# Generate CAs

for prefix in kube
do
    mkdir -p $prefix
    
    openssl genrsa -out $prefix/$prefix.key 2048
    
    openssl req -x509 -new -nodes -key $prefix/$prefix.key -sha256 -days 3650 -out $prefix/$prefix.pem -subj "/C=DE/ST=BW/CN=$prefix"

    certutil -d sql:$HOME/.pki/nssdb -D -n $prefix || echo "Cert does not exist"
    certutil -d sql:$HOME/.pki/nssdb -A -t "CT,," -n $prefix -i $CERT_FOLDER/$prefix/$prefix.pem
done

certutil -d sql:$HOME/.pki/nssdb -L

# Generate Cert

CN=kubernetes-dashboard
CA=kube

cd kube

## Generate Private Key
openssl genrsa -out ${CN}.key 2048

## Generate Certificate Signing Request (CSR)
cat << EOF > ${CN}.conf
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn
[ dn ]
C=DE
ST=BW
CN = minikube.infra
[ req_ext ]
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = localhosts
DNS.2 = kubernetes-dashboard
DNS.3 = minikube
DNS.4 = minikube.infra
IP.1 = 10.0.2.15
IP.2 = 127.0.0.1
EOF

openssl req -new -key ${CN}.key -out ${CN}.csr -config ${CN}.conf

# Show CSR Content
openssl req -text -noout -in ${CN}.csr   

# Sign CSR and thereby create the Certificate
openssl x509 -req -in ${CN}.csr -CA ${CA}.pem -CAkey ${CA}.key -CAcreateserial -out ${CN}.crt -days 11499 -sha256 -extensions req_ext -extfile ${CN}.conf
