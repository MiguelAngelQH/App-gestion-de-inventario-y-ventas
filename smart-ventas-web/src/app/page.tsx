'use client';

import { useEffect, useState } from 'react';
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

export default function Dashboard() {
  const [metrics, setMetrics] = useState<DashboardData | null>(null);
  const [reportes, setReportes] = useState<ReportesData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetchJson<DashboardData>('/api/dashboard', {
        ventasHoy: 0, ventasSemana: 0, gananciaTotal: 0,
        stockBajo: 0, cuentasCobrar: 0, cuentasPagar: 0, ventasCountHoy: 0,
      }),
      fetchJson<ReportesData>('/api/reportes', {
        ventasPorDia: [], ventasPorCategoria: [], topProductos: [],
      }),
    ]).then(([m, r]) => {
      setMetrics(m);
      setReportes(r);
    }).finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-slate-500">Cargando dashboard...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-slate-800">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard titulo="Ventas Hoy" valor={formatearMoneda(metrics?.ventasHoy ?? 0)} color="text-blue-600" icono="💰" />
        <MetricCard titulo="Ventas (7 días)" valor={formatearMoneda(metrics?.ventasSemana ?? 0)} color="text-emerald-600" icono="📈" />
        <MetricCard titulo="Ganancia Total" valor={formatearMoneda(metrics?.gananciaTotal ?? 0)} color="text-green-600" icono="🏆" />
        <MetricCard titulo="Stock Bajo" valor={String(metrics?.stockBajo ?? 0)} color="text-orange-600" icono="⚠️" />
        <MetricCard titulo="Cuentas por Cobrar" valor={formatearMoneda(metrics?.cuentasCobrar ?? 0)} color="text-purple-600" icono="📋" />
        <MetricCard titulo="Cuentas por Pagar" valor={formatearMoneda(metrics?.cuentasPagar ?? 0)} color="text-red-600" icono="💳" />
        <MetricCard titulo="Ventas Hoy (cant.)" valor={String(metrics?.ventasCountHoy ?? 0)} color="text-indigo-600" icono="🛒" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <SalesChart data={reportes?.ventasPorDia ?? []} />
        <CategoryChart data={reportes?.ventasPorCategoria ?? []} />
      </div>

      {Array.isArray(reportes?.topProductos) && reportes.topProductos.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
          <h3 className="text-sm font-semibold text-slate-700 mb-4">Top 5 Productos</h3>
          <div className="space-y-3">
            {reportes.topProductos.map((p, i) => (
              <div key={p.id} className="flex items-center gap-4">
                <span className="text-lg font-bold text-slate-400 w-6">#{i + 1}</span>
                <div className="flex-1">
                  <p className="text-sm font-medium text-slate-700">{p.nombre}</p>
                  <div className="w-full bg-slate-100 rounded-full h-2 mt-1">
                    <div className="bg-blue-500 h-2 rounded-full" style={{ width: `${Math.min(100, (p.cantidad / Math.max(...reportes.topProductos.map(x => x.cantidad))) * 100)}%` }} />
                  </div>
                </div>
                <span className="text-sm font-semibold text-slate-600">{p.cantidad} vendidos</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
