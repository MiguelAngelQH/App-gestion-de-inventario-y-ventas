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

    const [productosSnap, proveedoresSnap] = await Promise.all([
      db.collection('productos').where('uid', '==', uid).get(),
      db.collection('proveedores').where('uid', '==', uid).get(),
    ]);

    const proveedorMap: Record<string, string> = {};
    for (const doc of proveedoresSnap.docs) {
      const p: any = doc.data();
      proveedorMap[doc.id] = p.nombre;
    }

    let stockTotalGeneral = 0;
    let costoTotalInventario = 0;
    let productosConStock = 0;
    let stockBajo = 0;

    const productosBody: any[] = [];
    for (const doc of productosSnap.docs) {
      const p: any = doc.data();
      const stock = p.stock ?? 0;
      const costo = p.costo ?? 0;
      stockTotalGeneral += stock;
      costoTotalInventario += stock * costo;
      if (stock > 0) productosConStock++;
      if (stock <= 5) stockBajo++;

      const preciosStr = (p.presentaciones ?? [])
        .map((pr: any) => `${formatearMoneda(pr.precio)}/${pr.unidad}`)
        .join(', ');

      productosBody.push([
        { text: p.nombre ?? '—', color: '#1f2937', fontSize: 8 },
        { text: p.categoria ?? 'General', color: '#6b7280', fontSize: 8 },
        { text: p.marca ?? '—', color: '#6b7280', fontSize: 8 },
        { text: proveedorMap[p.proveedorId] || p.proveedorNombre || '—', color: '#6b7280', fontSize: 8 },
        { text: String(stock), alignment: 'center' as const, color: stock <= 5 ? '#dc2626' : '#1f2937', fontSize: 8 },
        { text: formatearMoneda(costo), alignment: 'right' as const, color: '#1f2937', fontSize: 8 },
        { text: formatearMoneda(stock * costo), alignment: 'right' as const, color: '#059669', fontSize: 8 },
        { text: preciosStr, color: '#6b7280', fontSize: 7 },
        { text: p.codigoBarras || '—', color: '#6b7280', fontSize: 7, alignment: 'center' as const },
      ]);
    }

    const printer = new PdfPrinter(fonts);

    const docDef = {
      pageSize: 'A4' as const,
      pageOrientation: 'landscape' as const,
      pageMargins: [25, 40, 25, 60],
      header: (currentPage: number) => ({
        margin: [25, 15, 25, 0],
        columns: [
          { text: 'SMARTVENTAS', color: '#1e40af', bold: true, fontSize: 9 },
          { text: `Página ${currentPage}`, alignment: 'right', color: '#9ca3af', fontSize: 8 },
        ],
      }),
      footer: (currentPage: number, pageCount: number) => ({
        margin: [25, 0, 25, 15],
        stack: [
          { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 770, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }] },
          { text: 'SmartVentas — Reporte de Inventario', alignment: 'center', color: '#9ca3af', fontSize: 7, margin: [0, 4, 0, 0] },
        ],
      }),
      content: [
        {
          stack: [
            { text: 'SMARTVENTAS', fontSize: 24, bold: true, color: '#1e40af', letterSpacing: 2 },
            { text: 'Reporte de Inventario de Productos', fontSize: 13, color: '#6b7280', margin: [0, 2, 0, 0] },
            { text: `Generado el ${formatearFecha()}`, fontSize: 8, color: '#9ca3af', margin: [0, 4, 0, 0] },
          ],
          margin: [0, 0, 0, 12],
        },

        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 770, y2: 0, lineWidth: 1, lineColor: '#1e40af' }], margin: [0, 0, 0, 12] },

        {
          text: 'RESUMEN DEL INVENTARIO',
          fontSize: 10,
          bold: true,
          color: '#1e40af',
          margin: [0, 0, 0, 6],
        },

        {
          layout: 'noBorders',
          table: {
            widths: ['*', '*', '*', '*'],
            body: [[
              { stack: [
                { text: String(productosSnap.size), fontSize: 18, bold: true, color: '#1d4ed8' },
                { text: 'Total Productos', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 8] },
              { stack: [
                { text: String(stockTotalGeneral), fontSize: 18, bold: true, color: '#059669' },
                { text: 'Unidades en Stock', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 8] },
              { stack: [
                { text: formatearMoneda(costoTotalInventario), fontSize: 18, bold: true, color: '#7c3aed' },
                { text: 'Valor Total Inventario', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 8] },
              { stack: [
                { text: String(stockBajo), fontSize: 18, bold: true, color: stockBajo > 0 ? '#dc2626' : '#059669' },
                { text: 'Productos con Stock Bajo', fontSize: 8, color: '#6b7280', margin: [0, 1, 0, 0] },
              ], alignment: 'center', margin: [0, 8] },
            ]],
          },
          margin: [0, 0, 0, 16],
        },

        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 770, y2: 0, lineWidth: 0.5, lineColor: '#e5e7eb' }], margin: [0, 0, 0, 8] },

        {
          text: 'LISTADO COMPLETO DE PRODUCTOS',
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
            widths: ['*', 50, 45, 55, 30, 45, 55, '*', 55],
            headerRows: 1,
            body: [
              [
                { text: 'Producto', color: '#ffffff', bold: true, fontSize: 7.5 },
                { text: 'Categoría', alignment: 'center', color: '#ffffff', bold: true, fontSize: 7.5 },
                { text: 'Marca', alignment: 'center', color: '#ffffff', bold: true, fontSize: 7.5 },
                { text: 'Proveedor', alignment: 'center', color: '#ffffff', bold: true, fontSize: 7.5 },
                { text: 'Stock', alignment: 'center', color: '#ffffff', bold: true, fontSize: 7.5 },
                { text: 'Costo', alignment: 'right', color: '#ffffff', bold: true, fontSize: 7.5 },
                { text: 'Valor Total', alignment: 'right', color: '#ffffff', bold: true, fontSize: 7.5 },
                { text: 'Precios Venta', alignment: 'center', color: '#ffffff', bold: true, fontSize: 7.5 },
                { text: 'Código Barras', alignment: 'center', color: '#ffffff', bold: true, fontSize: 7.5 },
              ],
              ...(productosBody.length > 0 ? productosBody : [[
                { text: 'No hay productos registrados', colSpan: 9, alignment: 'center' as const, color: '#9ca3af', fontSize: 8 }, {}, {}, {}, {}, {}, {}, {}, {}
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
        'Content-Disposition': `attachment; filename="inventario-productos-${new Date().toISOString().split('T')[0]}.pdf"`,
        'Content-Length': String(pdfBuffer.length),
      },
    });
  } catch (error) {
    console.error('Inventario PDF error:', error);
    return NextResponse.json({ error: 'Error al generar PDF' }, { status: 500 });
  }
}