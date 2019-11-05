#!/usr/bin/env bash

BLUEPRINT_NAME=`yq -r '.|.name' blueprint.yml`
SYSTEM_NAME=`yq -r '.|.deploy|keys|.[0]' blueprint.yml` # gets the `dev` system name
CHECK_RESULTS_FILE=check-dev-report  # this is from the `sysps-job-start.sh` for the check on the `dev` system.
ARTIFACT_BUCKET=adhoc-us-east-1-074150922133/private/roskelleycj/artifacts
REPO_NAME=spring-boot-2-sample-app
BRANCH=master
SHORT_REVISION=1a20771
BUILD_ID=build-1
SERVICE_ARTIFACTS_JSON_FILE=$BLUEPRINT_NAME-$SYSTEM_NAME-service-artifacts-url.json

# make sure we clean stuff up first.
rm $BLUEPRINT_NAME-*-artifacts.zip

./put-services-zip-to-s3.sh $BLUEPRINT_NAME \
                         $SYSTEM_NAME  \
                         $CHECK_RESULTS_FILE \
                         $ARTIFACT_BUCKET \
                         $BUILD_ID \
                         $SERVICE_ARTIFACTS_JSON_FILE
