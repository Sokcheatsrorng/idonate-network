#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Set strict error handling
set -euo pipefail

# Global variables
readonly LOG_FILE="deployment.log"
readonly ORGANIZATION_CHANNEL="donationchannel"

# Colors for logging
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Error handling
handle_error() {
    local line_no=$1
    local error_code=$2
    log_error "Error occurred in script at line: ${line_no}, error code: ${error_code}"
    exit "${error_code}"
}

trap 'handle_error ${LINENO} $?' ERR

# Initialize environment variables
init_environment() {
  
    log_info "Initializing environment variables"
    
    # Organization information
    export NAME_OF_ORGANIZATION="$1"
    export DOMAIN_OF_ORGANIZATION="$2"
    export HOST_IP_ADDRESS=172.17.0.1
    # HOST_IP_ADDRESS=$(hostname -I | awk '{print $1}')
    export ORGANIZATION_NAME_LOWERCASE=$(echo "$NAME_OF_ORGANIZATION" | tr '[:upper:]' '[:lower:]')
    export CA_ADDRESS_PORT="ca.$DOMAIN_OF_ORGANIZATION:7054"

    # Security credentials
    export COUCH_DB_USERNAME="idonateAdmin"
    export COUCH_DB_PASSWORD="idonatepw"
    export CA_ADMIN_USER="idonateAdmin"
    export CA_ADMIN_PASSWORD="idonatepw"
    export ORDERER_PASSWORD="ordererpw"
    export PEER_PASSWORD="peerpw"

    log_info "Environment variables initialized successfully"
}

# Setup network configuration
setup_network_config() {

    log_info "Setting up network configuration"
    
    ./clean-all.sh
    
    # Generate configtx.yaml from template
    sed -e "s/organization_name/$NAME_OF_ORGANIZATION/g" \
        -e "s/organization_domain/$DOMAIN_OF_ORGANIZATION/g" \
        -e "s/ip_address/$HOST_IP_ADDRESS/g" \
        configtx_template.yaml > configtx.yaml
        
    log_info "Network configuration completed"
}

# Setup certificate authority
setup_ca() {


  log_info "Starting Certificate Authority"

  # # Start CA container using Docker Compose
  docker-compose -p fabric-network -f docker-compose.yml up -d ca
  sleep 3

  # # # Give full permissions to the CA folder
  # log_info "Giving full permissions to CA folder"
  # docker exec "ca.$DOMAIN_OF_ORGANIZATION" /bin/bash -c \
  #     "chmod -R 777 /etc/hyperledger/artifacts/"

  # # # Generate orderer identities
  for orderer_num in {1..3}; do
      log_info "Generating identity for orderer$orderer_num"

      docker exec "ca.$DOMAIN_OF_ORGANIZATION" /bin/bash -c \
          "cd /etc/hyperledger/artifacts/ && \
          ./orderer-identity.sh $CA_ADDRESS_PORT $DOMAIN_OF_ORGANIZATION \
          $HOST_IP_ADDRESS $CA_ADMIN_USER $CA_ADMIN_PASSWORD \
          $orderer_num $ORDERER_PASSWORD"
  done

  # # # Generate peer identities
  for peer_num in {1..2}; do
      log_info "Generating identity for peer$peer_num"
      docker exec "ca.$DOMAIN_OF_ORGANIZATION" /bin/bash -c \
          "cd /etc/hyperledger/artifacts/ && \
          ./peer-identity.sh $CA_ADDRESS_PORT $DOMAIN_OF_ORGANIZATION \
          $HOST_IP_ADDRESS $PEER_PASSWORD $peer_num"
  done

  # Start the certficate authority
}

# Setup crypto material
setup_crypto_material() {
    log_info "Setting up cryptographic material"

    local source_dir="./${ORGANIZATION_NAME_LOWERCASE}Ca/client/crypto-config"
    local target_dir="./crypto-config"

    # Ensure the source directory exists
    if [ ! -d "$source_dir" ]; then
        log_error "Source directory $source_dir does not exist"
        exit 1
    fi

    # Handle the target directory
    if [ -d "$target_dir" ]; then
        log_warning "Target directory $target_dir already exists. Clearing its contents..."
        sudo rm -rf "$target_dir" || {
            log_error "Failed to clear the target directory"
            exit 1
        }
    fi

    # Move the source directory to the target location
    log_info "Moving cryptographic material from $source_dir to $target_dir"
    sudo mv "$source_dir" "$target_dir" || {
        log_error "Failed to move cryptographic material"
        exit 1
    }

    # Set appropriate permissions
    log_info "Setting permissions for $target_dir"
    sudo chmod -R 777 "$target_dir" || {
        log_error "Failed to set permissions for $target_dir"
        exit 1
    }

    # Setup orderer TLS certificates
    log_info "Setting up orderer TLS certificates..."
    for orderer_num in {1..3}; do
        setup_orderer_tls "$orderer_num"
    done

    # Setup peer TLS certificates
    log_info "Setting up peer TLS certificates..."
    for peer_num in {1..2}; do
        setup_peer_tls "$peer_num"
    done

    log_info "Cryptographic material setup completed successfully"
}

