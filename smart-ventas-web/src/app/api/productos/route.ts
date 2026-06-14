import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { requireAuth } from '@/lib/auth-utils';

export async function GET() {
  try {
    const uid = await requireAuth();
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
    const uid = await requireAuth();
    const body = await request.json();
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
