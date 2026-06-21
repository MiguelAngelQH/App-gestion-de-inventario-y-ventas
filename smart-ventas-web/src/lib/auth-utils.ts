import { cookies } from 'next/headers'
import { verifySessionJWT } from '@/lib/session'
import type { NextRequest } from 'next/server'

export async function getSessionUid(request?: NextRequest): Promise<string | null> {
  if (request) {
    const authHeader = request.headers.get('authorization')
    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.slice(7)
      const payload = await verifySessionJWT(token)
      if (payload?.uid) return payload.uid
    }
  }

  try {
    const cookieStore = await cookies()
    const sessionCookie = cookieStore.get('session')?.value
    if (!sessionCookie) return null
    const payload = await verifySessionJWT(sessionCookie)
    return payload?.uid ?? null
  } catch {
    return null
  }
}

export async function requireAuth(request?: NextRequest): Promise<string> {
  const uid = await getSessionUid(request)
  if (!uid) throw new Error('No autorizado')
  return uid
}
