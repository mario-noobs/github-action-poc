import { test, expect } from './_setup'

import { buildCheck } from '../fixtures/check-builder'
import { buildPolicy } from '../fixtures/policy-builder'
import { waitForIncident, waitForNotifications } from '../fixtures/wait'

test('issue reappear during recovery resumes the escalation', async ({ portal, sink, flaky }) => {
  const policy = await portal.createEscalation(
    buildPolicy('reappear-during-recovery', [
      { stepDelay: 0, contactEmail: 'first@example.com' },
      { stepDelay: 5, contactEmail: 'second@example.com' },
    ]),
  )
  const check = await portal.createCheck(
    buildCheck(policy.id, { recoverPeriod: 60, interval: 15 }),
  )

  await flaky.unhealthy()
  const incident = await waitForIncident(portal, check.id, { timeoutMs: 90_000 })
  await waitForNotifications(
    sink,
    (n) => n.filter((x) => x.incidentId === incident.id).length >= 1,
    { timeoutMs: 30_000, message: 'first notification before recovery' },
  )

  await flaky.healthy()
  await new Promise((r) => setTimeout(r, 30_000))

  await flaky.unhealthy()

  const both = await waitForNotifications(
    sink,
    (n) => n.filter((x) => x.incidentId === incident.id).length >= 2,
    { timeoutMs: 60_000, message: 'second notification after reappear' },
  )
  expect(both.filter((x) => x.incidentId === incident.id).length).toBeGreaterThanOrEqual(2)
})
