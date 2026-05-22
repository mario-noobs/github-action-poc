import { Client } from 'pg'

import { env } from './env'

async function connect(): Promise<Client> {
  const client = new Client({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    database: env.db.database,
  })
  await client.connect()
  return client
}

export async function seedOrgAndTeam(): Promise<void> {
  const client = await connect()
  try {
    await client.query(
      `INSERT INTO organizations (id, name)
       VALUES ($1, $2)
       ON CONFLICT (id) DO NOTHING`,
      [env.testOrgId, 'e2e-org'],
    )
    await client.query(
      `INSERT INTO teams (id, name, organization_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (id) DO NOTHING`,
      [env.testTeamId, 'e2e-team', env.testOrgId],
    )
    await client.query(
      `INSERT INTO severities (id, name, team_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (id) DO NOTHING`,
      ['CRITICAL', 'Critical', env.testTeamId],
    )
    // Seed a MANUAL subscription with CHARGE overage so the check-creation limit guard passes.
    await client.query(
      `INSERT INTO subscription_plans (id, name, plan_type, source, period)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (id) DO NOTHING`,
      ['e2e-plan-1', 'E2E Plan', 'BASE_PLAN', 'MANUAL', 'monthly'],
    )
    await client.query(
      `INSERT INTO plan_resource_limits (id, subscription_plan_id, resource_type, included_quantity, overage_price, overage_stripe_price_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (id) DO NOTHING`,
      ['e2e-limit-check', 'e2e-plan-1', 'CHECK', 10000, 0, 'price_e2e'],
    )
    await client.query(
      `INSERT INTO subscriptions (id, organization_id, status, source, overage_policy_fixed_resources)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (id) DO NOTHING`,
      ['e2e-sub-1', env.testOrgId, 'active', 'MANUAL', 'CHARGE'],
    )
    await client.query(
      `INSERT INTO subscription_items (id, subscription_id, stripe_price_id, subscription_plan_id, item_type, status)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (id) DO NOTHING`,
      ['e2e-sub-item-1', 'e2e-sub-1', 'price_e2e', 'e2e-plan-1', 'BASE_PLAN', 'active'],
    )
  } finally {
    await client.end()
  }
}

export async function seedWorker(location = 'eu', workerId = 'e2e-worker-eu'): Promise<string> {
  const client = await connect()
  try {
    await client.query(
      `INSERT INTO workers (id, ip, type, location, region)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (id) DO NOTHING`,
      [workerId, '127.0.0.1', 'http', location, location],
    )
    return workerId
  } finally {
    await client.end()
  }
}

export async function resetState(): Promise<void> {
  const client = await connect()
  try {
    // Order matters: dependents first
    await client.query(`DELETE FROM checks WHERE team_id = $1`, [env.testTeamId])
    await client.query(`DELETE FROM escalation_contacts WHERE escalation_step_id IN (SELECT id FROM escalation_steps WHERE escalation_id IN (SELECT id FROM escalations WHERE team_id = $1))`, [env.testTeamId])
    await client.query(`DELETE FROM escalation_steps WHERE escalation_id IN (SELECT id FROM escalations WHERE team_id = $1)`, [env.testTeamId])
    await client.query(`DELETE FROM escalations WHERE team_id = $1`, [env.testTeamId])
  } finally {
    await client.end()
  }
}
