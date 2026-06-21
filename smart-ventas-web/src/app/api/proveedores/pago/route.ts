import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { requireAuth } from '@/lib/auth-utils';

export async function POST(request: NextRequest) {
  try {
    const { proveedorId, monto, nota } = await request.json();
    const uid = await requireAuth(request);
    const batch = db.batch();
    const proveedorRef = db.collection('proveedores').doc(proveedorId);
    batch.update(proveedorRef, {
      saldoPendiente: FieldValue.increment(-monto),
    });
    const pagoRef = db.collection('pagos_pagar').doc();
    batch.set(pagoRef, {
      uid,
      proveedorId,
      monto,
      nota: nota || '',
      fecha: new Date().toISOString(),
    });
    await batch.commit();

    const doc = await proveedorRef.get();
    if (doc.exists && (doc.data()?.saldoPendiente ?? 0) <= 0) {
      await proveedorRef.update({ estado: 'pagado' });
    }
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error registering supplier payment:', error);
    return NextResponse.json({ error: 'Error al registrar pago' }, { status: 500 });
  }
}
