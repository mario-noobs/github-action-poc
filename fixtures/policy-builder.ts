import { CreateEscalationPayload, EscalationStep } from './api-client'

type StepInput = { stepDelay?: number; contactEmail?: string }

export function buildPolicy(name: string, steps: StepInput[]): CreateEscalationPayload {
  const escalationSteps: EscalationStep[] = steps.map((s) => ({
    stepDelay: s.stepDelay ?? 0,
    severity: 'CRITICAL',
    contacts: [
      {
        contactType: 'EMAIL',
        contactId: s.contactEmail ?? 'e2e@example.com',
      },
    ],
  }))
  return {
    name,
    repeatCount: 0,
    repeatDelay: 0,
    escalationSteps,
    resolutionAlerts: null,
  }
}
