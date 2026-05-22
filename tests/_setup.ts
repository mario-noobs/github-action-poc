import { test as base } from '@playwright/test'

import { FlakyTargetClient, NotificationSink, PortalClient } from '../fixtures/api-client'
import { resetState, seedOrgAndTeam, seedWorker } from '../fixtures/seed'

type Fixtures = {
  portal: PortalClient
  sink: NotificationSink
  flaky: FlakyTargetClient
}

export const test = base.extend<Fixtures>({
  portal: async ({ request }, use) => {
    await use(new PortalClient(request))
  },
  sink: async ({ request }, use) => {
    await use(new NotificationSink(request))
  },
  flaky: async ({ request }, use) => {
    await use(new FlakyTargetClient(request))
  },
})

test.beforeAll(async () => {
  await seedOrgAndTeam()
  await seedWorker('vie_sg')
})

test.beforeEach(async ({ sink, flaky }) => {
  await flaky.healthy()
  await sink.clear()
  await resetState()
})

export { expect } from '@playwright/test'
