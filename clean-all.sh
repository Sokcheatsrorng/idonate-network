# SPDX-License-Identifier: Apache-2.0

# Clean the container environment for deployment
# Get the list of running containers
RUNNING_CONTAINERS=$(docker ps -q)

# Get the list of all containers (running or stopped)
ALL_CONTAINERS=$(docker ps -aq)

# Loop through all containers and remove those that are not part of any active network
for CONTAINER in $ALL_CONTAINERS; do
  # Check if the container is running and attached to an active network
  if [[ ! " $RUNNING_CONTAINERS " =~ " $CONTAINER " ]]; then
    # If the container is not running, remove it
    echo "Removing container $CONTAINER..."
    docker rm -f $CONTAINER
  fi
done

# Get the list of images associated with dev-peer* (Hyperledger Fabric images)
DOCKER_IMAGE_IDS=$(docker images | awk '$1 ~ /dev-peer*/ {print $3}')

# Check if there are any images to remove
if [ -z "$DOCKER_IMAGE_IDS" ] || [ "$DOCKER_IMAGE_IDS" == " " ]; then
  echo "---- No images available for deletion ----"
else
  # Remove the images
  echo "Removing images: $DOCKER_IMAGE_IDS..."
  docker rmi -f $DOCKER_IMAGE_IDS
fi


# Delete old certificates and channel artifacts
sudo rm -rf ${ORGANIZATION_NAME_LOWERCASE}Ca/crypto-config/ artifacts/ config/ chaincode/node_modules configtx.yaml

if [ ! -d artifacts ]; then
   mkdir artifacts
fi

if [ ! -d config ];then
   mkdir config
fi
