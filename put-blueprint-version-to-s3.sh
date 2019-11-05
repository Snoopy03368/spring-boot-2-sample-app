#!/bin/sh -x

BLUEPRINT_NAME=$1
BUILD_NUMBER=$2
TRIGGER_URL=$3
TRIGGER_REV=$4
COMMIT_AUTHOR_EMAILS=$5
BLUEPRINT_VERSION_BUCKET_PATH=$6  # must be bucket/object

jq -n --argjson blueprint "`yq -c . blueprint.yml`" --arg version "${BUILD_NUMBER}" --arg triggerUrl "${TRIGGER_URL}" --arg triggerRev "${TRIGGER_REV}" --arg authorEmails "${COMMIT_AUTHOR_EMAILS}" '{"blueprint": $ARGS.named["blueprint"], "triggerRev": $ARGS.named["triggerRev"], "triggerUrl":$ARGS.named["triggerUrl"], "authorEmails": $ARGS.named["authorEmails"], "version": $ARGS.named["version"]}' >blueprint-version.json

aws s3 cp blueprint-version.json s3://${BLUEPRINT_VERSION_BUCKET_PATH}
