'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { TrendingUp } from 'lucide-react';
import { formatearMoneda } from '@/lib/types';
import SalesChart from '@/components/SalesChart';
import CategoryChart from '@/components/CategoryChart';
import ExportPDFButton from '@/components/ExportPDFButton';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.08, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
};

export default function ReportesPage() {
  const [data, setData] = useState<{
    ventasPorDia: { fecha: string; total: number }[];
    ventasPorCategoria: { categoria: string; total: number }[];
    topProductos: { id: string; nombre: string; cantidad: number }[];
  }>({ ventasPorDia: [], ventasPorCategoria: [], topProductos: [] });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        setError('');
        const res = await fetch('/api/reportes');
        const json = await res.json();
        if (res.ok) {
          setData({
            ventasPorDia: Array.isArray(json.ventasPorDia) ? json.ventasPorDia : [],
            ventasPorCategoria: Array.isArray(json.ventasPorCategoria) ? json.ventasPorCategoria : [],
            topProductos: Array.isArray(json.topProductos) ? json.topProductos : [],
          });
        } else {
          setError(json.error || 'Error al cargar reportes');
        }
      } catch {
        setError('Error de conexion');
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando reportes...</p>
        </div>
      </div>
    );
  }

  const totalVentas = data.ventasPorDia.reduce((s, d) => s + d.total, 0);

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-6">
      <motion.div variants={itemVariants} className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Reportes</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Analisis de ventas y rendimiento</p>
        </div>
        <ExportPDFButton />
      </motion.div>

      {error && (
        <motion.div variants={itemVariants} className="bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-600 dark:text-red-400 p-3 rounded-xl text-sm">
          {error}
        </motion.div>
      )}

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
                <div className="w-8 h-8 rounded-xl bg-blue-50 dark:bg-blue-500/10 border border-blue-100 dark:border-blue-500/20 flex items-center justify-center flex-shrink-0">
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
    </motion.div>
  );
}
