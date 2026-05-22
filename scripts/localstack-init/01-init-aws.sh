#!/bin/bash
# Creates SQS queues and DynamoDB tables that the backend expects on startup.
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

# Simple hash-key tables (id → String)
for table in incidents incident-events webhook-events status-pages status-reports; do
  awslocal dynamodb create-table \
    --table-name "${PREFIX}-${table}" \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url $ENDPOINT || true
done

# subscription-usages-v2: composite key (organizationId + sk)
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

echo "[init-aws] done"
