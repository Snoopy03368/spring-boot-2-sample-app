#!/usr/bin/env bash

BLUEPRINT_NAME=`yq -r '.|.name' blueprint.yml`
SYSTEM_NAME=`yq -r '.|.deploy|keys|.[0]' blueprint.yml`
BLUEPRINT_VERSION_BUCKET=adhoc-us-east-1-074150922133/roskelleycj
REPO_NAME=spring-boot-2-sample-app
BRANCH=master
SHORT_REVISION=1a20771
BUILD_ID=build-1
SERVICE_ARTIFACTS_JSON_FILE=$BLUEPRINT_NAME-$SYSTEM_NAME-service-artifacts-url.json

# make sure we clean stuff up first.
rm $BLUEPRINT_NAME-*-artifacts.zip

./put-services-zip-to-s3.sh $BLUEPRINT_NAME \
                         $SYSTEM_NAME  \
                         report \
                         $BLUEPRINT_VERSION_BUCKET \
                         $REPO_NAME \
                         $BRANCH \
                         $SHORT_REVISION \
                         $BUILD_ID \
                         $SERVICE_ARTIFACTS_JSON_FILE
