# Test-runner image: ships Playwright + the e2e test suite.
# Browsers are NOT installed — we only use the request fixture.
FROM node:20-bookworm-slim AS deps

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.20.0 --activate

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod=false

FROM node:20-bookworm-slim AS runner

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable \
  && corepack prepare pnpm@10.20.0 --activate

COPY --from=deps /app/node_modules ./node_modules
COPY package.json pnpm-lock.yaml playwright.config.ts tsconfig.json ./
COPY tests ./tests
COPY fixtures ./fixtures

ENV NODE_ENV=test
ENV CI=1

CMD ["pnpm", "test"]
