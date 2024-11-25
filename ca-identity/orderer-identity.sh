#!/bin/bash

# Exit immediately if a command fails
set -e

# Arguments
CA_ADDRESS_PORT=$1
COMPANY_DOMAIN=$2
ORDERER_IP_ADDRESS=$3
CA_ADMIN_USER=$4
CA_ADMIN_PASSWORD=$5
NUMBER=$6
ORDERER_PASSWORD=$7

# Check required arguments
if [ $# -lt 7 ]; then
  echo "Usage: $0 <CA_ADDRESS_PORT> <COMPANY_DOMAIN> <ORDERER_IP_ADDRESS> <CA_ADMIN_USER> <CA_ADMIN_PASSWORD> <NUMBER> <ORDERER_PASSWORD>"
  exit 1
fi

# Orderer directory to save
ORDERER_DIRECTORY="/etc/hyperledger/fabric-ca-client/crypto-config/ordererOrganizations"

# Enroll CA Admin
echo "Enrolling CA Admin..."
fabric-ca-client enroll -d -u https://"$CA_ADMIN_USER":"$CA_ADMIN_PASSWORD"@"$CA_ADDRESS_PORT"

# Rename Key file to key.pem
echo "Renaming key file to key.pem..."
if [ -d /etc/hyperledger/fabric-ca-server/msp/keystore ]; then
  mv /etc/hyperledger/fabric-ca-server/msp/keystore/*_sk /etc/hyperledger/fabric-ca-server/msp/keystore/key.pem
else
  echo "Keystore directory not found!"
  exit 1
fi

# Register orderer identities with the CA
echo "Registering orderer identity..."
fabric-ca-client register -d --id.name orderer"$NUMBER"."$COMPANY_DOMAIN" --id.secret "$ORDERER_PASSWORD" --id.type orderer -u https://"$CA_ADDRESS_PORT"

echo "Registering Admin identity..."
fabric-ca-client register -d --id.name Admin@orderer"$NUMBER"."$COMPANY_DOMAIN" --id.secret "$ORDERER_PASSWORD" --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://"$CA_ADDRESS_PORT"

# Enroll orderer identity
echo "Enrolling orderer identity..."
fabric-ca-client enroll -d -u https://orderer"$NUMBER"."$COMPANY_DOMAIN":"$ORDERER_PASSWORD"@"$CA_ADDRESS_PORT" --csr.hosts orderer"$NUMBER"."$COMPANY_DOMAIN" -M "$ORDERER_DIRECTORY/orderers/orderer$NUMBER.$COMPANY_DOMAIN/msp"

# Enroll TLS orderer identity
echo "Enrolling TLS identity for orderer..."
fabric-ca-client enroll -d -u https://orderer"$NUMBER"."$COMPANY_DOMAIN":"$ORDERER_PASSWORD"@"$CA_ADDRESS_PORT" --enrollment.profile tls --csr.hosts orderer"$NUMBER"."$COMPANY_DOMAIN","$ORDERER_IP_ADDRESS" -M "$ORDERER_DIRECTORY/orderers/orderer$NUMBER.$COMPANY_DOMAIN/tls"

# Enroll orderer Admin identity
echo "Enrolling Admin identity..."
fabric-ca-client enroll -d -u https://Admin@orderer"$NUMBER"."$COMPANY_DOMAIN":"$ORDERER_PASSWORD"@"$CA_ADDRESS_PORT" -M "$ORDERER_DIRECTORY/users/Admin@orderer$NUMBER.$COMPANY_DOMAIN/msp"

# Get TLS for Admin identity
echo "Getting TLS for Admin identity..."
fabric-ca-client enroll -d -u https://Admin@orderer"$NUMBER"."$COMPANY_DOMAIN":"$ORDERER_PASSWORD"@"$CA_ADDRESS_PORT" --enrollment.profile tls --csr.hosts orderer"$NUMBER"."$COMPANY_DOMAIN","$ORDERER_IP_ADDRESS" -M "$ORDERER_DIRECTORY/users/Admin@orderer$NUMBER.$COMPANY_DOMAIN/tls"

# Get Orderer Admin certs
echo "Fetching Admin certificates..."
fabric-ca-client certificate list --id Admin@orderer"$NUMBER"."$COMPANY_DOMAIN" --store "$ORDERER_DIRECTORY/users/Admin@orderer$NUMBER.$COMPANY_DOMAIN/msp/admincerts"

# Copy Admin certs to Orderers MSP
echo "Copying Admin certificates to orderer MSP..."
mkdir -p "$ORDERER_DIRECTORY/msp"
cp -r "$ORDERER_DIRECTORY/users/Admin@orderer$NUMBER.$COMPANY_DOMAIN/msp/admincerts/" "$ORDERER_DIRECTORY/orderers/orderer$NUMBER.$COMPANY_DOMAIN/msp/admincerts"

if [ "$NUMBER" == "1" ]; then
  echo "Setting up MSP for Orderer $NUMBER..."
  
  # Get MSP Files for Orderer
  fabric-ca-client getcacert -u https://"$CA_ADDRESS_PORT" -M "$ORDERER_DIRECTORY/msp"

  # AdminCerts for Orderer
  fabric-ca-client certificate list --id Admin@orderer"$NUMBER"."$COMPANY_DOMAIN" --store "$ORDERER_DIRECTORY/msp/admincerts"

  # TLS CA Certs for Orderer
  fabric-ca-client getcacert -u https://"$CA_ADDRESS_PORT" -M "$ORDERER_DIRECTORY/msp" --csr.hosts orderer"$NUMBER"."$COMPANY_DOMAIN","$ORDERER_IP_ADDRESS" --enrollment.profile tls
fi

echo "Script execution completed successfully!"
