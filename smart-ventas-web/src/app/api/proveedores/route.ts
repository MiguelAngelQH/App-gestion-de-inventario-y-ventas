import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { requireAuth } from '@/lib/auth-utils';

export async function GET(request: NextRequest) {
  try {
    const uid = await requireAuth(request);
    const snap = await db.collection('proveedores').where('uid', '==', uid).get();
    const proveedores = snap.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));
    return NextResponse.json(proveedores);
  } catch (error) {
    console.error('Error fetching proveedores:', error);
    return NextResponse.json({ error: 'Error al obtener proveedores' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const uid = await requireAuth(request);
    const docRef = await db.collection('proveedores').add({ ...body, uid });
    const doc = await docRef.get();
    return NextResponse.json({ id: docRef.id, ...doc.data() }, { status: 201 });
  } catch (error) {
    console.error('Error creating proveedor:', error);
    return NextResponse.json({ error: 'Error al crear proveedor' }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const uid = await requireAuth(request);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'ID requerido' }, { status: 400 });
    const body = await request.json();
    const doc = await db.collection('proveedores').doc(id).get();
    if (!doc.exists || doc.data()?.uid !== uid) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }
    await db.collection('proveedores').doc(id).update(body);
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error updating proveedor:', error);
    return NextResponse.json({ error: 'Error al actualizar proveedor' }, { status: 500 });
  }
}

export async function PUT(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const uid = await requireAuth(request);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'ID requerido' }, { status: 400 });
    const body = await request.json();
    const doc = await db.collection('proveedores').doc(id).get();
    if (!doc.exists || doc.data()?.uid !== uid) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }
    await db.collection('proveedores').doc(id).set({ ...body, uid }, { merge: true });
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error updating proveedor:', error);
    return NextResponse.json({ error: 'Error al actualizar proveedor' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const uid = await requireAuth(request);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'ID requerido' }, { status: 400 });
    const doc = await db.collection('proveedores').doc(id).get();
    if (!doc.exists || doc.data()?.uid !== uid) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }
    await db.collection('proveedores').doc(id).delete();
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting proveedor:', error);
    return NextResponse.json({ error: 'Error al eliminar proveedor' }, { status: 500 });
  }
}
