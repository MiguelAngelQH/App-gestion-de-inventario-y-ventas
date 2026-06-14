import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { requireAuth } from '@/lib/auth-utils';

export async function POST(request: NextRequest) {
  try {
    const uid = await requireAuth();
    const { clienteId, monto, nota } = await request.json();
    const batch = db.batch();
    const clienteRef = db.collection('clientes').doc(clienteId);
    batch.update(clienteRef, {
      deuda: FieldValue.increment(-monto),
    });
    const pagoRef = db.collection('pagos_cobrar').doc();
    batch.set(pagoRef, {
      uid,
      clienteId,
      monto,
      nota: nota || '',
      fecha: new Date().toISOString(),
    });
    await batch.commit();

    const doc = await clienteRef.get();
    if (doc.exists && (doc.data()?.deuda ?? 0) <= 0) {
      await clienteRef.update({ estado: 'pagado' });
    }
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error registering payment:', error);
    return NextResponse.json({ error: 'Error al registrar pago' }, { status: 500 });
  }
}
