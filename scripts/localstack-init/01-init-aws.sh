#!/bin/bash
# Creates SQS queues and DynamoDB tables (with GSIs) that the backend expects on startup.
set -euo pipefail

ENDPOINT=http://localhost:4566
REGION=ap-southeast-1
PREFIX=${DYNAMO_TABLE_PREFIX:-development}
export AWS_DEFAULT_REGION=$REGION
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo "[init-aws] creating SQS queues"
awslocal sqs create-queue --queue-name webhook-queue --endpoint-url $ENDPOINT || true
awslocal sqs create-queue --queue-name billing-queue --endpoint-url $ENDPOINT || true
awslocal sqs create-queue --queue-name NonProd-usage-events-queue-NonProd --endpoint-url $ENDPOINT || true

echo "[init-aws] creating DynamoDB tables (prefix: $PREFIX)"

# incidents — hash-only table
awslocal dynamodb create-table \
  --table-name "${PREFIX}-incidents" \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=checkId,AttributeType=S \
    AttributeName=teamId,AttributeType=S \
    AttributeName=status,AttributeType=S \
    AttributeName=createdAt,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --global-secondary-indexes '[
    {"IndexName":"checkId-index","KeySchema":[{"AttributeName":"checkId","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"checkId-createdAt-index","KeySchema":[{"AttributeName":"checkId","KeyType":"HASH"},{"AttributeName":"createdAt","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"teamId-index","KeySchema":[{"AttributeName":"teamId","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"teamId-createdAt-index","KeySchema":[{"AttributeName":"teamId","KeyType":"HASH"},{"AttributeName":"createdAt","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"status-index","KeySchema":[{"AttributeName":"status","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}
  ]' \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url $ENDPOINT || true

# incident-events — composite key (id + createdAt)
awslocal dynamodb create-table \
  --table-name "${PREFIX}-incident-events" \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=incidentId,AttributeType=S \
    AttributeName=createdAt,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
    AttributeName=createdAt,KeyType=RANGE \
  --global-secondary-indexes '[
    {"IndexName":"incidentId-index","KeySchema":[{"AttributeName":"incidentId","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"incidentId-createdAt-index","KeySchema":[{"AttributeName":"incidentId","KeyType":"HASH"},{"AttributeName":"createdAt","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}
  ]' \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url $ENDPOINT || true

# status-pages — composite key (id + createdAt)
awslocal dynamodb create-table \
  --table-name "${PREFIX}-status-pages" \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=teamId,AttributeType=S \
    AttributeName=subDomain,AttributeType=S \
    AttributeName=createdAt,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
    AttributeName=createdAt,KeyType=RANGE \
  --global-secondary-indexes '[
    {"IndexName":"teamId-index","KeySchema":[{"AttributeName":"teamId","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"teamId-createdAt-index","KeySchema":[{"AttributeName":"teamId","KeyType":"HASH"},{"AttributeName":"createdAt","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"subDomain-index","KeySchema":[{"AttributeName":"subDomain","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}
  ]' \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url $ENDPOINT || true

# status-reports — composite key (id + createdAt)
awslocal dynamodb create-table \
  --table-name "${PREFIX}-status-reports" \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=statusPageId,AttributeType=S \
    AttributeName=createdAt,AttributeType=S \
    AttributeName=reportTypeCreatedAt,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
    AttributeName=createdAt,KeyType=RANGE \
  --global-secondary-indexes '[
    {"IndexName":"statusPageId-index","KeySchema":[{"AttributeName":"statusPageId","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"statusPageId-createdAt-index","KeySchema":[{"AttributeName":"statusPageId","KeyType":"HASH"},{"AttributeName":"createdAt","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"statusPageId-reportType-createdAt-index","KeySchema":[{"AttributeName":"statusPageId","KeyType":"HASH"},{"AttributeName":"reportTypeCreatedAt","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}
  ]' \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url $ENDPOINT || true

# subscription-usages-v2 — composite key (organizationId + sk), no GSIs
awslocal dynamodb create-table \
  --table-name "${PREFIX}-subscription-usages-v2" \
  --attribute-definitions \
    AttributeName=organizationId,AttributeType=S \
    AttributeName=sk,AttributeType=S \
  --key-schema \
    AttributeName=organizationId,KeyType=HASH \
    AttributeName=sk,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url $ENDPOINT || true

# webhook-events — composite key (id + createdAt)
awslocal dynamodb create-table \
  --table-name "${PREFIX}-webhook-events" \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=webhookId,AttributeType=S \
    AttributeName=createdAt,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
    AttributeName=createdAt,KeyType=RANGE \
  --global-secondary-indexes '[
    {"IndexName":"webhookId-index","KeySchema":[{"AttributeName":"webhookId","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"webhookId-createdAt-index","KeySchema":[{"AttributeName":"webhookId","KeyType":"HASH"},{"AttributeName":"createdAt","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}
  ]' \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url $ENDPOINT || true

echo "[init-aws] done"
