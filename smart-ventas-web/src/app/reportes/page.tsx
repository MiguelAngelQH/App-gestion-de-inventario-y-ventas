'use client';

import { useEffect, useState } from 'react';
import { formatearMoneda } from '@/lib/types';
import SalesChart from '@/components/SalesChart';
import CategoryChart from '@/components/CategoryChart';

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
        setError('Error de conexión');
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  if (loading) return <div className="text-slate-500">Cargando reportes...</div>;

  const totalVentas = data.ventasPorDia.reduce((s, d) => s + d.total, 0);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-slate-800">Reportes</h1>

      {error && <div className="bg-red-50 text-red-600 p-3 rounded-lg text-sm">{error}</div>}

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
        <p className="text-sm text-slate-500">Total ventas (7 días)</p>
        <p className="text-3xl font-bold text-blue-600 mt-1">{formatearMoneda(totalVentas)}</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <SalesChart data={data.ventasPorDia} />
        <CategoryChart data={data.ventasPorCategoria} />
      </div>

      {data.topProductos.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
          <h3 className="text-sm font-semibold text-slate-700 mb-4">Top 5 Productos Más Vendidos</h3>
          <div className="space-y-3">
            {data.topProductos.map((p, i) => (
              <div key={p.id} className="flex items-center gap-4">
                <span className="text-lg font-bold text-slate-400 w-6">#{i + 1}</span>
                <div className="flex-1">
                  <div className="flex justify-between mb-1">
                    <span className="text-sm font-medium text-slate-700">{p.nombre}</span>
                    <span className="text-sm text-slate-500">{p.cantidad} vendidos</span>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-2.5">
                    <div className="bg-gradient-to-r from-blue-500 to-indigo-500 h-2.5 rounded-full transition-all" style={{ width: `${Math.min(100, (p.cantidad / data.topProductos[0].cantidad) * 100)}%` }} />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
