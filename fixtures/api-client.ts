import { APIRequestContext, APIResponse, expect } from '@playwright/test'

import { authHeaders } from './auth'
import { env } from './env'

type Json = Record<string, unknown>

async function unwrap<T = unknown>(res: APIResponse): Promise<T> {
  if (!res.ok()) {
    const body = await res.text()
    throw new Error(`HTTP ${res.status()} ${res.url()}: ${body}`)
  }
  const ct = res.headers()['content-type'] ?? ''
  if (ct.includes('application/json')) return res.json() as Promise<T>
  return (await res.text()) as unknown as T
}

export type EscalationStep = {
  contacts: { contactType: string; contactId: string | null }[]
  stepDelay: number
  severity: string
}

export type CreateEscalationPayload = {
  name: string
  repeatCount?: number
  repeatDelay?: number
  escalationSteps: EscalationStep[]
  resolutionAlerts?: string[] | null
}

export type CreateCheckPayload = {
  title: string
  type?: string
  url: string
  locations: string[]
  interval?: number
  recoverPeriod?: number
  confirmPeriod?: number
  method?: string
  timeout?: number
  escalationId?: string
  escalation?: string
}

export class PortalClient {
  constructor(private readonly request: APIRequestContext, private readonly baseURL = env.portalUrl) {}

  private async post<T = Json>(path: string, body: Json): Promise<T> {
    const res = await this.request.post(`${this.baseURL}${path}`, {
      headers: authHeaders(),
      data: body,
    })
    return unwrap<T>(res)
  }

  private async get<T = Json>(path: string): Promise<T> {
    const res = await this.request.get(`${this.baseURL}${path}`, {
      headers: authHeaders(),
    })
    return unwrap<T>(res)
  }

  async createEscalation(payload: CreateEscalationPayload): Promise<{ id: string }> {
    return this.post('/v1/escalation', payload as unknown as Json)
  }

  async createCheck(payload: CreateCheckPayload & { escalationId: string }): Promise<{ id: string }> {
    const { escalationId, ...rest } = payload
    return this.post('/v1/check', { ...rest, escalation: escalationId } as unknown as Json)
  }

  async getIncidentsForCheck(checkId: string): Promise<Array<{ id: string; status: string }>> {
    const res = await this.get<{ data: Array<{ id: string; status: string }> } | Array<{ id: string; status: string }>>(`/v1/incident/check/${checkId}`)
    return Array.isArray(res) ? res : (res as any).data ?? []
  }

  async acknowledgeIncident(incidentId: string): Promise<unknown> {
    return this.get(`/v1/incident/${incidentId}/acknowledge`)
  }

  async resolveIncident(incidentId: string): Promise<unknown> {
    return this.get(`/v1/incident/${incidentId}/resolve`)
  }

  async getIncident(incidentId: string): Promise<{ id: string; status: string }> {
    return this.get(`/v1/incident/${incidentId}`)
  }
}

export class FlakyTargetClient {
  constructor(private readonly request: APIRequestContext, private readonly baseURL = env.flakyUrl) {}

  async setStatus(status: number, body = 'ok'): Promise<void> {
    const res = await this.request.post(`${this.baseURL}/control`, {
      data: { status, body },
    })
    expect(res.ok(), `flaky-target /control failed: ${res.status()}`).toBeTruthy()
  }

  async healthy(): Promise<void> {
    await this.setStatus(200, 'ok')
  }

  async unhealthy(): Promise<void> {
    await this.setStatus(500, 'down')
  }
}

export class NotificationSink {
  constructor(private readonly request: APIRequestContext, private readonly baseURL = env.serverlessUrl) {}

  async list(): Promise<Array<{ incidentId: string; channel: string; contact: string }>> {
    const res = await this.request.get(`${this.baseURL}/dev/notifications`)
    return unwrap(res)
  }

  async clear(): Promise<void> {
    const res = await this.request.delete(`${this.baseURL}/dev/notifications`)
    if (!res.ok() && res.status() !== 404) {
      throw new Error(`failed to clear notifications: ${res.status()}`)
    }
  }
}
