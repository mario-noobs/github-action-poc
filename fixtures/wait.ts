import { expect } from '@playwright/test'

import { NotificationSink, PortalClient } from './api-client'

type Notification = { incidentId: string; channel: string; contact: string }

export async function waitForNotifications(
  sink: NotificationSink,
  predicate: (n: Notification[]) => boolean,
  opts: { timeoutMs?: number; intervalMs?: number; message?: string } = {},
): Promise<Notification[]> {
  const timeoutMs = opts.timeoutMs ?? 60_000
  const intervalMs = opts.intervalMs ?? 500
  const deadline = Date.now() + timeoutMs

  let last: Notification[] = []
  while (Date.now() < deadline) {
    last = await sink.list()
    if (predicate(last)) return last
    await new Promise((r) => setTimeout(r, intervalMs))
  }
  throw new Error(
    `${opts.message ?? 'waitForNotifications timed out'} after ${timeoutMs}ms; last seen: ${JSON.stringify(last)}`,
  )
}

export async function waitForIncident(
  portal: PortalClient,
  checkId: string,
  opts: { timeoutMs?: number; intervalMs?: number; minStatus?: string } = {},
): Promise<{ id: string; status: string }> {
  const timeoutMs = opts.timeoutMs ?? 60_000
  const intervalMs = opts.intervalMs ?? 500
  const deadline = Date.now() + timeoutMs

  let last: Array<{ id: string; status: string }> = []
  while (Date.now() < deadline) {
    last = await portal.getIncidentsForCheck(checkId)
    const found = last.find((i) => !!i.id)
    if (found) return found
    await new Promise((r) => setTimeout(r, intervalMs))
  }
  throw new Error(
    `waitForIncident timed out after ${timeoutMs}ms for checkId=${checkId}; last seen: ${JSON.stringify(last)}`,
  )
}

export async function expectStableCount(
  sink: NotificationSink,
  expected: number,
  windowMs: number,
): Promise<void> {
  const intervalMs = 1000
  const deadline = Date.now() + windowMs
  while (Date.now() < deadline) {
    const list = await sink.list()
    expect(list.length, `notification count should stay at ${expected} during quiet window`).toBeLessThanOrEqual(expected)
    await new Promise((r) => setTimeout(r, intervalMs))
  }
}
