import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { requireAuth } from '@/lib/auth-utils';

function esMismoDia(fechaStr: string, fechaRef: Date): boolean {
  const d = new Date(fechaStr);
  if (isNaN(d.getTime())) return false;
  return (
    d.getFullYear() === fechaRef.getFullYear() &&
    d.getMonth() === fechaRef.getMonth() &&
    d.getDate() === fechaRef.getDate()
  );
}

export async function GET(request: NextRequest) {
  try {
    const uid = await requireAuth(request);
    const ahora = new Date();
    const inicioSemana = new Date(
      ahora.getFullYear(), ahora.getMonth(), ahora.getDate() - 6
    );

    const ventasSnap = await db.collection('ventas').where('uid', '==', uid).get();
    const productosSnap = await db.collection('productos').where('uid', '==', uid).get();
    const clientesSnap = await db.collection('clientes').where('uid', '==', uid).get();
    const proveedoresSnap = await db.collection('proveedores').where('uid', '==', uid).get();

    let ventasHoy = 0;
    let ventasSemana = 0;
    let gananciaTotal = 0;
    let ventasCountHoy = 0;

    for (const doc of ventasSnap.docs) {
      const data: any = doc.data();
      const total = data.total ?? 0;
      const items = data.items ?? [];
      const fechaStr = data.fecha;

      if (data.estado === 'completada' && esMismoDia(fechaStr, ahora)) {
        ventasHoy += total;
        ventasCountHoy++;
      }
      if (data.estado === 'completada' && new Date(fechaStr) >= inicioSemana) {
        ventasSemana += total;
      }

      if (data.estado === 'completada') {
        let costoTotal = 0;
        for (const item of items) {
          costoTotal += (item.costoUnitario ?? 0) * (item.cantidad ?? 0);
        }
        gananciaTotal += total - costoTotal;
      }
    }

    let stockBajo = 0;
    for (const doc of productosSnap.docs) {
      const data: any = doc.data();
      if ((data.stock ?? 0) <= 5) stockBajo++;
    }

    let cuentasCobrar = 0;
    for (const doc of clientesSnap.docs) {
      cuentasCobrar += (doc.data() as any)?.deuda ?? 0;
    }

    let cuentasPagar = 0;
    for (const doc of proveedoresSnap.docs) {
      cuentasPagar += (doc.data() as any)?.saldoPendiente ?? 0;
    }

    return NextResponse.json({
      ventasHoy,
      ventasSemana,
      gananciaTotal,
      stockBajo,
      cuentasCobrar,
      cuentasPagar,
      ventasCountHoy,
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    return NextResponse.json({ error: 'Error al obtener métricas' }, { status: 500 });
  }
}
