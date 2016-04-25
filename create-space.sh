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

echo "*** When creating the space, the user which creates it is a SpaceManager"
echo "*** Add developers using: cf set-space-role USERNAME ed ${SPACE} SpaceDeveloper" 

# Target the space
cf target -o ed -s ${SPACE}

# Create a bservice instance used by snapshot tools
cf create-service s3 basic data-files
#cf create-user-provided-service bservice -p '{"BSERVICE_ACCESS_KEY":"YOUR_S3_ACCESS_KEY", "BSERVICE_SECRET_KEY": "YOUR_S3_SECRET_KEY", "BSERVICE_BUCKET": "YOUR_S3_BUCKET"}'

# Create backup service
echo "To create a backup service in this space run:"
echo "cf create-service s3 basic backup"

# Create the ElasticSearch service
cf create-service elasticsearch-swarm-1.7.5 3x eservice

# Create ccapi-indexing
#cf push -f ccapi-${SPACE}

# /downloads happens through an app in production space
# ed-public-download   started           2/2         64M      1G     ed-public-download.apps.cloud.gov, download.collegescorecard.ed.gov
# connected to bucket ....

