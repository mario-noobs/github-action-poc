import { test, expect } from './_setup'

import { buildCheck } from '../fixtures/check-builder'
import { buildPolicy } from '../fixtures/policy-builder'
import { waitForIncident, waitForNotifications } from '../fixtures/wait'

test('two-step policy fires both notifications with the configured delay', async ({ portal, sink, flaky }) => {
  const policy = await portal.createEscalation(
    buildPolicy('multi-step-with-delays', [
      { stepDelay: 0, contactEmail: 'first@example.com' },
      { stepDelay: 5, contactEmail: 'second@example.com' },
    ]),
  )
  const check = await portal.createCheck(buildCheck(policy.id))

  await flaky.unhealthy()
  const incident = await waitForIncident(portal, check.id, { timeoutMs: 90_000 })

  const all = await waitForNotifications(
    sink,
    (n) => n.filter((x) => x.incidentId === incident.id).length >= 2,
    { timeoutMs: 60_000, message: 'expected both step notifications' },
  )

  const forIncident = all.filter((x) => x.incidentId === incident.id)
  expect(forIncident.length).toBeGreaterThanOrEqual(2)
  expect(forIncident[0]?.contact).toContain('first@example.com')
  expect(forIncident[1]?.contact).toContain('second@example.com')
})
