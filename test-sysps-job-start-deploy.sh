#!/usr/bin/env bash

FSSESSIONID=`jq -r '.|.session.sessionId' ~/.paas-portal`
PHASE="deploy"
VERSION="version"
TRIGGER_REV="sha"
TRIGGER_URL="url"
BUILDSNAPSHOT_URL="null"
SYSTEM_NAME=`yq -r '.|.deploy|keys|.[0]' blueprint.yml`
BLUEPRINT_NAME=`yq -r '.|.name' blueprint.yml`

aws s3 presign s3://adhoc-us-east-1-074150922133/roskelleycj/blueprints/spring-boot-2-sample-app/master/13960c9>blueprint-version-url
BLUEPRINT_VERSION_URL=`cat blueprint-version-url`

./sysps-job-start.sh $FSSESSIONID \
                     $PHASE \
                     $VERSION \
                     $TRIGGER_REV \
                     $TRIGGER_URL \
                     $BUILDSNAPSHOT_URL \
                     $BLUEPRINT_NAME \
                     $SYSTEM_NAME \
                     $BLUEPRINT_VERSION_URL \
                     $BLUEPRINT_NAME-$SYSTEM_NAME-artifacts-url.json # must run test-push-services-zip-to-s3.sh first
