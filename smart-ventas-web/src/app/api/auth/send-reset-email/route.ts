import { NextResponse } from 'next/server'
import { auth } from '@/lib/firebase-admin'
import nodemailer from 'nodemailer'

const API_KEY = process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyCuPyDwJtELgZ25NydWGdndDpNVZCf2B6I'
const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL || 'https://germinate-compress-try.ngrok-free.dev'

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
  },
})

async function sendResetEmail(to: string, resetLink: string) {
  const html = `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f5f7fa;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 20px;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 12px rgba(0,0,0,0.06);">
        <tr><td style="background:#00897B;padding:24px;text-align:center;">
          <h1 style="color:#ffffff;font-size:22px;margin:0;">SmartVentas</h1>
        </td></tr>
        <tr><td style="padding:32px 24px;">
          <p style="color:#1f2937;font-size:16px;margin:0 0 8px 0;">Hola,</p>
          <p style="color:#64748b;font-size:14px;line-height:1.6;margin:0 0 20px 0;">
            Recibimos una solicitud para restablecer la contraseña de tu cuenta <strong style="color:#1f2937;">${to}</strong> en SmartVentas.
          </p>
          <p style="color:#64748b;font-size:14px;line-height:1.6;margin:0 0 24px 0;">
            Haz clic en el botón de abajo para crear una nueva contraseña:
          </p>
          <table cellpadding="0" cellspacing="0" style="margin:0 auto 24px auto;">
            <tr>
              <td align="center" style="background:#00897B;border-radius:10px;padding:14px 36px;">
                <a href="${resetLink}" style="color:#ffffff;font-size:15px;font-weight:bold;text-decoration:none;display:inline-block;">
                  Restablecer contraseña
                </a>
              </td>
            </tr>
          </table>
          <p style="color:#94a3b8;font-size:12px;line-height:1.5;margin:0 0 4px 0;">Este enlace expira en 1 hora.</p>
          <p style="color:#94a3b8;font-size:12px;line-height:1.5;margin:0 0 20px 0;">Si no solicitaste este cambio, ignora este correo.</p>
          <hr style="border:none;border-top:1px solid #e2e8f0;margin:20px 0;">
          <p style="color:#94a3b8;font-size:12px;margin:0;">El equipo de SmartVentas</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`

  await transporter.sendMail({
    from: process.env.SMTP_FROM || '"SmartVentas" <noreply@smart-ventas.com>',
    to,
    subject: 'Restablece tu contraseña de SmartVentas',
    html,
  })
}

export async function POST(request: Request) {
  try {
    const { email } = await request.json()

    if (!email || !email.includes('@')) {
      return NextResponse.json({ error: 'Correo inválido' }, { status: 400 })
    }

    const firebaseLink = await auth.generatePasswordResetLink(email, {
      url: BASE_URL + '/reset-password',
      handleCodeInApp: true,
    })

    const url = new URL(firebaseLink)
    const oobCode = url.searchParams.get('oobCode')

    if (!oobCode) {
      return NextResponse.json({ error: 'Error al generar código de restablecimiento' }, { status: 500 })
    }

    const myLink = `${BASE_URL}/reset-password?oobCode=${oobCode}&apiKey=${API_KEY}`

    if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
      console.log('SMTP no configurado. Link generado:', myLink)
      return NextResponse.json({
        success: true,
        message: 'Correo enviado correctamente',
        debug: myLink,
      })
    }

    await sendResetEmail(email, myLink)

    return NextResponse.json({ success: true, message: 'Correo enviado correctamente' })
  } catch (error: any) {
    console.error('Send reset email error:', error)

    if (error?.code === 'auth/user-not-found') {
      return NextResponse.json({ error: 'No existe una cuenta con ese correo' }, { status: 404 })
    }

    return NextResponse.json({ error: 'Error al enviar el correo' }, { status: 500 })
  }
}
