import { NextResponse } from 'next/server'
import { createSessionJWT } from '@/lib/session'

const API_KEY = process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyCuPyDwJtELgZ25NydWGdndDpNVZCf2B6I'

export async function POST(request: Request) {
  try {
    const { email, password } = await request.json()

    if (!email || !password) {
      return NextResponse.json({ error: 'Email y contraseña requeridos' }, { status: 400 })
    }

    const res = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, returnSecureToken: true }),
      },
    )

    const data = await res.json()

    if (!res.ok) {
      const code = data.error?.message || 'INVALID_LOGIN'
      const msg = code === 'EMAIL_NOT_FOUND' || code === 'INVALID_LOGIN_CREDENTIALS'
        ? 'Email o contraseña incorrectos'
        : code === 'USER_DISABLED'
        ? 'Usuario deshabilitado'
        : code === 'TOO_MANY_ATTEMPTS_TRY_LATER'
        ? 'Demasiados intentos. Intenta más tarde'
        : 'Error al iniciar sesión'
      return NextResponse.json({ error: msg, code }, { status: 401 })
    }

    const sessionJWT = await createSessionJWT({
      uid: data.localId,
      email: data.email,
    })

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
    console.error('Login error:', error)
    return NextResponse.json({ error: 'Error de conexión con el servidor de autenticación' }, { status: 500 })
  }
}
