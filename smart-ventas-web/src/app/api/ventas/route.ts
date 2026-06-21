import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { requireAuth } from '@/lib/auth-utils';

export async function GET(request: NextRequest) {
  try {
    const uid = await requireAuth(request);
    const snap = await db.collection('ventas').where('uid', '==', uid).get();
    const ventas = snap.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));
    ventas.sort((a: any, b: any) => (b.fecha || '').localeCompare(a.fecha || ''));
    return NextResponse.json(ventas);
  } catch (error) {
    console.error('Error fetching ventas:', error);
    return NextResponse.json({ error: 'Error al obtener ventas' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const uid = await requireAuth(request);
    const batch = db.batch();
    const ventaRef = db.collection('ventas').doc();
    
    batch.set(ventaRef, {
      ...body,
      uid,
      fecha: new Date().toISOString(),
    });

    for (const item of body.items ?? []) {
      const prodRef = db.collection('productos').doc(item.productoId);
      batch.update(prodRef, {
        stockTotal: FieldValue.increment(-(item.cantidad * (item.factor || 1))),
      });
    }

    await batch.commit();
    const doc = await ventaRef.get();
    return NextResponse.json({ id: ventaRef.id, ...doc.data() }, { status: 201 });
  } catch (error) {
    console.error('Error creating venta:', error);
    return NextResponse.json({ error: 'Error al crear venta' }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const uid = await requireAuth(request);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'ID requerido' }, { status: 400 });
    const body = await request.json();
    const doc = await db.collection('ventas').doc(id).get();
    if (!doc.exists || doc.data()?.uid !== uid) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }
    await db.collection('ventas').doc(id).update(body);
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error updating venta:', error);
    return NextResponse.json({ error: 'Error al actualizar venta' }, { status: 500 });
  }
}
