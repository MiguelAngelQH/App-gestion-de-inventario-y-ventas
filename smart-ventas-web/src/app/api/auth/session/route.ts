import { NextResponse } from 'next/server'
import { decodeFirebaseToken, createSessionJWT } from '@/lib/session'

export async function POST(request: Request) {
  try {
    const { idToken } = await request.json()

    const payload = decodeFirebaseToken(idToken)
    if (!payload) {
      return NextResponse.json({ error: 'Token inválido' }, { status: 401 })
    }

    const sessionJWT = await createSessionJWT(payload)

    const isSecure = request.headers.get('x-forwarded-proto') === 'https' || request.url.startsWith('https')

    const response = NextResponse.json({ success: true, token: sessionJWT })
    response.cookies.set('session', sessionJWT, {
      httpOnly: true,
      secure: isSecure,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 5,
      path: '/',
    })

    return response
  } catch (error) {
    console.error('Session creation error:', error)
    return NextResponse.json({ error: 'Error al crear sesión' }, { status: 401 })
  }
}
