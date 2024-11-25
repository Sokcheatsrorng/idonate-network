CHANNEL_NAME=$1

docker exec cli peer channel fetch 0 channel.block -c $CHANNEL_NAME --orderer orderer.ORGANIZATION_DOMAIN:7050 --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer.ORGANIZATION_DOMAIN/tls/ca.crt

docker exec cli peer channel join -b ./channel.block

# Approve chaincode (manual step, must add all organizations to signature policy and sequence number)

# PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled -o $ORDERER_DOMAIN:7050 --tls --cafile $TLS_CA_FILE | grep "$CHAINCODE_NAME" | awk -F " " '{print $2}')

# docker exec cli peer lifecycle chaincode approveformyorg -o orderer.ORGANIZATION_DOMAIN:7050 --channelID CHANNEL_NAME --name chaincode --version 1.0 --sequence 0 --signature-policy "OR('SMTIMSP.member', 'GabineteMSP.member', 'FinancasMSP.member')" --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer.ORGANIZATION_DOMAIN/tls/ca.crt --package-id $PACKAGE_ID 