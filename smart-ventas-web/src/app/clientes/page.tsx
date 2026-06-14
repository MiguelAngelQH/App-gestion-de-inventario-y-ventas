'use client';

import { useEffect, useState } from 'react';
import { Cliente, formatearMoneda, formatearFecha, ESTADOS_CLIENTE } from '@/lib/types';
import StatusBadge from '@/components/StatusBadge';

export default function ClientesPage() {
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [formOpen, setFormOpen] = useState(false);
  const [pagoOpen, setPagoOpen] = useState<string | null>(null);
  const [montoPago, setMontoPago] = useState(0);
  const [notaPago, setNotaPago] = useState('');
  const [form, setForm] = useState({ nombre: '', telefono: '', email: '', direccion: '', deuda: 0, estado: 'pendiente', fechaVencimiento: '' });

  const load = async () => {
    try {
      setError('');
      const res = await fetch('/api/clientes');
      const data = await res.json();
      setClientes(Array.isArray(data) ? data : []);
      if (!res.ok) setError(data.error || 'Error al cargar clientes');
    } catch {
      setError('Error de conexión');
      setClientes([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const guardar = async () => {
    await fetch('/api/clientes', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ...form, uid: 'web' }) });
    setFormOpen(false);
    setForm({ nombre: '', telefono: '', email: '', direccion: '', deuda: 0, estado: 'pendiente', fechaVencimiento: '' });
    load();
  };

  const registrarPago = async (id: string) => {
    await fetch(`/api/clientes/pago`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ clienteId: id, monto: montoPago, nota: notaPago }) });
    setPagoOpen(null);
    setMontoPago(0);
    setNotaPago('');
    load();
  };

  const cambiarEstado = async (id: string, estado: string) => {
    await fetch(`/api/clientes?id=${id}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ estado }) });
    load();
  };

  if (loading) return <div className="text-slate-500">Cargando clientes...</div>;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-800">Clientes — Cuentas por Cobrar</h1>
        <button onClick={() => setFormOpen(true)} className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">+ Nuevo Cliente</button>
      </div>

      {error && <div className="bg-red-50 text-red-600 p-3 rounded-lg text-sm">{error}</div>}

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-slate-50 text-slate-600">
              <th className="text-left p-3 font-medium">Nombre</th>
              <th className="text-left p-3 font-medium">Teléfono</th>
              <th className="text-right p-3 font-medium">Deuda</th>
              <th className="text-center p-3 font-medium">Vencimiento</th>
              <th className="text-center p-3 font-medium">Estado</th>
              <th className="text-center p-3 font-medium">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {Array.isArray(clientes) && clientes.map(c => (
              <tr key={c.id} className="border-t border-slate-100 hover:bg-slate-50">
                <td className="p-3 font-medium text-slate-800">{c.nombre}</td>
                <td className="p-3 text-slate-500">{c.telefono || '—'}</td>
                <td className="p-3 text-right font-semibold text-red-600">{formatearMoneda(c.deuda)}</td>
                <td className="p-3 text-center text-slate-500">{c.fechaVencimiento ? formatearFecha(c.fechaVencimiento) : '—'}</td>
                <td className="p-3 text-center"><StatusBadge estado={c.estado} /></td>
                <td className="p-3 text-center space-x-2">
                  {c.deuda > 0 && <button onClick={() => { setPagoOpen(c.id); setMontoPago(c.deuda); }} className="text-green-600 hover:text-green-800 text-xs">Registrar Pago</button>}
                  {c.estado === 'pendiente' && <button onClick={() => cambiarEstado(c.id, 'pagado')} className="text-blue-600 hover:text-blue-800 text-xs">Marcar Pagado</button>}
                </td>
              </tr>
            ))}
            {(!Array.isArray(clientes) || clientes.length === 0) && (
              <tr><td colSpan={6} className="p-8 text-center text-slate-400">No hay clientes</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {formOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md space-y-4">
            <h2 className="text-lg font-bold">Nuevo Cliente</h2>
            <input placeholder="Nombre" value={form.nombre} onChange={e => setForm({ ...form, nombre: e.target.value })} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <input placeholder="Teléfono" value={form.telefono} onChange={e => setForm({ ...form, telefono: e.target.value })} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <input placeholder="Email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <input placeholder="Dirección" value={form.direccion} onChange={e => setForm({ ...form, direccion: e.target.value })} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <input type="number" step="0.01" placeholder="Deuda inicial" value={form.deuda} onChange={e => setForm({ ...form, deuda: parseFloat(e.target.value) || 0 })} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <label className="text-sm text-slate-500">Fecha de vencimiento</label>
            <input type="date" value={form.fechaVencimiento} onChange={e => setForm({ ...form, fechaVencimiento: e.target.value })} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <div className="flex gap-3 justify-end">
              <button onClick={() => setFormOpen(false)} className="px-4 py-2 text-sm text-slate-600 hover:text-slate-800">Cancelar</button>
              <button onClick={guardar} className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">Guardar</button>
            </div>
          </div>
        </div>
      )}

      {pagoOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-sm space-y-4">
            <h2 className="text-lg font-bold">Registrar Pago</h2>
            <input type="number" step="0.01" placeholder="Monto" value={montoPago} onChange={e => setMontoPago(parseFloat(e.target.value) || 0)} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <input placeholder="Nota (opcional)" value={notaPago} onChange={e => setNotaPago(e.target.value)} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <div className="flex gap-3 justify-end">
              <button onClick={() => setPagoOpen(null)} className="px-4 py-2 text-sm text-slate-600 hover:text-slate-800">Cancelar</button>
              <button onClick={() => registrarPago(pagoOpen)} className="bg-green-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-green-700">Registrar Pago</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
