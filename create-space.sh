#!/bin/bash
set -e

if [ ! -n "$1" ]; then
  echo "Usage: create-space.sh spacename"
  exit 1
fi
echo "Creating space: $1"
SPACE=$1

# Creating the indexing space
cf create-space ${SPACE} -o ed

echo "# When creating the space, the user which creates it is a SpaceManager"
echo "# Add developers using: cf set-space-role USERNAME ed ${SPACE} SpaceDeveloper" 

# Target the space
cf target -o ed -s ${SPACE}

# Create a bservice instance used by snapshot tools
cf create-service s3 basic data-files


#cf create-user-provided-service bservice -p '{"BSERVICE_ACCESS_KEY":"YOUR_S3_ACCESS_KEY", "BSERVICE_SECRET_KEY": "YOUR_S3_SECRET_KEY", "BSERVICE_BUCKET": "YOUR_S3_BUCKET"}'

# Create backup service
echo "# To create a backup service in this space run:"
echo "# cf create-service s3 basic backup"

# Create the ElasticSearch service
cf create-service elasticsearch-swarm-1.7.5 3x eservice

echo "# To create the API server push the ccapi-${SPACE} app:"
echo "cf push -f manifest-${SPACE}.yml"

echo "# For data archive / downloads, these are served via a S3 proxy"
echo "# The /downloads path is redirected via CloudFront to"
echo "# ed-public-download.apps.cloud.gov which is in the production space"
echo "# To create additional S3 proxies: https://github.com/18F/cg-s3-proxy"

echo "# now you need to index"
echo "cf-ssh -f manifest-${SPACE}"
echo "# wait several minutes for this to connect"
echo "echo $DATA_PATH"
echo "# if blank, you will get default cities data"
echo "rake import"
echo "# when this is done, go to https://ccapi-${SPACE}.18f.gov and explore"

