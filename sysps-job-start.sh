#!/bin/sh -x

FSSESSIONID=$1
PHASE=$2
VERSION=$3
TRIGGER_REV=$4
TRIGGER_URL=$5
BUILDSNAPSHOT_URL=$6
BLUEPRINT_NAME=$7
SYSTEM_NAME=$8
BLUEPRINT_VERSION_URL=$9
SERVICE_ARTIFACT_URLS_STR=${10:-""}
SLEEP_DURATION_SEC=60

POST_JOB_URL=https://api.fsdpt.org/service_provisioning/$PHASE/$BLUEPRINT_NAME/$SYSTEM_NAME/jobs
if [[ "$FSSESSIONID" =~ .*-integ ]];
then
  # the dev-dev version of sysps api
  POST_JOB_URL=https://5fut8v0p96.execute-api.us-east-1.amazonaws.com/v1/$PHASE/$BLUEPRINT_NAME/$SYSTEM_NAME/jobs
fi

echo "Submitting job: $POST_JOB_URL"

if [ "$SERVICE_ARTIFACT_URLS_STR" == "" ];
then
  SERVICE_ARTIFACT_URLS="null"
else
  SERVICE_ARTIFACT_URLS=`echo $SERVICE_ARTIFACT_URLS_STR|jq '.|fromjson'`
fi

if [ $PHASE == "check" ];
then
  SLEEP_DURATION_SEC=2
fi

curl -s -w "Job submitted:  http_code=%{http_code}\n" --http1.1 \
  $POST_JOB_URL \
  -H 'Accept: */*' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H "Authorization: Bearer ${FSSESSIONID}" \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H 'User-Agent: roskelleycj/1.0 (manual)' \
  -H 'cache-control: no-cache' \
  -d "{\"systemContext\": {
        \"buildNumber\": \"$VERSION\",
        \"triggerURL\": \"$TRIGGER_URL\",
        \"triggerRev\": \"$TRIGGER_REV\",
        \"buildSnapshotUrl\": \"$BUILDSNAPSHOT_URL\",
        \"systemName\": \"$SYSTEM_NAME\",
        \"blueprintName\": \"$BLUEPRINT_NAME\",
        \"blueprintVersionUrl\": \"$BLUEPRINT_VERSION_URL\",
        \"serviceArtifactUrls\": $SERVICE_ARTIFACT_URLS,
        \"definition\":{}
    }}" -o post-job

JOBID=`jq -r -e '.|.id' post-job`
if [ $? -ne 0 ]
then
  echo "Didn't get a JOB ID!  Is it possible the session id has expired?"
  cat post-job
  exit 1
fi

GET_JOB_URL=$POST_JOB_URL/$JOBID
GET_JOB_STATUS_URL=$GET_JOB_URL/status

echo "Checking status on '$JOBID'"
TRY_ATTEMPT=1
STATUS="INPROGRESS"
while [ $STATUS != "CLOSED" ]
do
  sleep $SLEEP_DURATION_SEC

  curl -s -G -w "Job status attempt:  http_code=%{http_code}\n" --http1.1 \
  $GET_JOB_STATUS_URL \
  -H 'Accept: */*' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H "Authorization: Bearer ${FSSESSIONID}" \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H 'User-Agent: roskelleycj/1.0 (manual)' \
  -H 'cache-control: no-cache' -o status-$TRY_ATTEMPT

  STATUS=`jq -r '.|.executionStatus' status-$TRY_ATTEMPT`
  TRY_ATTEMPT=$((TRY_ATTEMPT+1))
  echo "Job status: '$STATUS'"
done

echo "Getting status for job"
curl -s -G -w "Reporting status for job:  http_code=%{http_code}\n" --http1.1 \
  $GET_JOB_URL \
  -H 'Accept: */*' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H "Authorization: Bearer ${FSSESSIONID}" \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H 'User-Agent: roskelleycj/1.0 (manual)' \
  -H 'cache-control: no-cache' -o $PHASE-$SYSTEM_NAME-report


echo "Found warnings: `jq '.|.warnings' $PHASE-$SYSTEM_NAME-report`"
echo "Found errors:  `jq '.|.errors' $PHASE-$SYSTEM_NAME-report`"

ERRORS=`jq '.|.errors|length' $PHASE-$SYSTEM_NAME-report`
if [ $ERRORS -ne 0 ];
then
  exit 1
fi
