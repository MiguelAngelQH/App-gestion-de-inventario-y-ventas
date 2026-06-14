import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function POST(request: NextRequest) {
  const isSecure = request.headers.get('x-forwarded-proto') === 'https' || request.url.startsWith('https')

  const response = NextResponse.json({ success: true })
  response.cookies.set('session', '', {
    httpOnly: true,
    secure: isSecure,
    sameSite: 'lax',
    maxAge: 0,
    path: '/',
  })
  return response
}
