# user-portal-backend e2e suite

End-to-end test suite for the **escalation flow** in [`user-portal-backend`](../user-portal-backend). The suite is packaged as a Docker image and orchestrated by GitHub Actions; given image tags for `portal`, `orchestrator`, `worker`, and `serverless-functions`, it spins up the full stack (Postgres, Redis, LocalStack, Inngest, plus a controllable HTTP target) and drives the escalation flow through the public API.

## What it tests

Five scenarios exercising the orchestrator → Inngest → escalation pipeline end-to-end. Every test goes through the public HTTP API only — no internal imports.

| Scenario | What it proves |
|---|---|
| `start-incident.spec.ts` | A failing check produces an incident and fires the first escalation step. |
| `resolve-cancels.spec.ts` | An auto-resolve mid-flight cancels subsequent steps (Inngest `cancelOn`). |
| `reappear-during-recovery.spec.ts` | An issue reappearing during the recovery window resumes the escalation (`step.waitForEvent('incident/reappeared')`). |
| `acknowledge-cancels.spec.ts` | Acknowledging an incident mid-flight cancels remaining steps. |
| `multi-step-with-delays.spec.ts` | A multi-step policy fires every step in order with the configured delay. |

## How it works

```
                                            ┌────────────────┐
                                            │   inngest      │
                                            │   dev server   │
                                            └────────────────┘
                                                    ▲
                                                    │ events
flaky-target.local ◀─ probes ─ worker ─▶ orchestrator ─▶ serverless-functions ─▶ /dev/notifications
                                  │                              │
                                  ▼                              ▼
                              postgres                       localstack
                              (policies)                     (DynamoDB)
```

- The suite creates an **escalation policy** and a **check** pointing at `http://flaky-target.local/health`, both via `POST /escalation` and `POST /check`.
- The `flaky-target` container's HTTP response can be toggled (`POST /control { status: 500 }`) — the real worker probes it, the real orchestrator confirms the incident, the real escalation flow fires.
- Notifications are asserted via `GET /dev/notifications` on `serverless-functions` (gated by `MOCK_NOTIFICATIONS=1`).

## Running locally

You need:
- Docker (with Compose v2)
- Image tags for the four backend apps already pushed to a registry you can pull from

```bash
docker login ghcr.io                     # if pulling from a private registry

export PORTAL_IMAGE=ghcr.io/<owner>/user-portal-backend:<tag>
export ORCHESTRATOR_IMAGE=ghcr.io/<owner>/orchestrator:<tag>
export WORKER_IMAGE=ghcr.io/<owner>/worker:<tag>
export SERVERLESS_IMAGE=ghcr.io/<owner>/serverless-functions:<tag>
export E2E_RUNNER_IMAGE=ghcr.io/<owner>/<this-repo>/e2e-tests:latest

./scripts/run-e2e.sh
```

The script boots compose, runs the suite, captures `logs/` and `reports/`, then tears down. Total runtime: ~3–5 min cold, ~1–2 min warm.

To run the **tests** locally without rebuilding the runner image (i.e., against the local source):

```bash
pnpm install
PORTAL_IMAGE=... ORCHESTRATOR_IMAGE=... WORKER_IMAGE=... SERVERLESS_IMAGE=... \
  docker compose -f docker-compose.e2e.yml up --wait \
    postgres redis localstack flaky-target migrate \
    portal orchestrator worker serverless-functions inngest

JWT_SECRET=e2e-jwt-secret-do-not-use-in-prod \
PORTAL_URL=http://localhost:8080 \
SERVERLESS_URL=http://localhost:3339 \
FLAKY_URL=http://localhost \
  pnpm test
```

(Local-mode requires you to expose the relevant ports on the host — add `ports:` mappings to `docker-compose.e2e.yml` for `portal:8080`, `serverless-functions:3339`, and `flaky-target:80`.)

## Triggering from GitHub Actions

