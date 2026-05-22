import { CreateCheckPayload } from './api-client'
import { env } from './env'

type Opts = {
  title?: string
  url?: string
  location?: string
  interval?: number
  recoverPeriod?: number
  confirmPeriod?: number
  timeout?: number
}

export function buildCheck(escalationId: string, opts: Opts = {}): CreateCheckPayload & { escalationId: string } {
  return {
    title: opts.title ?? 'e2e-check',
    type: 'status',
    url: opts.url ?? `${env.flakyUrl}/health`,
    locations: [opts.location ?? 'vie_sg'],
    interval: opts.interval ?? 10,
    recoverPeriod: opts.recoverPeriod ?? 0,
    confirmPeriod: opts.confirmPeriod ?? 0,
    method: 'GET',
    timeout: opts.timeout ?? 5,
    escalationId,
  }
}
