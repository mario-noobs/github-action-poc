function required(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`env ${name} is required`)
  return v
}

function optional(name: string, fallback: string): string {
  return process.env[name] ?? fallback
}

export const env = {
  portalUrl: optional('PORTAL_URL', 'http://localhost:8080'),
  serverlessUrl: optional('SERVERLESS_URL', 'http://localhost:3339'),
  flakyUrl: optional('FLAKY_URL', 'http://flaky-target.local'),
  jwtSecret: required('JWT_SECRET'),
  testUserId: optional('TEST_USER_ID', 'e2e-user-1'),
  testFirebaseId: optional('TEST_FIREBASE_ID', 'e2e-firebase-1'),
  testOrgId: optional('TEST_ORG_ID', 'e2e-org-1'),
  testTeamId: optional('TEST_TEAM_ID', 'e2e-team-1'),
  db: {
    host: optional('DB_HOST', 'localhost'),
    port: Number(optional('DB_PORT', '5432')),
    user: optional('DB_USER', 'test'),
    password: optional('DB_PASSWORD', 'test'),
    database: optional('DB_NAME', 'monitoringdog'),
  },
}
