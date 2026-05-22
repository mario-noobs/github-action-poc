#!/bin/bash
# Creates SQS queues and SSM parameters that the backend expects.
# DynamoDB tables are created by the app migration process.
set -euo pipefail

ENDPOINT=http://localhost:4566
REGION=ap-southeast-1
export AWS_DEFAULT_REGION=$REGION
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo "[init-aws] creating SQS queues"
awslocal sqs create-queue --queue-name webhook-queue --endpoint-url $ENDPOINT || true
awslocal sqs create-queue --queue-name billing-queue --endpoint-url $ENDPOINT || true
awslocal sqs create-queue --queue-name NonProd-usage-events-queue-NonProd --endpoint-url $ENDPOINT || true

echo "[init-aws] done"
