#!/bin/sh -ex

# Using the results from 'check-<system>-results' create ZIP files for each service
# and put them in S3 and finally generate serviceArtifactUrls
BLUEPRINT_NAME=$1
SYSTEM_NAME=$2
CHECK_RESULTS_FILE=$3
ARTIFACT_BUCKET=$4
BUILD_ID=$5
SERVICE_ARTIFACTS_JSON_FILE=$6

# Just do something to keep things from stepping other uploads.
BUCKET_OBJECT_BASE=${ARTIFACT_BUCKET}/${BUILD_ID}
SERVICE_NAMES=`jq -r '.|.expectedPaths|keys|.[]' $CHECK_RESULTS_FILE`

# generate the artifacts json snippet
jq -n '{}' > $SERVICE_ARTIFACTS_JSON_FILE

for service_name in $SERVICE_NAMES;
do
  zip_name=$BLUEPRINT_NAME-$SYSTEM_NAME-$service_name-artifacts.zip

  echo "Creating artifacts for:  $service_name"
  artifacts=`jq -r ".|.expectedPaths.$service_name|.required + .optional|.[]" $CHECK_RESULTS_FILE`
  for artifact in $artifacts;
  do
    zip $zip_name $artifact
  done

  echo "Uploading artifacts for:  $service_name"
  aws s3 cp $zip_name s3://$BUCKET_OBJECT_BASE/$zip_name
  # because we are using the adhoc bucket we have to grant permissions.  Normal automation wouldn't need this.
  aws s3 presign s3://$BUCKET_OBJECT_BASE/$zip_name >${zip_name}-presign-url
  PRESIGNED_URL=`cat ${zip_name}-presign-url`
  # adding to the list of serviceArtifactUrls
  jq -n --arg service_name $service_name --arg url $PRESIGNED_URL '[{"key":$ARGS.named["service_name"], "value":$ARGS.named["url"]}]|from_entries' >${zip_name}-add-service-name-url.json
  jq -e -s '.[0] * .[1]' $SERVICE_ARTIFACTS_JSON_FILE ${zip_name}-add-service-name-url.json >${zip_name}-copy-service-artifacts-json
  mv ${zip_name}-copy-service-artifacts-json $SERVICE_ARTIFACTS_JSON_FILE
done
