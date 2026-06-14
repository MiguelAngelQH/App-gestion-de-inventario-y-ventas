import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { requireAuth } from '@/lib/auth-utils';

export async function GET() {
  try {
    const uid = await requireAuth();
    const snap = await db.collection('compras').where('uid', '==', uid).get();
    const compras = snap.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));
    compras.sort((a: any, b: any) => (b.fecha || '').localeCompare(a.fecha || ''));
    return NextResponse.json(compras);
  } catch (error) {
    console.error('Error fetching compras:', error);
    return NextResponse.json({ error: 'Error al obtener compras' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const uid = await requireAuth();
    const batch = db.batch();
    const compraRef = db.collection('compras').doc();

    batch.set(compraRef, {
      ...body,
      uid,
      fecha: new Date().toISOString(),
    });

    for (const item of body.items ?? []) {
      const prodRef = db.collection('productos').doc(item.productoId);
      batch.update(prodRef, {
        stock: FieldValue.increment(item.cantidad),
        costo: item.costoUnitario,
      });
    }

    await batch.commit();
    const doc = await compraRef.get();
    return NextResponse.json({ id: compraRef.id, ...doc.data() }, { status: 201 });
  } catch (error) {
    console.error('Error creating compra:', error);
    return NextResponse.json({ error: 'Error al crear compra' }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const uid = await requireAuth();
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'ID requerido' }, { status: 400 });
    const body = await request.json();
    const doc = await db.collection('compras').doc(id).get();
    if (!doc.exists || doc.data()?.uid !== uid) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }
    await db.collection('compras').doc(id).update(body);
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error updating compra:', error);
    return NextResponse.json({ error: 'Error al actualizar compra' }, { status: 500 });
  }
}
