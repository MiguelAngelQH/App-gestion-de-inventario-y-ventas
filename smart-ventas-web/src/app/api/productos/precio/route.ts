import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { requireAuth } from '@/lib/auth-utils';

export async function PATCH(request: NextRequest) {
  try {
    const body = await request.json();
    const { productoId, presentacionId, precio, costo } = body;
    const uid = await requireAuth(request);

    if (costo !== undefined) {
      // Cost is now at product level, not per presentation
      if (!productoId) {
        return NextResponse.json({ error: 'productoId requerido' }, { status: 400 });
      }
      const doc = await db.collection('productos').doc(productoId).get();
      if (!doc.exists || doc.data()?.uid !== uid) {
        return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
      }
      await db.collection('productos').doc(productoId).update({ costo });
      return NextResponse.json({ success: true });
    }

    if (!productoId || !presentacionId) {
      return NextResponse.json({ error: 'productoId y presentacionId requeridos' }, { status: 400 });
    }

    const doc = await db.collection('productos').doc(productoId).get();
    if (!doc.exists || doc.data()?.uid !== uid) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }

    const data = doc.data() as any;
    const presentaciones = Array.isArray(data?.presentaciones)
      ? data.presentaciones.map((p: any) => ({ ...p }))
      : [];

    let updated = false;
    for (const p of presentaciones) {
      if (p.id === presentacionId) {
        if (precio !== undefined) p.precio = precio;
        updated = true;
        break;
      }
    }

    if (!updated) {
      return NextResponse.json({ error: 'Presentacion no encontrada' }, { status: 404 });
    }

    await db.collection('productos').doc(productoId).update({ presentaciones });
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error updating presentacion:', error);
    return NextResponse.json({ error: 'Error al actualizar presentacion' }, { status: 500 });
  }
}
