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

# https://yoozc195t9.execute-api.us-east-1.amazonaws.com/v1/check/dougireton-paas-tutorial/dev/jobs
#POST_JOB_URL=https://api.fsdpt.org/service_provisioning/$PHASE/$BLUEPRINT_NAME/$SYSTEM_NAME/jobs
POST_JOB_URL=https://yoozc195t9.execute-api.us-east-1.amazonaws.com/v1/$PHASE/$BLUEPRINT_NAME/$SYSTEM_NAME/jobs

echo "Submitting job: $POST_JOB_URL"

HTTP_STATUS=`curl -s -w "%{http_code}" \
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
        \"definition\":{}
    }}" -o post-job`

echo "http status: $HTTP_STATUS"

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
STATUS="INPROGRESS"
while [ $STATUS != "CLOSED" ]
do
  sleep 3

  curl -s -X GET \
  $GET_JOB_STATUS_URL \
  -H 'Accept: */*' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H "Authorization: Bearer ${FSSESSIONID}" \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H 'Host: api.fsdpt.org' \
  -H 'User-Agent: roskelleycj/1.0 (manual)' \
  -H 'cache-control: no-cache' >status

  STATUS=`jq -r '.|.executionStatus' status`
  echo "Job status: '$STATUS'"
done

echo "Reporting status for job"
curl -s -X GET \
  $GET_JOB_URL \
  -H 'Accept: */*' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H "Authorization: Bearer ${FSSESSIONID}" \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H 'Host: api.fsdpt.org' \
  -H 'User-Agent: roskelleycj/1.0 (manual)' \
  -H 'cache-control: no-cache' >report


echo "Found warnings: `jq '.|.warnings' report`"
echo "Found errors:  `jq '.|.errors' report`"

ERRORS=`jq '.|.errors|length' report`
if [ $ERRORS -ne 0 ];
then
  exit 1
fi
