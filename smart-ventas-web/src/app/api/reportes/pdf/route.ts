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
  return '$' + valor.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
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
      pageSize: 'A4',
      pageMargins: [40, 40, 40, 60],
      header: (currentPage: number) => ({
        margin: [40, 20, 40, 0],
        columns: [
          { text: 'SMARTVENTAS', color: '#1e40af', bold: true, fontSize: 9 },
          { text: `Página ${currentPage}`, alignment: 'right', color: '#9ca3af', fontSize: 8 },
        ],
      }),
      footer: (currentPage: number, pageCount: number) => ({
        margin: [40, 0, 40, 20],
        stack: [
          { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 515, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }] },
          { text: 'SmartVentas — Sistema de Gestión Empresarial', alignment: 'center', color: '#9ca3af', fontSize: 7, margin: [0, 4, 0, 0] },
        ],
      }),
      content: [
        {
          stack: [
            { text: 'SMARTVENTAS', fontSize: 28, bold: true, color: '#1e40af', letterSpacing: 2 },
            { text: 'Reporte de Ventas', fontSize: 14, color: '#6b7280', margin: [0, 2, 0, 0] },
            { text: `Generado el ${formatearFecha()}`, fontSize: 8, color: '#9ca3af', margin: [0, 4, 0, 0] },
          ],
          margin: [0, 0, 0, 16],
        },

        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 515, y2: 0, lineWidth: 1, lineColor: '#1e40af' }], margin: [0, 0, 0, 16] },

        {
          text: 'MÉTRICAS DEL DÍA',
          fontSize: 11,
          bold: true,
          color: '#1e40af',
          margin: [0, 0, 0, 8],
        },

        {
          layout: 'noBorders',
          table: {
            widths: ['*', '*', '*'],
            body: [
              [
                {
                  stack: [
                    { text: formatearMoneda(ventasHoy), fontSize: 20, bold: true, color: '#059669' },
                    { text: 'Ventas Hoy', fontSize: 9, color: '#6b7280', margin: [0, 2, 0, 0] },
                    { text: `${ventasCountHoy} transacciones`, fontSize: 8, color: '#9ca3af', margin: [0, 1, 0, 0] },
                  ],
                  alignment: 'center',
                  margin: [0, 8],
                },
                {
                  stack: [
                    { text: formatearMoneda(ventasSemana), fontSize: 20, bold: true, color: '#1d4ed8' },
                    { text: 'Ventas (7 días)', fontSize: 9, color: '#6b7280', margin: [0, 2, 0, 0] },
                  ],
                  alignment: 'center',
                  margin: [0, 8],
                },
                {
                  stack: [
                    { text: formatearMoneda(gananciaTotal), fontSize: 20, bold: true, color: '#059669' },
                    { text: 'Ganancia Total', fontSize: 9, color: '#6b7280', margin: [0, 2, 0, 0] },
                  ],
                  alignment: 'center',
                  margin: [0, 8],
                },
              ],
              [
                {
                  stack: [
                    { text: String(stockBajo), fontSize: 20, bold: true, color: stockBajo > 0 ? '#dc2626' : '#059669' },
                    { text: 'Productos Stock Bajo', fontSize: 9, color: '#6b7280', margin: [0, 2, 0, 0] },
                  ],
                  alignment: 'center',
                  margin: [0, 8],
                },
                {
                  stack: [
                    { text: formatearMoneda(cuentasCobrar), fontSize: 20, bold: true, color: '#7c3aed' },
                    { text: 'Cuentas por Cobrar', fontSize: 9, color: '#6b7280', margin: [0, 2, 0, 0] },
                  ],
                  alignment: 'center',
                  margin: [0, 8],
                },
                {
                  stack: [
                    { text: formatearMoneda(cuentasPagar), fontSize: 20, bold: true, color: '#d97706' },
                    { text: 'Cuentas por Pagar', fontSize: 9, color: '#6b7280', margin: [0, 2, 0, 0] },
                  ],
                  alignment: 'center',
                  margin: [0, 8],
                },
              ],
            ],
          },
          margin: [0, 0, 0, 20],
        },

        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 515, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }], margin: [0, 0, 0, 12] },

        {
          text: 'TOP 5 PRODUCTOS MÁS VENDIDOS',
          fontSize: 11,
          bold: true,
          color: '#1e40af',
          margin: [0, 0, 0, 8],
        },

        {
          layout: {
            hLineWidth: () => 0.5,
            vLineWidth: () => 0,
            hLineColor: () => '#e5e7eb',
            fillColor: (rowIndex: number) => rowIndex === 0 ? '#1e40af' : (rowIndex % 2 === 0 ? '#f8fafc' : null),
          },
          table: {
            widths: [30, '*', 50, 80],
            headerRows: 1,
            body: [
              [
                { text: '#', alignment: 'center', color: '#ffffff', bold: true, fontSize: 9 },
                { text: 'Producto', color: '#ffffff', bold: true, fontSize: 9 },
                { text: 'Cant.', alignment: 'center', color: '#ffffff', bold: true, fontSize: 9 },
                { text: 'Total', alignment: 'right', color: '#ffffff', bold: true, fontSize: 9 },
              ],
              ...topProductosBody,
            ],
          },
          margin: [0, 0, 0, 16],
        },

        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 515, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }], margin: [0, 0, 0, 12] },

        {
          text: 'VENTAS POR CATEGORÍA',
          fontSize: 11,
          bold: true,
          color: '#1e40af',
          margin: [0, 0, 0, 8],
        },

        {
          layout: {
            hLineWidth: () => 0.5,
            vLineWidth: () => 0,
            hLineColor: () => '#e5e7eb',
            fillColor: (rowIndex: number) => rowIndex % 2 === 0 ? '#f8fafc' : null,
          },
          table: {
            widths: ['*', 100],
            body: [
              [
                { text: 'Categoría', color: '#6b7280', bold: true, fontSize: 9 },
                { text: 'Total', alignment: 'right', color: '#6b7280', bold: true, fontSize: 9 },
              ],
              ...categoriasBody,
            ],
          },
          margin: [0, 0, 0, 16],
        },

        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 515, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }], margin: [0, 0, 0, 12] },

        {
          text: 'VENTAS ÚLTIMOS 7 DÍAS',
          fontSize: 11,
          bold: true,
          color: '#1e40af',
          margin: [0, 0, 0, 8],
        },

        {
          layout: {
            hLineWidth: () => 0.5,
            vLineWidth: () => 0,
            hLineColor: () => '#e5e7eb',
            fillColor: (rowIndex: number) => rowIndex % 2 === 0 ? '#f8fafc' : null,
          },
          table: {
            widths: [60, '*', 80],
            body: [
              [
                { text: 'Fecha', color: '#6b7280', bold: true, fontSize: 9 },
                { text: 'Total', alignment: 'right', color: '#6b7280', bold: true, fontSize: 9 },
                { text: 'Transacciones', alignment: 'center', color: '#6b7280', bold: true, fontSize: 9 },
              ],
              ...ventas7Body,
            ],
          },
          margin: [0, 0, 0, 16],
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
