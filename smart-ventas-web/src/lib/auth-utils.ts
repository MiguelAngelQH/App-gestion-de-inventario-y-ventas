import { cookies } from 'next/headers'
import { verifySessionJWT } from '@/lib/session'

export async function getSessionUid(): Promise<string | null> {
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

export async function requireAuth(): Promise<string> {
  const uid = await getSessionUid()
  if (!uid) throw new Error('No autorizado')
  return uid
}
