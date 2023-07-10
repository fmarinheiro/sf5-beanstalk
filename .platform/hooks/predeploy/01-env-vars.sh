#!/bin/bash

set -euxo pipefail

APP_ENVIRONMENT=$(/opt/elasticbeanstalk/bin/get-config environment | jq ".APP_ENVIRONMENT" --raw-output)
RDS_SECRET_CREDENTIALS=$(/opt/elasticbeanstalk/bin/get-config environment | jq ".RDS_SECRET_CREDENTIALS")
SECRETS_REGION=us-east-1

if [[ -z ${RDS_SECRET_CREDENTIALS} ]]; then
  echo "ERROR: RDS_SECRET_CREDENTIALS environment variable is not defined! Aborting setup..."
  exit 1
fi

if [[ -z ${SECRETS_REGION} ]]; then
  echo "ERROR: SECRETS_REGION environment variable is not defined! Aborting setup..."
  exit 1
fi
echo $APP_ENVIRONMENT


echo "Retrieving  secrets from ${RDS_SECRET_CREDENTIALS}..."
secrets=$(aws --region "${SECRETS_REGION}" --output json secretsmanager get-secret-value --secret-id \
        $(echo $RDS_SECRET_CREDENTIALS | sed "s/\"//g" ) | jq '.["SecretString"]' --raw-output)


DATABASE_USER=$(echo $secrets | jq '.["username"]' --raw-output)
DATABASE_PASSWORD=$(echo $secrets | jq '.["password"]' --raw-output)
DATABASE_HOST=$(/opt/elasticbeanstalk/bin/get-config environment | jq ".RDS_HOST" --raw-output)
DATABASE_NAME=$(/opt/elasticbeanstalk/bin/get-config environment | jq ".RDS_DB" --raw-output)

DATABASE_URL="mysql://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}:3306/${DATABASE_NAME}?serverVersion=mariadb-10.6.10"

echo "DATABASE_URL=\"${DATABASE_URL}\"" > ./.env.${APP_ENVIRONMENT}