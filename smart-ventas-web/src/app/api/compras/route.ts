import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { requireAuth } from '@/lib/auth-utils';

export async function GET(request: NextRequest) {
  try {
    const uid = await requireAuth(request);
    const snap = await db.collection('compras').where('uid', '==', uid).get();
    const compras = snap.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));
    compras.sort((a: any, b: any) => (b.fecha || '').localeCompare(a.fecha || ''));
    return NextResponse.json(compras);
  } catch (error) {
    console.error('Error fetching compras:', error);
    return NextResponse.json({ error: 'Error al obtener compras' }, { status: 500 });
  }
}

async function actualizarCostoPresentacion(
  productoId: string, presentacionId: string, nuevoCosto: number
) {
  const doc = await db.collection('productos').doc(productoId).get();
  if (!doc.exists) return;
  const data = doc.data() as any;
  const presentaciones = Array.isArray(data?.presentaciones)
    ? data.presentaciones.map((p: any) => ({ ...p }))
    : [];
  let updated = false;
  for (const p of presentaciones) {
    if (p.id === presentacionId) {
      p.costo = nuevoCosto;
      updated = true;
      break;
    }
  }
  if (updated) {
    await db.collection('productos').doc(productoId).update({ presentaciones });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const uid = await requireAuth(request);
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
        stockTotal: FieldValue.increment(item.cantidad * (item.factor || 1)),
      });
    }

    await batch.commit();

    for (const item of body.items ?? []) {
      await actualizarCostoPresentacion(item.productoId, item.presentacionId, item.costoUnitario);
    }

    const doc = await compraRef.get();
    return NextResponse.json({ id: compraRef.id, ...doc.data() }, { status: 201 });
  } catch (error) {
    console.error('Error creating compra:', error);
    return NextResponse.json({ error: 'Error al crear compra' }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const uid = await requireAuth(request);
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
