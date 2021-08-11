#!/usr/bin/env bash

set -euo pipefail

function finish {
    echo "Printing docker-compose logs"
    docker-compose -f docker-compose.yml -f docker-compose.verification.yml logs
#    echo "Stopping docker setup"
#    docker-compose -f docker-compose.yml -f docker-compose.verification.yml kill
}
trap finish EXIT

echo "Starting docker setup"
docker-compose -f docker-compose.yml -f docker-compose.verification.yml up -d

echo "Waiting for dependencies and app to start"
sleep 30

API_TOKEN=$(grep API_TOKEN .env | cut -d'=' -f2)
DOCS_USER=$(grep DOCS_USER .env | cut -d'=' -f2)
DOCS_PASSWORD=$(grep DOCS_PASSWORD .env | cut -d'=' -f2)

echo "Checking health check endpoint"
curl --fail --show-error http://localhost:8081/health > /dev/null
echo "Checking metrics endpoint"
curl --fail --show-error http://localhost:8081/metrics > /dev/null
echo "Checking openapi specification and swagger ui"
curl --fail --show-error --user "${DOCS_USER}:${DOCS_PASSWORD}" http://localhost:8080/docs/api-docs > /dev/null
curl --fail --show-error --user "${DOCS_USER}:${DOCS_PASSWORD}" http://localhost:8080/docs/swagger-ui.html > /dev/null
curl --fail --show-error --header "Authorization: Bearer ${API_TOKEN}" http://localhost:8080/api/hello/world > /dev/null
