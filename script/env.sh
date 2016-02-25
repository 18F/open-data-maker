#!/bin/sh

# TO DO: make environment vars match AWS

# usage example:
# export CF_CREDENTIALS=$(cf env ccapi-indexing)
# ./script/env.sh > .indexing.env

export BSERVICE_CREDENTIALS=`echo "${CF_CREDENTIALS}" | tail -n +5 | \
      jq -r '.VCAP_SERVICES["user-provided"][] | \
      select(.name != null) | \
      select(.name == "bservice").credentials'  2>/dev/null`

export AWS_ACCESS_KEY_ID=`echo "${BSERVICE_CREDENTIALS}" | jq -r .access_key`
export AWS_SECRET_ACCESS_KEY=`echo "${BSERVICE_CREDENTIALS}" | jq -r .secret_key`
export BUCKET_NAME=`echo "${BSERVICE_CREDENTIALS}" | jq -r .bucket`

echo "
s3_access_key=$AWS_ACCESS_KEY_ID
s3_secret_key=$AWS_SECRET_ACCESS_KEY
s3_bucket=$BUCKET_NAME
"
