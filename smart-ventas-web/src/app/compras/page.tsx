'use client';

import { useEffect, useState } from 'react';
import { Compra, formatearMoneda, formatearFechaHora, ESTADOS_COMPRA } from '@/lib/types';
import StatusBadge from '@/components/StatusBadge';

export default function ComprasPage() {
  const [compras, setCompras] = useState<Compra[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filterEstado, setFilterEstado] = useState('');
  const [selected, setSelected] = useState<Compra | null>(null);

  const load = async () => {
    try {
      setError('');
      const res = await fetch('/api/compras');
      const data = await res.json();
      setCompras(Array.isArray(data) ? data : []);
      if (!res.ok) setError(data.error || 'Error al cargar compras');
    } catch {
      setError('Error de conexión');
      setCompras([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const filtered = Array.isArray(compras)
    ? (filterEstado ? compras.filter(c => c.estado === filterEstado) : compras)
    : [];

  const cambiarEstado = async (id: string, estado: string) => {
    await fetch(`/api/compras?id=${id}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ estado }) });
    load();
  };

  if (loading) return <div className="text-slate-500">Cargando compras...</div>;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-800">Compras</h1>
        <div className="flex gap-2">
          {['', ...ESTADOS_COMPRA].map(e => (
            <button key={e} onClick={() => setFilterEstado(e)} className={`px-3 py-1.5 rounded-lg text-sm ${filterEstado === e ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}>{e || 'Todos'}</button>
          ))}
        </div>
      </div>

      {error && <div className="bg-red-50 text-red-600 p-3 rounded-lg text-sm">{error}</div>}

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-slate-50 text-slate-600">
              <th className="text-left p-3 font-medium">Folio</th>
              <th className="text-left p-3 font-medium">Fecha</th>
              <th className="text-left p-3 font-medium">Proveedor</th>
              <th className="text-right p-3 font-medium">Total</th>
              <th className="text-center p-3 font-medium">Estado</th>
              <th className="text-center p-3 font-medium">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(c => (
              <tr key={c.id} className="border-t border-slate-100 hover:bg-slate-50 cursor-pointer" onClick={() => setSelected(c)}>
                <td className="p-3 font-mono text-xs text-slate-500">C-{c.id.substring(0, 8).toUpperCase()}</td>
                <td className="p-3 text-slate-700">{formatearFechaHora(c.fecha)}</td>
                <td className="p-3">{c.proveedorNombre}</td>
                <td className="p-3 text-right font-semibold">{formatearMoneda(c.total)}</td>
                <td className="p-3 text-center"><StatusBadge estado={c.estado} /></td>
                <td className="p-3 text-center space-x-2">
                  {c.estado === 'pendiente' && <button onClick={(e) => { e.stopPropagation(); cambiarEstado(c.id, 'recibida'); }} className="text-green-600 hover:text-green-800 text-xs">Recibir</button>}
                  {c.estado !== 'cancelada' && <button onClick={(e) => { e.stopPropagation(); cambiarEstado(c.id, 'cancelada'); }} className="text-red-600 hover:text-red-800 text-xs">Cancelar</button>}
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan={6} className="p-8 text-center text-slate-400">No hay compras</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setSelected(null)}>
          <div className="bg-white rounded-xl p-6 w-full max-w-lg space-y-4" onClick={e => e.stopPropagation()}>
            <h2 className="text-lg font-bold">Detalle de Compra</h2>
            <div className="text-sm space-y-2">
              <p><span className="text-slate-500">Folio:</span> C-{selected.id.substring(0, 8).toUpperCase()}</p>
              <p><span className="text-slate-500">Fecha:</span> {formatearFechaHora(selected.fecha)}</p>
              <p><span className="text-slate-500">Proveedor:</span> {selected.proveedorNombre}</p>
              <p><span className="text-slate-500">Estado:</span> <StatusBadge estado={selected.estado} /></p>
            </div>
            <table className="w-full text-sm border-t pt-3">
              <thead>
                <tr className="text-slate-500">
                  <th className="text-left p-2">Producto</th>
                  <th className="text-right p-2">Cant.</th>
                  <th className="text-right p-2">Costo U.</th>
                  <th className="text-right p-2">Subtotal</th>
                </tr>
              </thead>
              <tbody>
                {selected.items.map((item, i) => (
                  <tr key={i} className="border-t border-slate-100">
                    <td className="p-2">{item.productoNombre}</td>
                    <td className="p-2 text-right">{item.cantidad}</td>
                    <td className="p-2 text-right">{formatearMoneda(item.costoUnitario)}</td>
                    <td className="p-2 text-right font-medium">{formatearMoneda(item.subtotal)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="border-t font-bold">
                  <td colSpan={3} className="p-2 text-right">Total</td>
                  <td className="p-2 text-right">{formatearMoneda(selected.total)}</td>
                </tr>
              </tfoot>
            </table>
            <button onClick={() => setSelected(null)} className="w-full py-2 text-sm text-slate-500 hover:text-slate-700">Cerrar</button>
          </div>
        </div>
      )}
    </div>
  );
}
