#!/usr/bin/env bash

FSSESSIONID="b3e5cde4-17e8-45f3-99fb-dcaad3c80f16-integ" #`jq -r '.|.session.sessionId' ~/.paas-portal`
PHASE="check"
VERSION="version"
TRIGGER_REV="sha"
TRIGGER_URL="url"
BUILDSNAPSHOT_URL="null"
SYSTEM_NAME=`yq -r '.|.deploy|keys|.[0]' blueprint.yml`
BLUEPRINT_NAME=`yq -r '.|.name' blueprint.yml`

aws s3 presign s3://adhoc-us-east-1-074150922133/roskelleycj/blueprints/spring-boot-2-sample-app/master/13960c9>blueprint-version-url
BLUEPRINT_VERSION_URL=`cat blueprint-version-url`

./sysps-job-start.sh $FSSESSIONID $PHASE $VERSION $TRIGGER_REV $TRIGGER_URL $BUILDSNAPSHOT_URL $BLUEPRINT_NAME $SYSTEM_NAME $BLUEPRINT_VERSION_URL
