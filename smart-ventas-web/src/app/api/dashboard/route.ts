import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { requireAuth } from '@/lib/auth-utils';

export async function GET() {
  try {
    const uid = await requireAuth();
    const ahora = new Date();
    const inicioHoy = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate());
    const finHoy = new Date(inicioHoy.getTime() + 86400000);
    const inicioSemana = new Date(inicioHoy.getTime() - 6 * 86400000);

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
      const fecha = new Date(data.fecha);
      const total = data.total ?? 0;
      const items = data.items ?? [];

      if (fecha >= inicioHoy && fecha < finHoy) {
        ventasHoy += total;
        ventasCountHoy++;
      }
      if (fecha >= inicioSemana) {
        ventasSemana += total;
      }

      let costoTotal = 0;
      for (const item of items) {
        costoTotal += (item.costoUnitario ?? 0) * (item.cantidad ?? 0);
      }
      gananciaTotal += total - costoTotal;
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
