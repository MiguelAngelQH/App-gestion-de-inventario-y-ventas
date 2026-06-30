'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Eye, X, CheckCircle2, Ban, Plus } from 'lucide-react';
import { Compra, formatearMoneda, formatearFechaHora, ESTADOS_COMPRA } from '@/lib/types';
import StatusBadge from '@/components/StatusBadge';
import Link from 'next/link';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

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
      setError('Error de conexion');
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

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando compras...</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-5">
      <motion.div variants={itemVariants} className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Compras</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Historial de compras a proveedores</p>
        </div>
        <div className="flex gap-2 flex-wrap">
          <Link href="/compras/nueva" className="btn-primary">
            <Plus size={16} /> Nueva Compra
          </Link>
          {['', ...ESTADOS_COMPRA].map(e => (
            <button
              key={e}
              onClick={() => setFilterEstado(e)}
              className={`px-3 py-1.5 rounded-xl text-xs font-medium transition-all ${
                filterEstado === e
                  ? 'card text-[var(--accent)] border-[var(--accent)]/30'
                  : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--bg-tertiary)]'
              }`}
            >
              {e || 'Todos'}
            </button>
          ))}
        </div>
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
                <th className="text-left p-4">Folio</th>
                <th className="text-left p-4">Fecha</th>
                <th className="text-left p-4">Proveedor</th>
                <th className="text-right p-4">Total</th>
                <th className="text-center p-4">Estado</th>
                <th className="text-center p-4">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(c => (
                <tr key={c.id} className="cursor-pointer" onClick={() => setSelected(c)}>
                  <td className="font-mono text-xs text-[var(--text-muted)]">C-{c.id.substring(0, 8).toUpperCase()}</td>
                  <td className="text-[var(--text-secondary)]">{formatearFechaHora(c.fecha)}</td>
                  <td className="text-[var(--text-primary)]">{c.proveedorNombre}</td>
                  <td className="text-right font-semibold text-[var(--text-primary)]">{formatearMoneda(c.total)}</td>
                  <td className="text-center"><StatusBadge estado={c.estado} /></td>
                  <td className="text-center">
                    <div className="flex items-center justify-center gap-2" onClick={e => e.stopPropagation()}>
                      <button onClick={() => setSelected(c)} className="btn-secondary flex items-center gap-1 py-1.5 px-2.5 text-xs">
                        <Eye size={12} /> Ver
                      </button>
                      {c.estado === 'pendiente' && (
                        <button onClick={() => cambiarEstado(c.id, 'recibida')} className="btn-success flex items-center gap-1">
                          <CheckCircle2 size={12} /> Recibir
                        </button>
                      )}
                      {c.estado !== 'cancelada' && (
                        <button onClick={() => cambiarEstado(c.id, 'cancelada')} className="btn-danger flex items-center gap-1">
                          <Ban size={12} /> Cancelar
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr><td colSpan={6} className="p-12 text-center text-[var(--text-muted)]">No hay compras</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </motion.div>

      {selected && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="fixed inset-0 bg-black/30 dark:bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
          onClick={() => setSelected(null)}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            onClick={e => e.stopPropagation()}
            className="card overflow-hidden w-full max-w-lg mx-4"
          >
            <div className="bg-gradient-to-r from-blue-600 to-indigo-600 px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                  <Eye size={20} className="text-white" />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-white">Detalle de Compra</h2>
                  <p className="text-xs text-blue-200">C-{selected.id.substring(0, 8).toUpperCase()}</p>
                </div>
              </div>
              <button onClick={() => setSelected(null)} className="text-white/80 hover:text-white transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="bg-[var(--bg-tertiary)] rounded-xl px-4 py-3">
                  <p className="text-xs text-[var(--text-muted)] mb-1">Folio</p>
                  <p className="text-[var(--text-primary)] font-mono">C-{selected.id.substring(0, 8).toUpperCase()}</p>
                </div>
                <div className="bg-[var(--bg-tertiary)] rounded-xl px-4 py-3">
                  <p className="text-xs text-[var(--text-muted)] mb-1">Fecha</p>
                  <p className="text-[var(--text-primary)]">{formatearFechaHora(selected.fecha)}</p>
                </div>
                <div className="bg-[var(--bg-tertiary)] rounded-xl px-4 py-3">
                  <p className="text-xs text-[var(--text-muted)] mb-1">Proveedor</p>
                  <p className="text-[var(--text-primary)]">{selected.proveedorNombre}</p>
                </div>
                <div className="bg-[var(--bg-tertiary)] rounded-xl px-4 py-3">
                  <p className="text-xs text-[var(--text-muted)] mb-1">Estado</p>
                  <StatusBadge estado={selected.estado} />
                </div>
              </div>

              <div className="card overflow-hidden">
                <table className="w-full text-sm">
                  <thead>
                    <tr><th className="text-left p-3">Producto</th><th className="text-right p-3">Cant.</th><th className="text-right p-3">Costo U.</th><th className="text-right p-3">Subtotal</th></tr>
                  </thead>
                  <tbody>
                    {selected.items.map((item, i) => (
                      <tr key={i}>
                        <td className="text-[var(--text-primary)]">{item.productoNombre}</td>
                        <td className="text-right text-[var(--text-secondary)]">{item.cantidad}</td>
                        <td className="text-right text-[var(--text-secondary)]">{formatearMoneda(item.costoUnitario)}</td>
                        <td className="text-right text-[var(--text-primary)] font-medium">{formatearMoneda(item.subtotal)}</td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr className="border-t border-[var(--border)]">
                      <td colSpan={3} className="p-3 text-right text-[var(--text-secondary)] font-medium">Total</td>
                      <td className="p-3 text-right text-[var(--accent)] font-bold">{formatearMoneda(selected.total)}</td>
                    </tr>
                  </tfoot>
                </table>
              </div>

              <button onClick={() => setSelected(null)} className="w-full py-2.5 text-sm text-[var(--text-muted)] hover:text-[var(--text-primary)] transition-colors bg-[var(--bg-tertiary)] rounded-xl">
                Cerrar
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </motion.div>
  );
}
