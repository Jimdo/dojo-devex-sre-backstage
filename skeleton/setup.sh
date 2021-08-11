#!/usr/bin/env bash
set -euo pipefail

make wl

set +u
DRY_RUN=${DRY_RUN:false}
if [ $DRY_RUN ]; then
  echo "Running in dry run mode, will not modify state outside this repository"
fi

OS=$(uname)
if [ "${OS}" == "Darwin" ]; then
  echo "Running on MacOS"
  SED_IN_PLACE=(-i "")
else
  echo "Running on Linux"
  SED_IN_PLACE=(-i)
fi

if [ -z "${TEAM}" ]; then
  echo "We're going to customize this repository now. Please enter the following information:"
  echo -n "Team name (e.g. web): "
  read TEAM
fi
if [ -z "${SERVICE_NAME}" ]; then
  echo -n "Service name (e.g. website-service): "
  read SERVICE_NAME
fi
PACKAGE_NAME=$(echo "${SERVICE_NAME}" | sed 's/-//g')
if [ -z "${SLACK_CHANNEL}" ]; then
  echo -n "Slack channel (e.g. #web-builds) "
  read SLACK_CHANNEL
fi
echo ""

echo "This service is owned by team ${TEAM} and named ${SERVICE_NAME}"
echo "The package name will be ${PACKAGE_NAME}"
echo "Notifications will go to ${SLACK_CHANNEL}"
echo ""

if [ -z "${CONTINUE}" ]; then
  echo -n "This correct? [Y/n] "
  read CONTINUE
  if [[ $CONTINUE =~ ^[Nn]$ ]]
  then
    echo "Aborting"
    exit 1
  fi
  echo ""
fi
set +u

function assertServiceDoesNotExist {
  set +e
  OUTPUT=$(./wl service list | grep "${1}")
  set -e
  if [ -n "${OUTPUT}" ]; then
    echo "Service ${1}, already exists - aborting"
    echo "Output from wl service list:"
    echo "${OUTPUT}"
    exit 1
  fi
}

echo "Ensuring service does not yet exist"
assertServiceDoesNotExist "${SERVICE_NAME}-stage"
assertServiceDoesNotExist "${SERVICE_NAME}-prod"
echo ""

echo "Replacing placeholders"
echo ""
FILES=$(find . -name '*.kt' -o -name 'Makefile' -o -name '*.tf' -o -name '*.yml' -o -name '*.kts' -o -name '*.md')
sed "${SED_IN_PLACE[@]}" -r "s/spring-boot-template/${SERVICE_NAME}/g" ${FILES}
sed "${SED_IN_PLACE[@]}" -r "s/template/${PACKAGE_NAME}/g" ${FILES}
sed "${SED_IN_PLACE[@]}" -r "s/#dev-bots/${SLACK_CHANNEL}/g" ${FILES}
sed "${SED_IN_PLACE[@]}" "s/developers/${TEAM}/g" Makefile
sed "${SED_IN_PLACE[@]}" -r "s/developers\/spring-boot-template/${TEAM}\/${SERVICE_NAME}/" .github/workflows/*.yml
git mv "src/main/kotlin/com/jimdo/template" "src/main/kotlin/com/jimdo/${PACKAGE_NAME}"
git mv "src/test/kotlin/com/jimdo/template" "src/test/kotlin/com/jimdo/${PACKAGE_NAME}"
git rm .github/workflows/dryrun.yml

echo "Verifying nothing was forgotten"
set +e
REMAINING=$(git grep -i template -- './*' ':!README.md' ':!setup.sh')
set -e
if [ -n "${REMAINING}" ]; then
  echo "Something went wrong with the processing - the word template was still found outside the README.md"
  echo ""
  echo "Remaining occurrences:"
  echo "${REMAINING}"
  exit 1
fi
echo "Every occurrence of template except for README.md was removed, good"
echo ""

function assertVaultDoesNotExist {
  set +e
  OUTPUT=$(./wl vault read "${1}" 2>&1)
  set -e
  if [[ "${OUTPUT}" =~ "permission denied" ]]; then
    echo "Vault ${1} got permission denied, continuing anyways!"
    return
  fi
  if [[ ! "${OUTPUT}" =~ "error: No value found at" ]]; then
    echo "Vault ${1} already exist, aborting!"
    exit 1
  fi
}

echo "Setting up vault"
echo "Checking if vaults already exist"
assertVaultDoesNotExist "${TEAM}/${SERVICE_NAME}-local"
assertVaultDoesNotExist "${TEAM}/${SERVICE_NAME}-stage"
assertVaultDoesNotExist "${TEAM}/${SERVICE_NAME}-prod"
echo "All vaults do not exist, continuing"
if [ $DRY_RUN ]; then
  echo "In dry run, not creating vaults"
else
  ./wl vault write "${TEAM}/${SERVICE_NAME}-local" DATABASE_ENDPOINT=localhost DATABASE_NAME="${PACKAGE_NAME}_dev" DATABASE_PORT=5432 DATABASE_USER=postgres DATABASE_PASSWORD=postgres DOCS_USER=docs DOCS_PASSWORD=jimdo API_USER=apiuser API_TOKEN=token SPRING_PROFILES_ACTIVE=dev OTEL_TRACES_EXPORTER=none OTEL_METRICS_EXPORTER=none 
  ./wl vault write "${TEAM}/${SERVICE_NAME}-stage" OTEL_EXPORTER_ZIPKIN_ENDPOINT=https://opentelemetry-collector-stable.jimdo-platform.net:9411/api/v2/spans OTEL_TRACES_EXPORTER=zipkin DOCS_USER=docs DOCS_PASSWORD="$(openssl rand -base64 30 | tr -d '\n')" OTEL_METRICS_EXPORTER=none API_USER=apiuser API_TOKEN="$(openssl rand -base64 30 | tr -d '\n')"
  ./wl vault write "${TEAM}/${SERVICE_NAME}-prod" OTEL_EXPORTER_ZIPKIN_ENDPOINT=https://opentelemetry-collector-prod.jimdo-platform.net:9411/api/v2/spans OTEL_TRACES_EXPORTER=zipkin DOCS_USER=docs  DOCS_PASSWORD="$(openssl rand -base64 30 | tr -d '\n')" OTEL_METRICS_EXPORTER=none API_USER=apiuser API_TOKEN="$(openssl rand -base64 30 | tr -d '\n')"
fi
echo ""

echo "Creationg OpenAPI generator client"
if [ $DRY_RUN ]; then
  echo "In dry run, not creationg openapi generator client"
else
  eval "$(wl vault read developers/openapi-generator-prod -o env | grep HTTP_BASIC_USER)"
  eval "$(wl vault read developers/openapi-generator-prod -o env | grep HTTP_BASIC_PASS)"
  curl --fail --silent --show-error --header "Content-Type: application/json" --request POST --data "{\"name\": \"${SERVICE_NAME}\", \"slackChannel\": \"${SLACK_CHANNEL}\"}" "https://${HTTP_BASIC_USER}:${HTTP_BASIC_PASS}@openapi-generator-prod.jimdo-platform.net/clients"
fi
echo ""

echo "Replacing README"
git rm -f README.md
git mv README.service.md README.md
echo ""

echo "Deleting setup script"
rm setup.sh
echo ""

echo "Done, enjoy your new project"