The workflow is `workflow_dispatch` + `workflow_call`. From the `user-portal-backend` repo's CI, after pushing PR images:

```yaml
- name: Run e2e against PR images
  run: |
    gh workflow run e2e.yml --repo <owner>/<this-repo> \
      -f portal_image=ghcr.io/<owner>/user-portal-backend:sha-${{ github.sha }} \
      -f orchestrator_image=ghcr.io/<owner>/orchestrator:sha-${{ github.sha }} \
      -f worker_image=ghcr.io/<owner>/worker:sha-${{ github.sha }} \
      -f serverless_image=ghcr.io/<owner>/serverless-functions:sha-${{ github.sha }}
  env:
    GH_TOKEN: ${{ secrets.E2E_DISPATCH_PAT }}
```

`GITHUB_TOKEN` cannot dispatch workflows across repos — you need a Personal Access Token (or a GitHub App) with `actions:write` on this repo, stored as a secret named `E2E_DISPATCH_PAT`.

## Backend-repo prerequisites

These need to land in `user-portal-backend` before this suite can run against PR images. They are **not** owned by this repo.

### 1. `apps/serverless-functions/Dockerfile`

`serverless-functions` has no Dockerfile today (in prod it deploys via CDK to Lambda; in `__workflows__` it's spawned on the host). For the e2e model to work, it needs to run as a container so Inngest can reach `/api/inngest`. Suggested sketch:

```Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm@10.20.0
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm exec nx run serverless-functions:build --configuration=production

FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm@10.20.0
COPY --from=builder /app/dist/apps/serverless-functions ./
RUN pnpm install --frozen-lockfile --prod
EXPOSE 3339
CMD ["node", "dev.js"]
```

`dev.js` is the entrypoint that serves `/api/inngest` + `/dev/notifications` (see `apps/serverless-functions/src/serve/dev.ts`).

### 2. PR workflow on GitHub

The backend's PR workflow must:
1. Build all four Docker images (`portal`, `orchestrator`, `worker`, `serverless-functions`).
2. Push them to ghcr.io with the commit SHA as the tag.
3. Invoke this repo's `e2e.yml` workflow (snippet above).

## Auth shortcut

This suite signs its own JWTs in `fixtures/auth.ts` using a shared `JWT_SECRET`. The token sets `internalRole: 'super_admin'`, which short-circuits the permission guard (`apps/user-portal-backend/src/commons/guard/permissions.guards.ts:44`) — no need to seed RBAC tables.

The org and team IDs are inserted directly into Postgres via `fixtures/seed.ts` because the controllers' usecases need a real team row to attach the policy/check to.

If the backend ever DB-validates the JWT's `userId` against the `users` table, `seed.ts` will need to insert a user row too.

## Repository layout

```
.
├── docker-compose.e2e.yml          # full stack
├── Dockerfile                      # runner image
├── flaky-target/                   # controllable HTTP target
├── fixtures/                       # Playwright helpers
├── playwright.config.ts
├── scripts/
│   ├── run-e2e.sh                  # boot → run → log → teardown
│   └── localstack-init/            # AWS table setup, runs on LocalStack ready
├── tests/                          # 5 scenarios
└── .github/workflows/
    ├── e2e.yml                     # workflow_dispatch / workflow_call
    └── runner-image.yml            # build & push the runner image
```

## Known limitations / next steps

- **No frontend coverage** — by design. Add Playwright UI tests later if needed.
- **Notifier is mocked** — `MOCK_NOTIFICATIONS=1` redirects everything to an in-memory sink. To assert on real email/Slack delivery, swap to MailHog + a webhook receiver.
- **Single worker location** — only `eu` is seeded. Tests that need geographic diversity will need to seed more rows in `workers`.
- **Test data is leaked between scenarios** in DynamoDB and Inngest. `resetState()` only wipes Postgres. If parallelism is enabled later, DynamoDB cleanup will be needed too.
