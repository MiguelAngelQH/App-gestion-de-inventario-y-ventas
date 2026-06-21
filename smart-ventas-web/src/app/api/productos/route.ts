import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { requireAuth } from '@/lib/auth-utils';

export async function GET(request: NextRequest) {
  try {
    const uid = await requireAuth(request);
    const snap = await db.collection('productos').where('uid', '==', uid).get();
    const productos = snap.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));
    productos.sort((a: any, b: any) => (b.fechaCreacion || '').localeCompare(a.fechaCreacion || ''));
    return NextResponse.json(productos);
  } catch (error) {
    console.error('Error fetching productos:', error);
    return NextResponse.json({ error: 'Error al obtener productos' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const uid = await requireAuth(request);
    const docRef = await db.collection('productos').add({
      ...body,
      uid,
      fechaCreacion: new Date().toISOString(),
    });
    const doc = await docRef.get();
    return NextResponse.json({ id: docRef.id, ...doc.data() }, { status: 201 });
  } catch (error) {
    console.error('Error creating producto:', error);
    return NextResponse.json({ error: 'Error al crear producto' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const uid = await requireAuth(request);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'ID requerido' }, { status: 400 });
    const doc = await db.collection('productos').doc(id).get();
    if (!doc.exists || doc.data()?.uid !== uid) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }
    await db.collection('productos').doc(id).delete();
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting producto:', error);
    return NextResponse.json({ error: 'Error al eliminar producto' }, { status: 500 });
  }
}

export async function PUT(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const uid = await requireAuth(request);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'ID requerido' }, { status: 400 });
    const body = await request.json();
    const doc = await db.collection('productos').doc(id).get();
    if (!doc.exists || doc.data()?.uid !== uid) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }
    await db.collection('productos').doc(id).update(body);
    const updated = await db.collection('productos').doc(id).get();
    return NextResponse.json({ id, ...updated.data() });
  } catch (error) {
    console.error('Error updating producto:', error);
    return NextResponse.json({ error: 'Error al actualizar producto' }, { status: 500 });
  }
}
