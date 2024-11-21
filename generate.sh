# SPDX-License-Identifier: Apache-2.0
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH

# Set the Fabric configuration path
export FABRIC_CFG_PATH=/home/sokcheat/blockchain-cstad/ledgerlift/hyperledger-fabric-idonate-network

# Set the binary directory (no spaces around `=`)
# export BINARY_DIR=/home/sokcheat/blockchain-cstad/ledgerlift/hyperledger-fabric-idonate-network/bin

# Capture channel and organization names from arguments
CHANNEL_NAME=donationchannel
ORGANIZATION_NAME=$2

# Create config directory if it doesn't exist
mkdir -p config/

# Remove any previous crypto material and config transactions
rm -fr config/*

# Generate the channel configuration transaction
configtxgen -profile Channel -outputBlock ./config/channel.tx -channelID $CHANNEL_NAME

if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# Generate anchor peer transaction for the specified organization
configtxgen -profile Channel -outputAnchorPeersUpdate ./config/${ORGANIZATION_NAME}MSPanchors.tx -channelID $CHANNEL_NAME -asOrg ${ORGANIZATION_NAME}MSP

if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for MSP..."
  exit 1
fi