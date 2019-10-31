#!/usr/bin/env bash -e

# Poor mans credential management.  If we really do this, we will create/manage a service account user for the creds

echo "Generate a 15 minute session"
aws sts get-session-token --duration-seconds 900 > /tmp/token.json

cp aws-creds-spec /tmp/temp-aws-creds
AWS_ACCESS_KEY_ID=`jq -r '.|.Credentials.AccessKeyId' /tmp/token.json`
sed -i '' -e "s|aws_access_key_id.*|aws_access_key_id=$AWS_ACCESS_KEY_ID|g" /tmp/temp-aws-creds

AWS_SECRET_ACCESS_KEY=`jq -r '.|.Credentials.SecretAccessKey' /tmp/token.json`
sed -i '' -e "s|aws_secret_access_key.*|aws_secret_access_key=$AWS_SECRET_ACCESS_KEY|g" /tmp/temp-aws-creds

AWS_SECURITY_TOKEN=`jq -r '.|.Credentials.SessionToken' /tmp/token.json`
sed -i '' -e "s|^aws_security_token.*$|aws_security_token=$AWS_SECURITY_TOKEN|g" /tmp/temp-aws-creds

EXPIRATION=`jq -r '.|.Credentials.Expiration' /tmp/token.json`
sed -i '' -e "s|expiration.*|expiration=$AWS_SECURITY_TOKEN|g" /tmp/temp-aws-creds

AWS_CREDENTIALS_FILE=`base64 /tmp/temp-aws-creds`
FSSESSIONID=`jq -r '.|.session.sessionId' ~/.paas-portal`
cat creds-spec.yml|sed -e "s|AWS_CREDENTIALS_FILE:.*|AWS_CREDENTIALS_FILE: ${AWS_CREDENTIALS_FILE}|"|sed -e "s|FSSESSIONID:.*|FSSESSIONID: ${FSSESSIONID}|">/tmp/gen-creds-spec.yml
codefresh patch context -f /tmp/gen-creds-spec.yml
