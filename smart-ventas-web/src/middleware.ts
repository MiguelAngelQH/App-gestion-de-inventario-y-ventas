import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

const protectedRoutes = ['/dashboard', '/productos', '/ventas', '/compras', '/clientes', '/proveedores', '/reportes']
const publicRoutes = ['/login']

export function middleware(request: NextRequest) {
  const path = request.nextUrl.pathname
  const session = request.cookies.get('session')?.value

  if (path === '/') {
    return NextResponse.next()
  }

  if (protectedRoutes.includes(path) && !session) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  if (publicRoutes.includes(path) && session) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  if (path.startsWith('/api/') && !path.startsWith('/api/auth/') && !session) {
    return NextResponse.json({ error: 'No autorizado' }, { status: 401 })
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|smartventas-.*\\.svg|.*\\.png$).*)'],
}