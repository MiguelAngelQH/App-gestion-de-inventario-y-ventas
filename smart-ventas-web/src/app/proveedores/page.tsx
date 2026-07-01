'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Plus, X, DollarSign, CheckCircle2, Pencil, Trash2, User, Phone, Mail, MapPin, Calendar, CreditCard } from 'lucide-react';
import { Proveedor, formatearMoneda, formatearFecha } from '@/lib/types';
import StatusBadge from '@/components/StatusBadge';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

export default function ProveedoresPage() {
  const [proveedores, setProveedores] = useState<Proveedor[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [formOpen, setFormOpen] = useState(false);
  const [pagoOpen, setPagoOpen] = useState<string | null>(null);
  const [montoPago, setMontoPago] = useState(0);
  const [notaPago, setNotaPago] = useState('');
  const [form, setForm] = useState({ nombre: '', telefono: '', email: '', direccion: '', saldoPendiente: 0, estado: 'pendiente', fechaVencimiento: '' });
  const [editOpen, setEditOpen] = useState(false);
  const [editProveedor, setEditProveedor] = useState<any | null>(null);
  const [editForm, setEditForm] = useState({ nombre: '', telefono: '', email: '', direccion: '', saldoPendiente: 0, fechaVencimiento: '' });

  const load = async () => {
    try {
      setError('');
      const res = await fetch('/api/proveedores');
      const data = await res.json();
      setProveedores(Array.isArray(data) ? data : []);
      if (!res.ok) setError(data.error || 'Error al cargar proveedores');
    } catch {
      setError('Error de conexion');
      setProveedores([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const guardar = async () => {
    await fetch('/api/proveedores', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ...form, uid: 'web' }) });
    setFormOpen(false);
    setForm({ nombre: '', telefono: '', email: '', direccion: '', saldoPendiente: 0, estado: 'pendiente', fechaVencimiento: '' });
    load();
  };

  const registrarPago = async (id: string) => {
    await fetch(`/api/proveedores/pago`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ proveedorId: id, monto: montoPago, nota: notaPago }) });
    setPagoOpen(null);
    setMontoPago(0);
    setNotaPago('');
    load();
  };

  const cambiarEstado = async (id: string, estado: string) => {
    await fetch(`/api/proveedores?id=${id}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ estado }) });
    load();
  };

  const openEdit = (p: any) => {
    setEditProveedor(p);
    setEditForm({
      nombre: p.nombre,
      telefono: p.telefono,
      email: p.email,
      direccion: p.direccion,
      saldoPendiente: p.saldoPendiente,
      fechaVencimiento: p.fechaVencimiento || '',
    });
    setEditOpen(true);
  };

  const guardarEdit = async () => {
    if (!editProveedor) return;
    await fetch(`/api/proveedores?id=${editProveedor.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nombre: editForm.nombre,
        telefono: editForm.telefono,
        email: editForm.email,
        direccion: editForm.direccion,
        saldoPendiente: editForm.saldoPendiente,
        estado: editProveedor.estado,
        fechaVencimiento: editForm.fechaVencimiento || null,
      }),
    });
    setEditOpen(false);
    setEditProveedor(null);
    load();
  };

  const eliminarProveedor = async (id: string, nombre: string) => {
    if (!confirm(`¿Eliminar a "${nombre}"?\nEsta acción no se puede deshacer.`)) return;
    await fetch(`/api/proveedores?id=${id}`, { method: 'DELETE' });
    load();
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-teal-600/30 border-t-teal-600 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando proveedores...</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-5">
      <motion.div variants={itemVariants} className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Proveedores</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Cuentas por pagar</p>
        </div>
        <button onClick={() => setFormOpen(true)} className="btn-primary flex items-center gap-2">
          <Plus size={16} /> Nuevo Proveedor
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
                <th className="text-right p-4">Saldo Pendiente</th>
                <th className="text-center p-4">Vencimiento</th>
                <th className="text-center p-4">Estado</th>
                <th className="text-center p-4">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {Array.isArray(proveedores) && proveedores.map(p => (
                <tr key={p.id}>
                  <td className="font-medium text-[var(--text-primary)]">{p.nombre}</td>
                  <td className="text-[var(--text-muted)]">{p.telefono || '—'}</td>
                  <td className="text-right font-semibold text-[var(--danger)]">{formatearMoneda(p.saldoPendiente)}</td>
                  <td className="text-center text-[var(--text-muted)]">{p.fechaVencimiento ? formatearFecha(p.fechaVencimiento) : '—'}</td>
                  <td className="text-center"><StatusBadge estado={p.estado} /></td>
                  <td className="text-center">
                    <div className="flex items-center justify-center gap-2">
                      {p.saldoPendiente > 0 && (
                        <button onClick={() => { setPagoOpen(p.id); setMontoPago(p.saldoPendiente); }} className="btn-success flex items-center gap-1">
                          <DollarSign size={12} /> Pagar
                        </button>
                      )}
                      {p.estado === 'pendiente' && (
                        <button onClick={() => cambiarEstado(p.id, 'pagado')} className="btn-secondary flex items-center gap-1 py-1.5 px-2.5 text-xs">
                          <CheckCircle2 size={12} /> Pagado
                        </button>
                      )}
                      <button onClick={() => openEdit(p)} className="btn-success"><Pencil size={12} /> Editar</button>
                      <button onClick={() => eliminarProveedor(p.id, p.nombre)} className="btn-danger"><Trash2 size={12} /> Eliminar</button>
                    </div>
                  </td>
                </tr>
              ))}
              {(!Array.isArray(proveedores) || proveedores.length === 0) && (
                <tr><td colSpan={6} className="p-12 text-center text-[var(--text-muted)]">No hay proveedores</td></tr>
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
            className="card overflow-hidden w-full max-w-md mx-4"
          >
            <div className="bg-gradient-to-r from-purple-600 to-violet-600 px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                  <User size={20} className="text-white" />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-white">Nuevo Proveedor</h2>
                  <p className="text-xs text-purple-200">Registra un nuevo proveedor</p>
                </div>
              </div>
              <button onClick={() => setFormOpen(false)} className="text-white/80 hover:text-white transition-colors"><X size={20} /></button>
            </div>
            <div className="p-6 space-y-4">
              <div className="relative">
                <User size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input placeholder="Nombre del proveedor" value={form.nombre} onChange={e => setForm({ ...form, nombre: e.target.value })} className="w-full pl-10" />
              </div>
              <div className="relative">
                <Phone size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input placeholder="Teléfono" value={form.telefono} onChange={e => setForm({ ...form, telefono: e.target.value })} className="w-full pl-10" />
              </div>
              <div className="relative">
                <Mail size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input placeholder="Email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} className="w-full pl-10" />
              </div>
              <div className="relative">
                <MapPin size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input placeholder="Dirección" value={form.direccion} onChange={e => setForm({ ...form, direccion: e.target.value })} className="w-full pl-10" />
              </div>
              <div className="relative">
                <CreditCard size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input type="number" step="0.01" placeholder="Saldo pendiente" value={form.saldoPendiente} onChange={e => setForm({ ...form, saldoPendiente: parseFloat(e.target.value) || 0 })} className="w-full pl-10" />
              </div>
              <div>
                <label className="text-xs text-[var(--text-muted)] mb-1.5 block font-medium">Fecha de vencimiento</label>
                <div className="relative">
                  <Calendar size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                  <input type="date" value={form.fechaVencimiento} onChange={e => setForm({ ...form, fechaVencimiento: e.target.value })} className="w-full pl-10" />
                </div>
              </div>
              <div className="flex gap-3 justify-end pt-2">
                <button onClick={() => setFormOpen(false)} className="btn-secondary">Cancelar</button>
                <button onClick={guardar} className="btn-primary">Guardar Proveedor</button>
              </div>
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
            className="card overflow-hidden w-full max-w-sm mx-4"
          >
            <div className="bg-gradient-to-r from-orange-600 to-red-600 px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                  <DollarSign size={20} className="text-white" />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-white">Pagar a Proveedor</h2>
                  <p className="text-xs text-orange-200">Registra un pago realizado</p>
                </div>
              </div>
              <button onClick={() => setPagoOpen(null)} className="text-white/80 hover:text-white transition-colors"><X size={20} /></button>
            </div>
            <div className="p-6 space-y-4">
              <div className="relative">
                <DollarSign size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input type="number" step="0.01" placeholder="Monto del pago" value={montoPago} onChange={e => setMontoPago(parseFloat(e.target.value) || 0)} className="w-full pl-10" />
              </div>
              <div className="relative">
                <CreditCard size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input placeholder="Nota (opcional)" value={notaPago} onChange={e => setNotaPago(e.target.value)} className="w-full pl-10" />
              </div>
              <div className="flex gap-3 justify-end pt-2">
                <button onClick={() => setPagoOpen(null)} className="btn-secondary">Cancelar</button>
                <button onClick={() => registrarPago(pagoOpen)} className="btn-primary">
                  <DollarSign size={16} /> Registrar Pago
                </button>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}

      {editOpen && editProveedor && (
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
            className="card overflow-hidden w-full max-w-md mx-4"
          >
            <div className="bg-gradient-to-r from-amber-600 to-orange-600 px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                  <Pencil size={20} className="text-white" />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-white">Editar Proveedor</h2>
                  <p className="text-xs text-amber-200">Modifica los datos del proveedor</p>
                </div>
              </div>
              <button onClick={() => setEditOpen(false)} className="text-white/80 hover:text-white transition-colors"><X size={20} /></button>
            </div>
            <div className="p-6 space-y-4">
              <div className="relative">
                <User size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input placeholder="Nombre" value={editForm.nombre} onChange={e => setEditForm({ ...editForm, nombre: e.target.value })} className="w-full pl-10" />
              </div>
              <div className="relative">
                <Phone size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input placeholder="Teléfono" value={editForm.telefono} onChange={e => setEditForm({ ...editForm, telefono: e.target.value })} className="w-full pl-10" />
              </div>
              <div className="relative">
                <Mail size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input placeholder="Email" value={editForm.email} onChange={e => setEditForm({ ...editForm, email: e.target.value })} className="w-full pl-10" />
              </div>
              <div className="relative">
                <MapPin size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input placeholder="Dirección" value={editForm.direccion} onChange={e => setEditForm({ ...editForm, direccion: e.target.value })} className="w-full pl-10" />
              </div>
              <div className="relative">
                <CreditCard size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                <input type="number" step="0.01" placeholder="Saldo pendiente" value={editForm.saldoPendiente} onChange={e => setEditForm({ ...editForm, saldoPendiente: parseFloat(e.target.value) || 0 })} className="w-full pl-10" />
              </div>
              <div>
                <label className="text-xs text-[var(--text-muted)] mb-1.5 block font-medium">Fecha de vencimiento</label>
                <div className="relative">
                  <Calendar size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
                  <input type="date" value={editForm.fechaVencimiento} onChange={e => setEditForm({ ...editForm, fechaVencimiento: e.target.value })} className="w-full pl-10" />
                </div>
              </div>
              <div className="flex gap-3 justify-end pt-2">
                <button onClick={() => setEditOpen(false)} className="btn-secondary">Cancelar</button>
                <button onClick={guardarEdit} className="btn-primary">Guardar Cambios</button>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </motion.div>
  );
}
