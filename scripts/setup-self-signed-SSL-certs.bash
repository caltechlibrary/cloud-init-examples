#!/bin/bash

# Collect the information to create our certificates.
CA_NAME=$(hostname -d)
IP_NAME=$(hostname -f)
IP_ADDRESS=$(host $IP_NAME | cut -d\  -f4)

# Setup local directory structure if needed
if [ ! -d etc/ssl/private ]; then
    mkdir -p etc/ssl/private
fi
if [ ! -d etc/ssl/certs ]; then
    mkdir -p etc/ssl/certs
fi
if [ ! -d etc/ssl/csr ]; then
    mkdir -p etc/ssl/csr
fi

# Where we put ".pem" files
PEM_DIR=etc/ssl/certs
# Where we put ".key" files
KEY_DIR=etc/ssl/private
# Where we put the ".csr" files
CSR_DIR=etc/ssl/csr

#
# Setup our example.edu "certificate authority"
#

# Generate private key
openssl genrsa -des3 -out $KEY_DIR/$CA_NAME.key 2048
# Generate root certificate
openssl req -x509 -new -nodes -key $KEY_DIR/$CA_NAME.key -sha256 -days 825 \
        -out $PEM_DIR/$CA_NAME.pem

#
# Create CA-signed certs for idp.example.edu
#


# Generate a private key
openssl genrsa -out $KEY_DIR/$IP_NAME.key 2048
# Create a certificate-signing request
openssl req -new -key $KEY_DIR/$IP_NAME.key -out $CSR_DIR/$IP_NAME.csr
# Create a config file for the extensions
>$CSR_DIR/$IP_NAME.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $IP_NAME
IP.1 = $IP_ADDRESS
EOF
# Create the signed certificate
openssl x509 -req -in $CSR_DIR/$IP_NAME.csr -CA $PEM_DIR/$CA_NAME.pem -CAkey $KEY_DIR/$CA_NAME.key \
        -CAcreateserial \
        -out $PEM_DIR/$IP_NAME.crt \
        -days 825 -sha256 \
        -extfile $CSR_DIR/$IP_NAME.ext
# Turn my crt into a PEM file.
openssl x509 -in $PEM_DIR/$IP_NAME.crt \
            -out $PEM_DIR/$IP_NAME.pem \
            -outform PEM
# Now turn our individual $IP_NAME and $CA_NAME certs into a bundle
# that we'll use in our Apache config.
cat $PEM_DIR/$IP_NAME.pem $PEM_DIR/$CA_NAME.pem >$PEM_DIR/$IP_NAME.chain.pem

