import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { requireAuth } from '@/lib/auth-utils';

export async function GET(request: NextRequest) {
  try {
    const uid = await requireAuth(request);
    const ahora = new Date();
    const inicio7 = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate() - 6);
    const finHoy = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate() + 1);

    const ventasSnap = await db.collection('ventas').where('uid', '==', uid).get();
    const productosSnap = await db.collection('productos').where('uid', '==', uid).get();

    const ventasPorDia: Record<string, number> = {};
    for (let i = 0; i < 7; i++) {
      const d = new Date(inicio7.getTime() + i * 86400000);
      ventasPorDia[`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`] = 0;
    }

    const ventasPorCategoria: Record<string, number> = {};
    const conteoProductos: Record<string, { nombre: string; cantidad: number }> = {};

    for (const doc of ventasSnap.docs) {
      const data: any = doc.data();
      if (data.estado !== 'completada') continue;
      const fecha = new Date(data.fecha);
      if (fecha < inicio7 || fecha >= finHoy) continue;

      const dia = `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}-${String(fecha.getDate()).padStart(2, '0')}`;
      if (ventasPorDia[dia] !== undefined) {
        ventasPorDia[dia] += data.total ?? 0;
      }

      for (const item of data.items ?? []) {
        const cat = item.categoria ?? 'General';
        ventasPorCategoria[cat] = (ventasPorCategoria[cat] ?? 0) + (item.subtotal ?? 0);

        const pid = item.productoId;
        if (pid) {
          if (!conteoProductos[pid]) {
            conteoProductos[pid] = { nombre: item.productoNombre ?? 'Sin nombre', cantidad: 0 };
          }
          conteoProductos[pid].cantidad += item.cantidad ?? 0;
        }
      }
    }

    const topProductos = Object.entries(conteoProductos)
      .sort(([, a], [, b]) => b.cantidad - a.cantidad)
      .slice(0, 5)
      .map(([id, info]) => ({ id, ...info }));

    return NextResponse.json({
      ventasPorDia: Object.entries(ventasPorDia).map(([fecha, total]) => ({ fecha, total })),
      ventasPorCategoria: Object.entries(ventasPorCategoria).map(([categoria, total]) => ({ categoria, total })),
      topProductos,
    });
  } catch (error) {
    console.error('Reportes error:', error);
    return NextResponse.json({ error: 'Error al obtener reportes' }, { status: 500 });
  }
}