# Helper function for orderer TLS setup
setup_orderer_tls() {
    local orderer_num=$1
    local orderer_dir="./crypto-config/ordererOrganizations/orderers/orderer${orderer_num}.$DOMAIN_OF_ORGANIZATION"
    
    log_info "Setting up TLS for orderer${orderer_num}"
    
    sudo mv "${orderer_dir}/tls/signcerts/cert.pem" "${orderer_dir}/tls/server.crt"
    sudo mv "${orderer_dir}/tls/keystore/"*"_sk" "${orderer_dir}/tls/server.key"
    sudo mv "${orderer_dir}/tls/tlscacerts/"*.pem "${orderer_dir}/tls/ca.crt"
    sudo rm -rf "${orderer_dir}/tls/"{"cacerts","keystore","signcerts","tlscacerts","user"}
}



# Helper function for peer TLS setup
setup_peer_tls() {
    local peer_num=$1
    local peer_dir="./crypto-config/peerOrganizations/peers/peer${peer_num}.$DOMAIN_OF_ORGANIZATION"
    
    log_info "Setting up TLS for peer${peer_num}"
    
    sudo mv "${peer_dir}/tls/signcerts/cert.pem" "${peer_dir}/tls/server.crt"
    sudo mv "${peer_dir}/tls/keystore/"*"_sk" "${peer_dir}/tls/server.key"
    sudo mv "${peer_dir}/tls/tlscacerts/"*.pem "${peer_dir}/tls/ca.crt"
    sudo rm -rf "${peer_dir}/tls/"{"cacerts","keystore","signcerts","tlscacerts","user"}
}

# Deploy network
deploy_network() {

    log_info "Deploying network"
    
    ./generate.sh "$ORGANIZATION_CHANNEL" "$NAME_OF_ORGANIZATION"
    sleep 2
    
    docker-compose -f docker-compose.yml up -d peer peer2 couchdb cli
    sleep 2
    docker-compose -f docker-compose.yml up -d orderer2 orderer3
    
    join_orderers_to_channel
    join_peers_to_channel
}

# Join orderers to channel
join_orderers_to_channel() {
    log_info "Joining orderers to channel"
    
    for orderer_num in {1..3}; do
        local port=$((7053 + (orderer_num - 1) * 1000))
        docker exec cli osnadmin channel join \
            -o "orderer${orderer_num}.$DOMAIN_OF_ORGANIZATION:${port}" \
            --channelID "$ORGANIZATION_CHANNEL" \
            --config-block /etc/hyperledger/artifacts/channel.tx \
            --ca-file "/etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer${orderer_num}.$DOMAIN_OF_ORGANIZATION/tls/ca.crt" \
            --client-cert "/etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer${orderer_num}.$DOMAIN_OF_ORGANIZATION/tls/server.crt" \
            --client-key "/etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer${orderer_num}.$DOMAIN_OF_ORGANIZATION/tls/server.key"
    done
}

# Join peers to channel
join_peers_to_channel() {
    log_info "Joining peers to channel"
    
    for peer_num in {1..2}; do
        docker exec cli peer channel join \
            -b "/etc/hyperledger/artifacts/channel.block"
    done
}

# Deploy chaincode
deploy_chaincode() {
    log_info "Deploying chaincode"
    
    # Package and install chaincode
    docker exec cli peer lifecycle chaincode package chaincode.tar.gz \
        --path /etc/hyperledger/chaincode --lang golang --label ccv1
    
    docker exec cli peer lifecycle chaincode install chaincode.tar.gz
    
    # Get package ID
    docker exec cli peer lifecycle chaincode queryinstalled >&log.txt
    PACKAGE_ID=$(sed -n '/Package/{s/^Package ID: //; s/, Label:.*$//; p;}' log.txt)
    log_info "Chaincode package ID: $PACKAGE_ID"
    
    approve_and_commit_chaincode
}

# Approve and commit chaincode
approve_and_commit_chaincode() {
    log_info "Approving and committing chaincode"
    
    docker exec cli peer lifecycle chaincode approveformyorg \
        -o "orderer1.$DOMAIN_OF_ORGANIZATION:7050" \
        --ordererTLSHostnameOverride "orderer1.$DOMAIN_OF_ORGANIZATION" \
        --channelID "$ORGANIZATION_CHANNEL" \
        --name chaincode --version 1.0 --sequence 1 \
        --tls --cafile "/etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$DOMAIN_OF_ORGANIZATION/tls/ca.crt" \
        --package-id "${PACKAGE_ID}"
    
    docker exec cli peer lifecycle chaincode commit \
        -o "orderer1.$DOMAIN_OF_ORGANIZATION:7050" \
        --channelID "$ORGANIZATION_CHANNEL" \
        --name chaincode --version 1.0 --sequence 1 \
        --tls --cafile "/etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$DOMAIN_OF_ORGANIZATION/tls/ca.crt" \
        --peerAddresses "peer1.$DOMAIN_OF_ORGANIZATION:7051" \
        --tlsRootCertFiles "/etc/hyperledger/crypto-config/peerOrganizations/peers/peer1.$DOMAIN_OF_ORGANIZATION/tls/ca.crt"
  }

# Main function
main() {
    # Check if log file exists, if not create it
    touch "$LOG_FILE"
    log_info "Starting network deployment script"
    
    # Get organization details
    read -rp "Organization Name: " org_name
    read -rp "Organization Domain: " org_domain
    
    # Initialize environment
    init_environment "$org_name" "$org_domain"
    
    # Execute deployment steps
    setup_network_config
    setup_ca
    setup_crypto_material
    deploy_network
    deploy_chaincode
    
    log_info "Network deployment completed successfully"
}

# Execute main function
main