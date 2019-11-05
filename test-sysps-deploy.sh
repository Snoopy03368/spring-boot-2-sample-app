#!/usr/bin/env bash

FSSESSIONID="b3e5cde4-17e8-45f3-99fb-dcaad3c80f16-integ" #`jq -r '.|.session.sessionId' ~/.paas-portal`
PHASE="check"
BLUEPRINT_NAME=`yq -r '.|.name' blueprint.yml`
SYSTEM_NAME=`yq -r '.|.deploy|keys|.[0]' blueprint.yml`
SERVICE_ARTIFACTS_JSON_FILE=$BLUEPRINT_NAME-$SYSTEM_NAME-service-artifacts-url.json
BUILD_NUMBER=476
TRIGGER_REV="d85d594668d900b5f369d5afe4eaaf110a151e40"
TRIGGER_URL="git@github.com:me/myrepo.git"
BUCKET="adhoc-us-east-1-074150922133"
ARTIFACT_BUCKET_PATH="$BUCKET/private/roskelleycj/artifacts"
BLUEPRINT_VERSION_BUCKET_PATH="$BUCKET/private/roskelleycj/blueprints/$BLUEPRINT_NAME/$BUILD_NUMBER"
BUILD_SNAPSHOT_URL="null"

# because we are using the adhoc bucket we have to grant permissions.  Normal automation wouldn't need this.
aws s3 presign s3://$BLUEPRINT_VERSION_BUCKET_PATH>blueprint-version-url
BLUEPRINT_VERSION_URL=`cat blueprint-version-url`

./put-services-zip-to-s3.sh $BLUEPRINT_NAME \
                            $SYSTEM_NAME \
                            check-$SYSTEM_NAME-report \
                            $ARTIFACT_BUCKET_PATH \
                            $BUILD_NUMBER \
                            $SERVICE_ARTIFACTS_JSON_FILE

SERVICE_ARTIFACTS_JSON=`jq '.|tostring' $BLUEPRINT_NAME-$SYSTEM_NAME-service-artifacts-url.json`
./sysps-job-start.sh $FSSESSIONID \
                     $PHASE \
                     $BUILD_NUMBER \
                     $TRIGGER_REV \
                     $TRIGGER_URL \
                     $BUILD_SNAPSHOT_URL \
                     $BLUEPRINT_NAME \
                     $SYSTEM_NAME \
                     $BLUEPRINT_VERSION_URL \
                     $SERVICE_ARTIFACTS_JSON


