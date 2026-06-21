import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { requireAuth } from '@/lib/auth-utils';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ codigo: string }> }
) {
  try {
    await requireAuth(request);
    const { codigo } = await params;
    if (!codigo) {
      return NextResponse.json({ error: 'Código requerido' }, { status: 400 });
    }

    const doc = await db.collection('barcode_catalog').doc(codigo).get();
    if (!doc.exists) {
      return NextResponse.json({ error: 'No encontrado' }, { status: 404 });
    }

    return NextResponse.json({ id: doc.id, ...doc.data() });
  } catch (error) {
    console.error('Error buscando código de barras:', error);
    return NextResponse.json({ error: 'Error al buscar código' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    await requireAuth(request);
    const body = await request.json();
    const { codigo, nombre, descripcion, marca, proveedorNombre, categoria } = body;

    if (!codigo || !nombre) {
      return NextResponse.json({ error: 'Código y nombre requeridos' }, { status: 400 });
    }

    await db.collection('barcode_catalog').doc(codigo).set({
      nombre,
      descripcion: descripcion || '',
      marca: marca || '',
      proveedorNombre: proveedorNombre || '',
      categoria: categoria || 'General',
      actualizado: new Date().toISOString(),
    });

    return NextResponse.json({ success: true }, { status: 201 });
  } catch (error) {
    console.error('Error guardando código de barras:', error);
    return NextResponse.json({ error: 'Error al guardar código' }, { status: 500 });
  }
}
