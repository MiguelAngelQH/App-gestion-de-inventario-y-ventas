'use client';

import { useEffect, useState, useRef, useCallback } from 'react';
import { motion } from 'framer-motion';
import { DollarSign, TrendingUp, Award, AlertTriangle, Receipt, CreditCard, ShoppingCart } from 'lucide-react';
import MetricCard from '@/components/MetricCard';
import SalesChart from '@/components/SalesChart';
import CategoryChart from '@/components/CategoryChart';
import { formatearMoneda } from '@/lib/types';

interface DashboardData {
  ventasHoy: number;
  ventasSemana: number;
  gananciaTotal: number;
  stockBajo: number;
  cuentasCobrar: number;
  cuentasPagar: number;
  ventasCountHoy: number;
}

interface ReportesData {
  ventasPorDia: { fecha: string; total: number }[];
  ventasPorCategoria: { categoria: string; total: number }[];
  topProductos: { id: string; nombre: string; cantidad: number }[];
}

async function fetchJson<T>(url: string, fallback: T): Promise<T> {
  try {
    const res = await fetch(url);
    if (!res.ok) return fallback;
    const data = await res.json();
    return data ?? fallback;
  } catch {
    return fallback;
  }
}

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.08, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

export default function Dashboard() {
  const [metrics, setMetrics] = useState<DashboardData | null>(null);
  const [reportes, setReportes] = useState<ReportesData | null>(null);
  const [loading, setLoading] = useState(true);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchData = useCallback(async () => {
    const [m, r] = await Promise.all([
      fetchJson<DashboardData>('/api/dashboard', {
        ventasHoy: 0, ventasSemana: 0, gananciaTotal: 0,
        stockBajo: 0, cuentasCobrar: 0, cuentasPagar: 0, ventasCountHoy: 0,
      }),
      fetchJson<ReportesData>('/api/reportes', {
        ventasPorDia: [], ventasPorCategoria: [], topProductos: [],
      }),
    ]);
    setMetrics(m);
    setReportes(r);
  }, []);

  useEffect(() => {
    fetchData().finally(() => setLoading(false));
    intervalRef.current = setInterval(fetchData, 30000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [fetchData]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-6">
      <motion.div variants={itemVariants}>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">Dashboard</h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">Resumen general de tu negocio</p>
      </motion.div>

      <motion.div variants={itemVariants} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard titulo="Ventas Hoy" valor={formatearMoneda(metrics?.ventasHoy ?? 0)} icono={DollarSign} color="from-emerald-500 to-teal-600" />
        <MetricCard titulo="Ventas (7 dias)" valor={formatearMoneda(metrics?.ventasSemana ?? 0)} icono={TrendingUp} color="from-blue-500 to-indigo-600" />
        <MetricCard titulo="Ganancia Total" valor={formatearMoneda(metrics?.gananciaTotal ?? 0)} icono={Award} color="from-amber-500 to-orange-600" />
        <MetricCard titulo="Stock Bajo" valor={String(metrics?.stockBajo ?? 0)} icono={AlertTriangle} color="from-red-500 to-rose-600" />
        <MetricCard titulo="Cuentas por Cobrar" valor={formatearMoneda(metrics?.cuentasCobrar ?? 0)} icono={Receipt} color="from-purple-500 to-violet-600" />
        <MetricCard titulo="Cuentas por Pagar" valor={formatearMoneda(metrics?.cuentasPagar ?? 0)} icono={CreditCard} color="from-pink-500 to-rose-600" />
        <MetricCard titulo="Ventas Hoy (cant.)" valor={String(metrics?.ventasCountHoy ?? 0)} icono={ShoppingCart} color="from-sky-500 to-blue-600" />
      </motion.div>

      <motion.div variants={itemVariants} className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <SalesChart data={reportes?.ventasPorDia ?? []} />
        <CategoryChart data={reportes?.ventasPorCategoria ?? []} />
      </motion.div>

      {Array.isArray(reportes?.topProductos) && reportes.topProductos.length > 0 && (
        <motion.div variants={itemVariants} className="card p-5">
          <h3 className="text-sm font-semibold text-[var(--text-primary)] mb-4">Top 5 Productos</h3>
          <div className="space-y-4">
            {reportes.topProductos.map((p, i) => (
              <div key={p.id} className="flex items-center gap-4">
                <div className="w-8 h-8 rounded-xl bg-blue-50 dark:bg-blue-500/10 border border-blue-100 dark:border-blue-500/20 flex items-center justify-center flex-shrink-0">
                  <span className="text-xs font-bold text-blue-600 dark:text-blue-400">#{i + 1}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex justify-between mb-1.5">
                    <span className="text-sm font-medium text-[var(--text-primary)] truncate">{p.nombre}</span>
                    <span className="text-xs text-[var(--text-muted)] flex-shrink-0 ml-2">{p.cantidad} vendidos</span>
                  </div>
                  <div className="w-full bg-gray-100 dark:bg-white/5 rounded-full h-2 overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${Math.min(100, (p.cantidad / Math.max(...reportes.topProductos.map(x => x.cantidad))) * 100)}%` }}
                      transition={{ duration: 1, delay: 0.3 + i * 0.1 }}
                      className="h-full rounded-full bg-gradient-to-r from-blue-500 to-indigo-500"
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
