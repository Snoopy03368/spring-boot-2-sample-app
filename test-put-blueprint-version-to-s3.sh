#!/usr/bin/env bash -x

BLUEPRINT_NAME=`yq -r '.|.name' blueprint.yml`
BUILD_NUMBER="476"
TRIGGER_URL="github@github.com:me/repo.git"
TRIGGER_REV=b5474985954e898cf218b9f5a57431bdebd1b19e
COMMIT_AUTHOR_EMAILS="roskelleycj@familysearch.org"
BLUEPRINT_VERSION_BUCKET="adhoc-us-east-1-074150922133/private/roskelleycj/blueprints"
BLUEPRINT_VERSION_BUCKET_PATH="$BLUEPRINT_VERSION_BUCKET/$BLUEPRINT_NAME/$BUILD_NUMBER"

./put-blueprint-version-to-s3.sh $BLUEPRINT_NAME $BUILD_NUMBER $TRIGGER_URL $TRIGGER_REV $COMMIT_AUTHOR_EMAILS $BLUEPRINT_VERSION_BUCKET_PATH

# aws s3 presign s3://${BLUEPRINT_VERSION_BUCKET_PATH} >blueprint-version-url
aws s3 cp s3://$BLUEPRINT_VERSION_BUCKET_PATH /tmp/blueprint-version.yml
jq '.' /tmp/blueprint-version.yml
