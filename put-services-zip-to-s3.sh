#!/bin/sh -ex

# Using the 'results' from check create ZIP files for each service
# and put them in S3 and finally generate serviceArtifactUrls
BLUEPRINT_NAME=$1
SYSTEM_NAME=$2
CHECK_RESULTS_FILE=$3
BLUEPRINT_VERSION_BUCKET=$4
REPO_NAME=$5
BRANCH=$6
SHORT_REVISION=$7
BUILD_ID=$8
SERVICE_ARTIFACTS_JSON_FILE=$9

BUCKET_OBJECT_BASE=${BLUEPRINT_VERSION_BUCKET}/artifacts/${REPO_NAME}/${BRANCH}/${SHORT_REVISION}/${BUILD_ID}
SERVICE_NAMES=`jq -r '.|.expectedPaths|keys|.[]' $CHECK_RESULTS_FILE`

# generate the artifacts json snippet
jq -n '{}' > $SERVICE_ARTIFACTS_JSON_FILE

for service_name in $SERVICE_NAMES;
do
  zip_name=$BLUEPRINT_NAME-$SYSTEM_NAME-$service_name-artifacts.zip

  echo "Creating artifacts for:  $service_name"
  required_artifacts=`jq -r ".|.expectedPaths.$service_name|.required + .optional|.[]" $CHECK_RESULTS_FILE`
  for artifact in $required_artifacts;
  do
    zip $zip_name $artifact
  done

  echo "Uploading artifacts for:  $service_name"
  aws s3 cp $zip_name s3://$BUCKET_OBJECT_BASE/$zip_name
  aws s3 presign s3://$BUCKET_OBJECT_BASE/$zip_name >${zip_name}-presign-url
  PRESIGNED_URL=`cat ${zip_name}-presign-url`
  # adding to the list of serviceArtifactUrls
  jq -n --arg service_name $service_name --arg url $PRESIGNED_URL '[{"key":$ARGS.named["service_name"], "value":$ARGS.named["url"]}]|from_entries' >add-service-name-url.json
  jq -e -s '.[0] * .[1]' $SERVICE_ARTIFACTS_JSON_FILE add-service-name-url.json >copy-service-artifacts-json
  mv copy-service-artifacts-json $SERVICE_ARTIFACTS_JSON_FILE
done
