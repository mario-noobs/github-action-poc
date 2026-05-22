import jwt from 'jsonwebtoken'

import { env } from './env'

export type JwtPayload = {
  userId: string
  firebaseId: string
  internalRole?: string
}

export function signAccessToken(payload: Partial<JwtPayload> = {}): string {
  const full: JwtPayload = {
    userId: payload.userId ?? env.testUserId,
    firebaseId: payload.firebaseId ?? env.testFirebaseId,
    internalRole: payload.internalRole ?? 'super_admin',
  }
  return jwt.sign(full, env.jwtSecret, { expiresIn: '1h' })
}

export function authHeaders(token?: string): Record<string, string> {
  const t = token ?? signAccessToken()
  return {
    Authorization: `Bearer ${t}`,
    'organization-id': env.testOrgId,
    'team-id': env.testTeamId,
  }
}
