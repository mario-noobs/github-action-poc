import { test, expect } from './_setup'

import { buildCheck } from '../fixtures/check-builder'
import { buildPolicy } from '../fixtures/policy-builder'
import { waitForIncident, waitForNotifications } from '../fixtures/wait'

test('check failure fires the first escalation step', async ({ portal, sink, flaky }) => {
  const policy = await portal.createEscalation(
    buildPolicy('start-incident', [{ stepDelay: 0, contactEmail: 'first@example.com' }]),
  )
  const check = await portal.createCheck(buildCheck(policy.id))

  await flaky.unhealthy()

  const incident = await waitForIncident(portal, check.id, { timeoutMs: 90_000 })

  const notifications = await waitForNotifications(
    sink,
    (n) => n.some((x) => x.incidentId === incident.id),
    { timeoutMs: 30_000, message: 'expected at least one notification for the new incident' },
  )

  expect(notifications.length).toBeGreaterThanOrEqual(1)
  expect(notifications[0]?.incidentId).toBe(incident.id)
})
