import { SignJWT, jwtVerify, decodeJwt } from 'jose'

const SECRET = new TextEncoder().encode(
  process.env.SESSION_SECRET || 'smart-ventas-secret-change-in-production-2024'
)

const SESSION_DURATION = 60 * 60 * 24 * 5

export interface SessionPayload {
  uid: string
  email?: string
}

export function decodeFirebaseToken(idToken: string): SessionPayload | null {
  try {
    const payload = decodeJwt(idToken)
    if (!payload.sub) return null
    return { uid: payload.sub, email: payload.email as string | undefined }
  } catch {
    return null
  }
}

export async function createSessionJWT(payload: SessionPayload): Promise<string> {
  return new SignJWT({ ...payload })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(`${SESSION_DURATION}s`)
    .sign(SECRET)
}

export async function verifySessionJWT(token: string): Promise<SessionPayload | null> {
  try {
    const { payload } = await jwtVerify(token, SECRET)
    if (!payload.uid) return null
    return { uid: payload.uid as string, email: payload.email as string | undefined }
  } catch {
    return null
  }
}
