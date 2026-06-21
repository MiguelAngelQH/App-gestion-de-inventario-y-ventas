'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Plus, X, DollarSign, CheckCircle2, Pencil, Trash2 } from 'lucide-react';
import { Cliente, formatearMoneda, formatearFecha } from '@/lib/types';
import StatusBadge from '@/components/StatusBadge';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

export default function ClientesPage() {
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [formOpen, setFormOpen] = useState(false);
  const [pagoOpen, setPagoOpen] = useState<string | null>(null);
  const [montoPago, setMontoPago] = useState(0);
  const [notaPago, setNotaPago] = useState('');
  const [form, setForm] = useState({ nombre: '', telefono: '', email: '', direccion: '', deuda: 0, estado: 'pendiente', fechaVencimiento: '' });
  const [editOpen, setEditOpen] = useState(false);
  const [editCliente, setEditCliente] = useState<Cliente | null>(null);
  const [editForm, setEditForm] = useState({ nombre: '', telefono: '', email: '', direccion: '', deuda: 0, fechaVencimiento: '' });

  const load = async () => {
    try {
      setError('');
      const res = await fetch('/api/clientes');
      const data = await res.json();
      setClientes(Array.isArray(data) ? data : []);
      if (!res.ok) setError(data.error || 'Error al cargar clientes');
    } catch {
      setError('Error de conexion');
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

  const openEdit = (c: Cliente) => {
    setEditCliente(c);
    setEditForm({
      nombre: c.nombre,
      telefono: c.telefono,
      email: c.email,
      direccion: c.direccion,
      deuda: c.deuda,
      fechaVencimiento: c.fechaVencimiento || '',
    });
    setEditOpen(true);
  };

  const guardarEdit = async () => {
    if (!editCliente) return;
    await fetch(`/api/clientes?id=${editCliente.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nombre: editForm.nombre,
        telefono: editForm.telefono,
        email: editForm.email,
        direccion: editForm.direccion,
        deuda: editForm.deuda,
        estado: editCliente.estado,
        fechaVencimiento: editForm.fechaVencimiento || null,
      }),
    });
    setEditOpen(false);
    setEditCliente(null);
    load();
  };

  const eliminarCliente = async (id: string, nombre: string) => {
    if (!confirm(`¿Eliminar a "${nombre}"?\nEsta acción no se puede deshacer.`)) return;
    await fetch(`/api/clientes?id=${id}`, { method: 'DELETE' });
    load();
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando clientes...</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-5">
      <motion.div variants={itemVariants} className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Clientes</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Cuentas por cobrar</p>
        </div>
        <button onClick={() => setFormOpen(true)} className="btn-primary flex items-center gap-2">
          <Plus size={16} /> Nuevo Cliente
        </button>
      </motion.div>

      {error && (
        <motion.div variants={itemVariants} className="bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-600 dark:text-red-400 p-3 rounded-xl text-sm">
          {error}
        </motion.div>
      )}

      <motion.div variants={itemVariants} className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr>
                <th className="text-left p-4">Nombre</th>
                <th className="text-left p-4">Telefono</th>
                <th className="text-right p-4">Deuda</th>
                <th className="text-center p-4">Vencimiento</th>
                <th className="text-center p-4">Estado</th>
                <th className="text-center p-4">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {Array.isArray(clientes) && clientes.map(c => (
                <tr key={c.id}>
                  <td className="font-medium text-[var(--text-primary)]">{c.nombre}</td>
                  <td className="text-[var(--text-muted)]">{c.telefono || '—'}</td>
                  <td className="text-right font-semibold text-[var(--danger)]">{formatearMoneda(c.deuda)}</td>
                  <td className="text-center text-[var(--text-muted)]">{c.fechaVencimiento ? formatearFecha(c.fechaVencimiento) : '—'}</td>
                  <td className="text-center"><StatusBadge estado={c.estado} /></td>
                  <td className="text-center">
                    <div className="flex items-center justify-center gap-2">
                      {c.deuda > 0 && (
                        <button onClick={() => { setPagoOpen(c.id); setMontoPago(c.deuda); }} className="btn-success flex items-center gap-1">
                          <DollarSign size={12} /> Registrar Pago
                        </button>
                      )}
                      {c.estado === 'pendiente' && (
                        <button onClick={() => cambiarEstado(c.id, 'pagado')} className="btn-secondary flex items-center gap-1 py-1.5 px-2.5 text-xs">
                          <CheckCircle2 size={12} /> Pagado
                        </button>
                      )}
                      <button onClick={() => openEdit(c)} className="btn-success"><Pencil size={12} /> Editar</button>
                      <button onClick={() => eliminarCliente(c.id, c.nombre)} className="btn-danger"><Trash2 size={12} /> Eliminar</button>
                    </div>
                  </td>
                </tr>
              ))}
              {(!Array.isArray(clientes) || clientes.length === 0) && (
                <tr><td colSpan={6} className="p-12 text-center text-[var(--text-muted)]">No hay clientes</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </motion.div>

      {formOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="fixed inset-0 bg-black/30 dark:bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
          onClick={() => setFormOpen(false)}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            onClick={e => e.stopPropagation()}
            className="card p-6 w-full max-w-md space-y-4 mx-4"
          >
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-[var(--text-primary)]">Nuevo Cliente</h2>
              <button onClick={() => setFormOpen(false)} className="text-[var(--text-muted)] hover:text-[var(--text-primary)] transition-colors"><X size={20} /></button>
            </div>
            <input placeholder="Nombre" value={form.nombre} onChange={e => setForm({ ...form, nombre: e.target.value })} className="w-full" />
            <input placeholder="Telefono" value={form.telefono} onChange={e => setForm({ ...form, telefono: e.target.value })} className="w-full" />
            <input placeholder="Email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} className="w-full" />
            <input placeholder="Direccion" value={form.direccion} onChange={e => setForm({ ...form, direccion: e.target.value })} className="w-full" />
            <input type="number" step="0.01" placeholder="Deuda inicial" value={form.deuda} onChange={e => setForm({ ...form, deuda: parseFloat(e.target.value) || 0 })} className="w-full" />
            <label className="text-sm text-[var(--text-muted)]">Fecha de vencimiento</label>
            <input type="date" value={form.fechaVencimiento} onChange={e => setForm({ ...form, fechaVencimiento: e.target.value })} className="w-full" />
            <div className="flex gap-3 justify-end pt-2">
              <button onClick={() => setFormOpen(false)} className="btn-secondary">Cancelar</button>
              <button onClick={guardar} className="btn-primary">Guardar</button>
            </div>
          </motion.div>
        </motion.div>
      )}

      {pagoOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="fixed inset-0 bg-black/30 dark:bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
          onClick={() => setPagoOpen(null)}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            onClick={e => e.stopPropagation()}
            className="card p-6 w-full max-w-sm space-y-4 mx-4"
          >
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-[var(--text-primary)]">Registrar Pago</h2>
              <button onClick={() => setPagoOpen(null)} className="text-[var(--text-muted)] hover:text-[var(--text-primary)] transition-colors"><X size={20} /></button>
            </div>
            <input type="number" step="0.01" placeholder="Monto" value={montoPago} onChange={e => setMontoPago(parseFloat(e.target.value) || 0)} className="w-full" />
            <input placeholder="Nota (opcional)" value={notaPago} onChange={e => setNotaPago(e.target.value)} className="w-full" />
            <div className="flex gap-3 justify-end pt-2">
              <button onClick={() => setPagoOpen(null)} className="btn-secondary">Cancelar</button>
              <button onClick={() => registrarPago(pagoOpen)} className="btn-primary flex items-center gap-2">
                <DollarSign size={16} /> Registrar Pago
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}

      {editOpen && editCliente && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="fixed inset-0 bg-black/30 dark:bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
          onClick={() => setEditOpen(false)}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            onClick={e => e.stopPropagation()}
            className="card p-6 w-full max-w-md space-y-4 mx-4"
          >
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-[var(--text-primary)]">Editar Cliente</h2>
              <button onClick={() => setEditOpen(false)} className="text-[var(--text-muted)] hover:text-[var(--text-primary)] transition-colors"><X size={20} /></button>
            </div>
            <input placeholder="Nombre" value={editForm.nombre} onChange={e => setEditForm({ ...editForm, nombre: e.target.value })} className="w-full" />
            <input placeholder="Telefono" value={editForm.telefono} onChange={e => setEditForm({ ...editForm, telefono: e.target.value })} className="w-full" />
            <input placeholder="Email" value={editForm.email} onChange={e => setEditForm({ ...editForm, email: e.target.value })} className="w-full" />
            <input placeholder="Direccion" value={editForm.direccion} onChange={e => setEditForm({ ...editForm, direccion: e.target.value })} className="w-full" />
            <input type="number" step="0.01" placeholder="Deuda" value={editForm.deuda} onChange={e => setEditForm({ ...editForm, deuda: parseFloat(e.target.value) || 0 })} className="w-full" />
            <label className="text-sm text-[var(--text-muted)]">Fecha de vencimiento</label>
            <input type="date" value={editForm.fechaVencimiento} onChange={e => setEditForm({ ...editForm, fechaVencimiento: e.target.value })} className="w-full" />
            <div className="flex gap-3 justify-end pt-2">
              <button onClick={() => setEditOpen(false)} className="btn-secondary">Cancelar</button>
              <button onClick={guardarEdit} className="btn-primary">Guardar</button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </motion.div>
  );
}
