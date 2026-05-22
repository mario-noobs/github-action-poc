import { test, expect } from './_setup'

import { buildCheck } from '../fixtures/check-builder'
import { buildPolicy } from '../fixtures/policy-builder'
import { expectStableCount, waitForIncident, waitForNotifications } from '../fixtures/wait'

test('auto-resolve mid-flight cancels subsequent escalation steps', async ({ portal, sink, flaky }) => {
  const policy = await portal.createEscalation(
    buildPolicy('resolve-cancels', [
      { stepDelay: 0, contactEmail: 'first@example.com' },
      { stepDelay: 30, contactEmail: 'second@example.com' },
    ]),
  )
  const check = await portal.createCheck(buildCheck(policy.id, { recoverPeriod: 0 }))

  await flaky.unhealthy()
  const incident = await waitForIncident(portal, check.id, { timeoutMs: 90_000 })
  await waitForNotifications(sink, (n) => n.some((x) => x.incidentId === incident.id))

  await flaky.healthy()

  await expectStableCount(sink, 1, 40_000)
  const final = await sink.list()
  expect(final.filter((x) => x.incidentId === incident.id).length).toBe(1)
})
