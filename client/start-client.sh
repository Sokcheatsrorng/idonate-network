#!/bin/bash


# Cleanup
# sudo rm -rf ./wallet/*

function exportVariables(){
    # Get the parameters
    export NAME_OF_ORGANIZATION=$NAME_OF_ORGANIZATION
    export DOMAIN_OF_ORGANIZATION=$DOMAIN_OF_ORGANIZATION
    export HOST_IP_ADDRESS=$HOST_IP_ADDRESS
    export ORGANIZATION_NAME_LOWERCASE=`echo "$NAME_OF_ORGANIZATION" | tr '[:upper:]' '[:lower:]'`
    export ORG_MSP=${NAME_OF_ORGANIZATION}MSP
}

read -p "Organization Name: "  NAME_OF_ORGANIZATION
read -p "Organization Domain: " DOMAIN_OF_ORGANIZATION

HOST_IP_ADDRESS=172.17.0.1
exportVariables

npm install

# Update variables in template
sed -e 's/NAME_OF_ORGANIZATION/'$NAME_OF_ORGANIZATION'/g' \
    -e 's/DOMAIN_OF_ORGANIZATION/'$DOMAIN_OF_ORGANIZATION'/g' \
    -e 's/HOST_IP_ADDRESS/'$HOST_IP_ADDRESS'/g' \
    -e 's/ORGANIZATION_NAME_LOWERCASE/'$ORGANIZATION_NAME_LOWERCASE'/g' \
    ./template/connection-org.json > connection-org.json

sed -e 's/NAME_OF_ORGANIZATION/'$NAME_OF_ORGANIZATION'/g' \
    -e 's/DOMAIN_OF_ORGANIZATION/'$DOMAIN_OF_ORGANIZATION'/g' \
    -e 's/HOST_IP_ADDRESS/'$HOST_IP_ADDRESS'/g' \
    -e 's/ORGANIZATION_NAME_LOWERCASE/'$ORGANIZATION_NAME_LOWERCASE'/g' \
    ./template/connections.yml > connections.yml

# Get the certificates
cp ../${ORGANIZATION_NAME_LOWERCASE}Ca/tls-cert.pem .
cp ../crypto-config/peerOrganizations/peers/peer.${DOMAIN_OF_ORGANIZATION}/tls/ca.crt ./

# ./start-kong.sh $HOST_IP_ADDRESS

npm run build && npm run start