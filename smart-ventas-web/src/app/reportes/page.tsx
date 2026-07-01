'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { TrendingUp, FileDown, Package, BarChart3 } from 'lucide-react';
import { formatearMoneda, Producto } from '@/lib/types';
import SalesChart from '@/components/SalesChart';
import CategoryChart from '@/components/CategoryChart';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.08, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
};

type TipoReporte = 'ventas' | 'productos';

export default function ReportesPage() {
  const [tipo, setTipo] = useState<TipoReporte>('ventas');
  const [data, setData] = useState<{
    ventasPorDia: { fecha: string; total: number }[];
    ventasPorCategoria: { categoria: string; total: number }[];
    topProductos: { id: string; nombre: string; cantidad: number }[];
  }>({ ventasPorDia: [], ventasPorCategoria: [], topProductos: [] });
  const [productos, setProductos] = useState<Producto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        setError('');
        const [resVentas, resProd] = await Promise.all([
          fetch('/api/reportes'),
          fetch('/api/productos'),
        ]);
        const jsonVentas = await resVentas.json();
        const jsonProd = await resProd.json();
        if (resVentas.ok) {
          setData({
            ventasPorDia: Array.isArray(jsonVentas.ventasPorDia) ? jsonVentas.ventasPorDia : [],
            ventasPorCategoria: Array.isArray(jsonVentas.ventasPorCategoria) ? jsonVentas.ventasPorCategoria : [],
            topProductos: Array.isArray(jsonVentas.topProductos) ? jsonVentas.topProductos : [],
          });
        } else {
          setError(jsonVentas.error || 'Error al cargar reportes');
        }
        setProductos(Array.isArray(jsonProd) ? jsonProd : []);
      } catch {
        setError('Error de conexion');
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const exportVentasPDF = async () => {
    try {
      const res = await fetch('/api/reportes/pdf');
      if (!res.ok) throw new Error('Error al generar PDF');
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `reporte-ventas-${new Date().toISOString().split('T')[0]}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch {
      alert('Error al exportar PDF');
    }
  };

  const exportProductosPDF = async () => {
    try {
      const res = await fetch('/api/reportes/inventario');
      if (!res.ok) throw new Error('Error al generar PDF');
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `inventario-productos-${new Date().toISOString().split('T')[0]}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch {
      alert('Error al exportar PDF');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-teal-600/30 border-t-teal-600 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando reportes...</p>
        </div>
      </div>
    );
  }

  const totalVentas = data.ventasPorDia.reduce((s, d) => s + d.total, 0);

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-6">
      <motion.div variants={itemVariants} className="flex items-start justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Reportes</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Analisis y exportacion de datos</p>
        </div>
        <div className="flex gap-2">
          <div className="relative">
            <BarChart3 size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)] pointer-events-none" />
            <select
              value={tipo}
              onChange={e => setTipo(e.target.value as TipoReporte)}
              className="pl-10 pr-4 py-2.5 min-w-[180px] appearance-none cursor-pointer"
            >
              <option value="ventas">Ventas y Ganancias</option>
              <option value="productos">Inventario de Productos</option>
            </select>
          </div>
          {tipo === 'ventas' ? (
            <button onClick={exportVentasPDF} className="btn-primary">
              <FileDown size={16} /> Exportar PDF
            </button>
          ) : (
            <button onClick={exportProductosPDF} className="btn-primary">
              <FileDown size={16} /> Exportar PDF
            </button>
          )}
        </div>
      </motion.div>

      {error && (
        <motion.div variants={itemVariants} className="bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-600 dark:text-red-400 p-3 rounded-xl text-sm">
          {error}
        </motion.div>
      )}

      {tipo === 'ventas' ? (
        <>
          <motion.div variants={itemVariants} className="card p-5 relative overflow-hidden">
            <div className="flex items-center gap-2 mb-2">
              <TrendingUp size={16} className="text-[var(--accent)]" />
              <p className="text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">Total Ventas (7 dias)</p>
            </div>
            <p className="text-3xl font-bold text-[var(--text-primary)]">
              {formatearMoneda(totalVentas)}
            </p>
          </motion.div>

          <motion.div variants={itemVariants} className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <SalesChart data={data.ventasPorDia} />
            <CategoryChart data={data.ventasPorCategoria} />
          </motion.div>

          {data.topProductos.length > 0 && (
            <motion.div variants={itemVariants} className="card p-5">
              <h3 className="text-sm font-semibold text-[var(--text-primary)] mb-4">Top 5 Productos Mas Vendidos</h3>
              <div className="space-y-4">
                {data.topProductos.map((p, i) => (
                  <div key={p.id} className="flex items-center gap-4">
                    <div className="w-8 h-8 rounded-xl bg-teal-50 dark:bg-teal-600/10 border border-blue-100 dark:border-teal-600/20 flex items-center justify-center flex-shrink-0">
                      <span className="text-xs font-bold text-[var(--accent)]">#{i + 1}</span>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex justify-between mb-1.5">
                        <span className="text-sm font-medium text-[var(--text-primary)] truncate">{p.nombre}</span>
                        <span className="text-xs text-[var(--text-muted)] flex-shrink-0 ml-2">{p.cantidad} vendidos</span>
                      </div>
                      <div className="w-full bg-[var(--bg-tertiary)] rounded-full h-2.5 overflow-hidden">
                        <motion.div
                          initial={{ width: 0 }}
                          animate={{ width: `${Math.min(100, (p.cantidad / data.topProductos[0].cantidad) * 100)}%` }}
                          transition={{ duration: 1, delay: 0.3 + i * 0.1 }}
                          className="h-full rounded-full bg-[var(--accent)]"
                        />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </motion.div>
          )}
        </>
      ) : (
        <motion.div variants={itemVariants} className="card overflow-hidden">
          <div className="p-4 border-b border-[var(--border)] flex items-center gap-2">
            <Package size={16} className="text-[var(--accent)]" />
            <h3 className="text-sm font-semibold text-[var(--text-primary)]">Inventario Completo de Productos</h3>
            <span className="ml-auto text-xs text-[var(--text-muted)]">{productos.length} producto(s)</span>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr>
                  <th>Producto</th>
                  <th>Categoria</th>
                  <th>Marca</th>
                  <th className="text-center">Stock</th>
                  <th className="text-right">Costo</th>
                  <th className="text-right">Valor Total</th>
                  <th>Precios</th>
                  <th className="text-center">Codigo</th>
                </tr>
              </thead>
              <tbody>
                {productos.map(p => (
                  <tr key={p.id}>
                    <td className="font-medium text-[var(--text-primary)]">{p.nombre}</td>
                    <td className="text-[var(--text-secondary)]">{p.categoria}</td>
                    <td className="text-[var(--text-secondary)]">{p.marca || '—'}</td>
                    <td className={`text-center font-medium ${(p.stock ?? 0) <= 5 ? 'text-red-600 dark:text-red-400' : 'text-[var(--text-primary)]'}`}>
                      {p.stock ?? 0}
                    </td>
                    <td className="text-right text-[var(--text-secondary)]">{formatearMoneda(p.costo ?? 0)}</td>
                    <td className="text-right font-medium text-[var(--accent)]">{formatearMoneda((p.stock ?? 0) * (p.costo ?? 0))}</td>
                    <td className="text-[var(--text-muted)] text-xs">
                      {(p.presentaciones || []).map(pr => `${formatearMoneda(pr.precio)}/${pr.unidad}`).join(', ')}
                    </td>
                    <td className="text-center text-[var(--text-muted)] text-xs">{p.codigoBarras || '—'}</td>
                  </tr>
                ))}
                {productos.length === 0 && (
                  <tr><td colSpan={8} className="p-12 text-center text-[var(--text-muted)]">No hay productos registrados</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </motion.div>
      )}
    </motion.div>
  );
}