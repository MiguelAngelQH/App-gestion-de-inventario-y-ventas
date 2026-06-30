import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { requireAuth } from '@/lib/auth-utils';
import type PdfPrinterType from 'pdfmake';

const PdfPrinter: typeof PdfPrinterType = require('pdfmake');

const vfs = require('pdfmake/build/vfs_fonts').pdfMake.vfs;

const fonts = {
  Roboto: {
    normal: Buffer.from(vfs['Roboto-Regular.ttf'], 'base64'),
    bold: Buffer.from(vfs['Roboto-Medium.ttf'], 'base64'),
    italics: Buffer.from(vfs['Roboto-Italic.ttf'], 'base64'),
    bolditalics: Buffer.from(vfs['Roboto-MediumItalic.ttf'], 'base64'),
  },
};

function formatearFecha(): string {
  const d = new Date();
  const dia = String(d.getDate()).padStart(2, '0');
  const mes = String(d.getMonth() + 1).padStart(2, '0');
  const anio = d.getFullYear();
  const hora = String(d.getHours()).padStart(2, '0');
  const min = String(d.getMinutes()).padStart(2, '0');
  return `${dia}/${mes}/${anio} ${hora}:${min}`;
}

function formatearMoneda(valor: number): string {
  return 'S/ ' + valor.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

export async function GET(request: NextRequest) {
  try {
    const uid = await requireAuth(request);

    const ahora = new Date();
    const inicioHoy = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate());
    const finHoy = new Date(inicioHoy.getTime() + 86400000);
    const inicioSemana = new Date(inicioHoy.getTime() - 6 * 86400000);

    const [ventasSnap, productosSnap, clientesSnap, proveedoresSnap] = await Promise.all([
      db.collection('ventas').where('uid', '==', uid).get(),
      db.collection('productos').where('uid', '==', uid).get(),
      db.collection('clientes').where('uid', '==', uid).get(),
      db.collection('proveedores').where('uid', '==', uid).get(),
    ]);

    let ventasHoy = 0;
    let ventasCountHoy = 0;
    let ventasSemana = 0;
    let gananciaTotal = 0;
    const ventas7Dias: Record<string, { total: number; count: number }> = {};
    const ventasPorCategoria: Record<string, number> = {};
    const topProductos: Record<string, { nombre: string; cantidad: number; total: number }> = {};

    for (let i = 0; i < 7; i++) {
      const d = new Date(inicioSemana.getTime() + i * 86400000);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      ventas7Dias[key] = { total: 0, count: 0 };
    }

    for (const doc of ventasSnap.docs) {
      const data: any = doc.data();
      if (data.estado !== 'completada') continue;

      const fecha = new Date(data.fecha);
      const total = data.total ?? 0;
      const items = data.items ?? [];

      const diaKey = `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}-${String(fecha.getDate()).padStart(2, '0')}`;

      if (fecha >= inicioHoy && fecha < finHoy) {
        ventasHoy += total;
        ventasCountHoy++;
      }
      if (fecha >= inicioSemana) {
        ventasSemana += total;
      }
      if (ventas7Dias[diaKey]) {
        ventas7Dias[diaKey].total += total;
        ventas7Dias[diaKey].count++;
      }

      let costoTotal = 0;
      for (const item of items) {
        costoTotal += (item.costoUnitario ?? 0) * (item.cantidad ?? 0);
        const cat = item.categoria ?? 'General';
        ventasPorCategoria[cat] = (ventasPorCategoria[cat] ?? 0) + (item.subtotal ?? 0);

        const pid = item.productoId;
        if (pid) {
          if (!topProductos[pid]) {
            topProductos[pid] = { nombre: item.productoNombre ?? 'Sin nombre', cantidad: 0, total: 0 };
          }
          topProductos[pid].cantidad += item.cantidad ?? 0;
          topProductos[pid].total += item.subtotal ?? 0;
        }
      }
      gananciaTotal += total - costoTotal;
    }

    const top5 = Object.entries(topProductos)
      .sort(([, a], [, b]) => b.cantidad - a.cantidad)
      .slice(0, 5);

    let stockBajo = 0;
    for (const doc of productosSnap.docs) {
      if (((doc.data() as any)?.stock ?? 0) <= 5) stockBajo++;
    }

    let cuentasCobrar = 0;
    for (const doc of clientesSnap.docs) {
      cuentasCobrar += (doc.data() as any)?.deuda ?? 0;
    }

    let cuentasPagar = 0;
    for (const doc of proveedoresSnap.docs) {
      cuentasPagar += (doc.data() as any)?.saldoPendiente ?? 0;
    }

    // Build detailed products sold list from ALL completed ventas
    const productosVendidosBody: any[] = [];
    let totalDetallado = 0;
    let totalCostoDetallado = 0;
    for (const doc of ventasSnap.docs) {
      const data: any = doc.data();
      if (data.estado !== 'completada') continue;
      const fecha = new Date(data.fecha);
      const fechaStr = `${String(fecha.getDate()).padStart(2, '0')}/${String(fecha.getMonth() + 1).padStart(2, '0')}`;
      for (const item of data.items ?? []) {
        productosVendidosBody.push([
          { text: fechaStr, color: '#6b7280', fontSize: 8 },
          { text: item.productoNombre ?? '—', color: '#1f2937', fontSize: 8 },
          { text: item.categoria ?? 'General', color: '#6b7280', fontSize: 8 },
          { text: formatearMoneda(item.precioUnitario ?? 0), alignment: 'right' as const, color: '#1f2937', fontSize: 8 },
          { text: String(item.cantidad ?? 0), alignment: 'center' as const, color: '#1f2937', fontSize: 8 },
          { text: formatearMoneda(item.subtotal ?? 0), alignment: 'right' as const, color: '#059669', fontSize: 8 },
          { text: formatearMoneda((item.costoUnitario ?? 0) * (item.cantidad ?? 0)), alignment: 'right' as const, color: '#dc2626', fontSize: 8 },
        ]);
        totalDetallado += item.subtotal ?? 0;
        totalCostoDetallado += (item.costoUnitario ?? 0) * (item.cantidad ?? 0);
      }
    }

    // Build inventory section
    const inventarioBody: any[] = [];
    for (const doc of productosSnap.docs) {
      const p: any = doc.data();
      inventarioBody.push([
        { text: p.nombre ?? '—', color: '#1f2937', fontSize: 8 },
        { text: p.categoria ?? 'General', color: '#6b7280', fontSize: 8 },
        { text: p.marca ?? '—', color: '#6b7280', fontSize: 8 },
        { text: String(p.stock ?? 0), alignment: 'center' as const, color: (p.stock ?? 0) <= 5 ? '#dc2626' : '#1f2937', fontSize: 8 },
        { text: formatearMoneda(p.costo ?? 0), alignment: 'right' as const, color: '#1f2937', fontSize: 8 },
        { text: p.presentaciones?.map((pr: any) => `${formatearMoneda(pr.precio)}/${pr.unidad}`).join(', ') ?? '—', color: '#6b7280', fontSize: 7 },
      ]);
    }

    const topProductosBody = top5.length > 0
      ? top5.map(([id, p], i) => [
          { text: String(i + 1), alignment: 'center' as const, color: '#6b7280' },
          { text: p.nombre, color: '#1f2937' },
          { text: String(p.cantidad), alignment: 'center' as const, color: '#1f2937' },
          { text: formatearMoneda(p.total), alignment: 'right' as const, color: '#059669' },
        ])
      : [[{ text: 'Sin ventas en este periodo', colSpan: 4, alignment: 'center' as const, color: '#9ca3af' }, {}, {}, {}]];

    const categoriasBody = Object.entries(ventasPorCategoria)
      .sort(([, a], [, b]) => b - a)
      .map(([cat, total]) => [
        { text: cat, color: '#1f2937' },
        { text: formatearMoneda(total), alignment: 'right' as const, color: '#059669' },
      ]);

    const ventas7Body = Object.entries(ventas7Dias).map(([fecha, data]) => {
      const [anio, mes, dia] = fecha.split('-');
      const fechaStr = `${dia}/${mes}`;
      return [
        { text: fechaStr, color: '#6b7280' },
        { text: formatearMoneda(data.total), alignment: 'right' as const, color: '#1f2937', bold: data.total > 0 },
        { text: data.count > 0 ? `${data.count} ventas` : '-', alignment: 'center' as const, color: '#9ca3af' },
      ];
    });

    const printer = new PdfPrinter(fonts);

    const docDef = {
      pageSize: 'A4' as const,
      pageOrientation: 'landscape' as const,
      pageMargins: [30, 40, 30, 60],
      header: (currentPage: number) => ({
        margin: [30, 15, 30, 0],
        columns: [
          { text: 'SMARTVENTAS', color: '#1e40af', bold: true, fontSize: 9 },
          { text: `Página ${currentPage}`, alignment: 'right', color: '#9ca3af', fontSize: 8 },
        ],
      }),
      footer: (currentPage: number, pageCount: number) => ({
        margin: [30, 0, 30, 15],
        stack: [
          { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 750, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }] },
          { text: 'SmartVentas — Sistema de Gestión Empresarial', alignment: 'center', color: '#9ca3af', fontSize: 7, margin: [0, 4, 0, 0] },
        ],
      }),
      content: [
        {
          stack: [
            { text: 'SMARTVENTAS', fontSize: 26, bold: true, color: '#1e40af', letterSpacing: 2 },
            { text: 'Reporte de Ventas — Detalle Completo', fontSize: 13, color: '#6b7280', margin: [0, 2, 0, 0] },
            { text: `Generado el ${formatearFecha()}`, fontSize: 8, color: '#9ca3af', margin: [0, 4, 0, 0] },
          ],
          margin: [0, 0, 0, 12],
        },

        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 750, y2: 0, lineWidth: 1, lineColor: '#1e40af' }], margin: [0, 0, 0, 12] },

        {
          text: 'MÉTRICAS DEL DÍA',
          fontSize: 10,
          bold: true,
          color: '#1e40af',
          margin: [0, 0, 0, 6],
        },

        {
          layout: 'noBorders',
          table: {
            widths: ['*', '*', '*', '*', '*', '*'],
            body: [[
              { stack: [
                { text: formatearMoneda(ventasHoy), fontSize: 16, bold: true, color: '#059669' },
                { text: 'Ventas Hoy', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
                { text: `${ventasCountHoy} transacciones`, fontSize: 7, color: '#9ca3af', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 4] },
              { stack: [
                { text: formatearMoneda(ventasSemana), fontSize: 16, bold: true, color: '#1d4ed8' },
                { text: 'Ventas (7 días)', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 4] },
              { stack: [
                { text: formatearMoneda(gananciaTotal), fontSize: 16, bold: true, color: '#059669' },
                { text: 'Ganancia Total', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 4] },
              { stack: [
                { text: String(stockBajo), fontSize: 16, bold: true, color: stockBajo > 0 ? '#dc2626' : '#059669' },
                { text: 'Stock Bajo', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 4] },
              { stack: [
                { text: formatearMoneda(cuentasCobrar), fontSize: 16, bold: true, color: '#7c3aed' },
                { text: 'Por Cobrar', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 4] },
              { stack: [
                { text: formatearMoneda(cuentasPagar), fontSize: 16, bold: true, color: '#d97706' },
                { text: 'Por Pagar', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 4] },
            ]],
          },
          margin: [0, 0, 0, 14],
        },

        // ---- SECTION: DETALLE DE PRODUCTOS VENDIDOS ----
        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 750, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }], margin: [0, 0, 0, 8] },

        {
          text: 'DETALLE DE PRODUCTOS VENDIDOS',
          fontSize: 10,
          bold: true,
          color: '#1e40af',
          margin: [0, 0, 0, 6],
        },

        {
          layout: {
            hLineWidth: () => 0.5,
            vLineWidth: () => 0,
            hLineColor: () => '#e5e7eb',
            fillColor: (rowIndex: number) => rowIndex === 0 ? '#1e40af' : (rowIndex % 2 === 0 ? '#f8fafc' : null),
          },
          table: {
            widths: [40, '*', 55, 50, 30, 55, 55],
            headerRows: 1,
            body: [
              [
                { text: 'Fecha', alignment: 'center', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Producto', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Categoría', alignment: 'center', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Precio Unit.', alignment: 'right', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Cant.', alignment: 'center', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Subtotal', alignment: 'right', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Costo Total', alignment: 'right', color: '#ffffff', bold: true, fontSize: 8 },
              ],
              ...(productosVendidosBody.length > 0 ? productosVendidosBody : [[
                { text: 'Sin ventas en este periodo', colSpan: 7, alignment: 'center' as const, color: '#9ca3af', fontSize: 8 }, {}, {}, {}, {}, {}, {}
              ]]),
              [
                { text: 'TOTALES', colSpan: 4, color: '#1f2937', bold: true, fontSize: 8, alignment: 'right' as const }, {}, {}, {},
                { text: '', alignment: 'center' as const, fontSize: 8 },
                { text: formatearMoneda(totalDetallado), alignment: 'right' as const, color: '#059669', bold: true, fontSize: 8 },
                { text: formatearMoneda(totalCostoDetallado), alignment: 'right' as const, color: '#dc2626', bold: true, fontSize: 8 },
              ],
            ],
          },
          margin: [0, 0, 0, 16],
        },

        // ---- SECTION: TOP 5 + CATEGORIAS + 7 DIAS (3 columns) ----
        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 750, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }], margin: [0, 0, 0, 8] },

        {
          columns: [
            {
              width: '*',
              stack: [
                { text: 'TOP 5 PRODUCTOS', fontSize: 9, bold: true, color: '#1e40af', margin: [0, 0, 0, 4] },
                {
                  layout: {
                    hLineWidth: () => 0.5, vLineWidth: () => 0, hLineColor: () => '#e5e7eb',
                    fillColor: (rowIndex: number) => rowIndex === 0 ? '#1e40af' : (rowIndex % 2 === 0 ? '#f8fafc' : null),
                  },
                  table: {
                    widths: [20, '*', 35, 55],
                    headerRows: 1,
                    body: [
                      [{ text: '#', alignment: 'center', color: '#ffffff', bold: true, fontSize: 7 },
                       { text: 'Producto', color: '#ffffff', bold: true, fontSize: 7 },
                       { text: 'Cant.', alignment: 'center', color: '#ffffff', bold: true, fontSize: 7 },
                       { text: 'Total', alignment: 'right', color: '#ffffff', bold: true, fontSize: 7 }],
                      ...topProductosBody.map(r => r.map(c => ({ ...c, fontSize: 7 }))),
                    ],
                  },
                  margin: [0, 0, 8, 0],
                },
              ],
            },
            {
              width: '*',
              stack: [
                { text: 'VENTAS POR CATEGORÍA', fontSize: 9, bold: true, color: '#1e40af', margin: [0, 0, 0, 4] },
                {
                  layout: {
                    hLineWidth: () => 0.5, vLineWidth: () => 0, hLineColor: () => '#e5e7eb',
                    fillColor: (rowIndex: number) => rowIndex % 2 === 0 ? '#f8fafc' : null,
                  },
                  table: {
                    widths: ['*', 70],
                    body: [
                      [{ text: 'Categoría', color: '#6b7280', bold: true, fontSize: 7 },
                       { text: 'Total', alignment: 'right', color: '#6b7280', bold: true, fontSize: 7 }],
                      ...categoriasBody.map(r => r.map(c => ({ ...c, fontSize: 7 }))),
                    ],
                  },
                  margin: [0, 0, 8, 0],
                },
              ],
            },
            {
              width: '*',
              stack: [
                { text: 'ÚLTIMOS 7 DÍAS', fontSize: 9, bold: true, color: '#1e40af', margin: [0, 0, 0, 4] },
                {
                  layout: {
                    hLineWidth: () => 0.5, vLineWidth: () => 0, hLineColor: () => '#e5e7eb',
                    fillColor: (rowIndex: number) => rowIndex % 2 === 0 ? '#f8fafc' : null,
                  },
                  table: {
                    widths: [45, '*', 55],
                    body: [
                      [{ text: 'Fecha', color: '#6b7280', bold: true, fontSize: 7 },
                       { text: 'Total', alignment: 'right', color: '#6b7280', bold: true, fontSize: 7 },
                       { text: 'Transacciones', alignment: 'center', color: '#6b7280', bold: true, fontSize: 7 }],
                      ...ventas7Body.map(r => r.map(c => ({ ...c, fontSize: 7 }))),
                    ],
                  },
                },
              ],
            },
          ],
          margin: [0, 0, 0, 16],
        },

        // ---- SECTION: INVENTARIO ----
        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 750, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }], margin: [0, 0, 0, 8] },

        {
          text: 'INVENTARIO DE PRODUCTOS',
          fontSize: 10,
          bold: true,
          color: '#1e40af',
          margin: [0, 0, 0, 6],
        },

        {
          layout: {
            hLineWidth: () => 0.5,
            vLineWidth: () => 0,
            hLineColor: () => '#e5e7eb',
            fillColor: (rowIndex: number) => rowIndex === 0 ? '#1e40af' : (rowIndex % 2 === 0 ? '#f8fafc' : null),
          },
          table: {
            widths: ['*', 55, 50, 35, 50, '*'],
            headerRows: 1,
            body: [
              [
                { text: 'Producto', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Categoría', alignment: 'center', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Marca', alignment: 'center', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Stock', alignment: 'center', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Costo Prom.', alignment: 'right', color: '#ffffff', bold: true, fontSize: 8 },
                { text: 'Precios de Venta', alignment: 'center', color: '#ffffff', bold: true, fontSize: 8 },
              ],
              ...(inventarioBody.length > 0 ? inventarioBody : [[
                { text: 'No hay productos registrados', colSpan: 6, alignment: 'center' as const, color: '#9ca3af', fontSize: 8 }, {}, {}, {}, {}, {}
              ]]),
            ],
          },
          margin: [0, 0, 0, 8],
        },
      ],
      defaultStyle: {
        font: 'Roboto',
        fontSize: 9,
        color: '#1f2937',
      },
    };

    const pdfDoc = printer.createPdfKitDocument(docDef);

    const chunks: Buffer[] = [];

    await new Promise<void>((resolve, reject) => {
      pdfDoc.on('data', (chunk: Buffer) => chunks.push(chunk));
      pdfDoc.on('end', resolve);
      pdfDoc.on('error', reject);
      pdfDoc.end();
    });

    const pdfBuffer = Buffer.concat(chunks);

    return new NextResponse(pdfBuffer, {
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="reporte-ventas-${ahora.toISOString().split('T')[0]}.pdf"`,
        'Content-Length': String(pdfBuffer.length),
      },
    });
  } catch (error) {
    console.error('PDF error:', error);
    return NextResponse.json({ error: 'Error al generar PDF' }, { status: 500 });
  }
}
