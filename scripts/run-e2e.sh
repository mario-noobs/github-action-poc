#!/bin/bash
# Boots the e2e stack, runs the test suite, captures logs, tears down.
#
# Required environment variables:
#   PORTAL_IMAGE, ORCHESTRATOR_IMAGE, WORKER_IMAGE, SERVERLESS_IMAGE
# Optional:
#   E2E_RUNNER_IMAGE (defaults to the latest e2e-tests image)
#   JWT_SECRET (defaults to a hardcoded test value)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Load .env if present (lets docker compose and this script share the same config)
if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$REPO_ROOT/.env"
  set +a
fi

COMPOSE="docker compose -f docker-compose.e2e.yml"

mkdir -p logs reports

echo "==> validating image inputs"
: "${PORTAL_IMAGE:?PORTAL_IMAGE is required}"
: "${ORCHESTRATOR_IMAGE:?ORCHESTRATOR_IMAGE is required}"
: "${WORKER_IMAGE:?WORKER_IMAGE is required}"
: "${SERVERLESS_IMAGE:?SERVERLESS_IMAGE is required}"
echo "    PORTAL_IMAGE=$PORTAL_IMAGE"
echo "    ORCHESTRATOR_IMAGE=$ORCHESTRATOR_IMAGE"
echo "    WORKER_IMAGE=$WORKER_IMAGE"
echo "    SERVERLESS_IMAGE=$SERVERLESS_IMAGE"
echo "    E2E_RUNNER_IMAGE=${E2E_RUNNER_IMAGE:-(default)}"

cleanup() {
  local exit_code=$?
  echo "==> capturing logs"
  $COMPOSE --profile run logs --no-color > logs/compose.log 2>&1 || true
  $COMPOSE --profile run logs --no-color portal > logs/portal.log 2>&1 || true
  $COMPOSE --profile run logs --no-color orchestrator > logs/orchestrator.log 2>&1 || true
  $COMPOSE --profile run logs --no-color worker > logs/worker.log 2>&1 || true
  $COMPOSE --profile run logs --no-color serverless-functions > logs/serverless.log 2>&1 || true
  $COMPOSE --profile run logs --no-color inngest > logs/inngest.log 2>&1 || true
  echo "==> tearing down"
  $COMPOSE --profile run down -v --remove-orphans || true
  exit $exit_code
}
trap cleanup EXIT

echo "==> bringing up infra + apps (without runner)"
$COMPOSE up --wait \
  postgres redis localstack flaky-target migrate \
  portal orchestrator worker serverless-functions inngest

echo "==> running e2e suite"
$COMPOSE --profile run run --rm e2e-runner
