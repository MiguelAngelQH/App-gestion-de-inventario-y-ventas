'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Eye, X, CheckCircle2, Ban, Plus } from 'lucide-react';
import { Venta, formatearMoneda, formatearFechaHora, ESTADOS_VENTA } from '@/lib/types';
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

export default function VentasPage() {
  const [ventas, setVentas] = useState<Venta[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filterEstado, setFilterEstado] = useState('');
  const [selected, setSelected] = useState<Venta | null>(null);

  const load = async () => {
    try {
      setError('');
      const res = await fetch('/api/ventas');
      const data = await res.json();
      setVentas(Array.isArray(data) ? data : []);
      if (!res.ok) setError(data.error || 'Error al cargar ventas');
    } catch {
      setError('Error de conexion');
      setVentas([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const filtered = Array.isArray(ventas)
    ? (filterEstado ? ventas.filter(v => v.estado === filterEstado) : ventas)
    : [];

  const cambiarEstado = async (id: string, estado: string) => {
    await fetch(`/api/ventas?id=${id}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ estado }) });
    load();
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando ventas...</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-5">
      <motion.div variants={itemVariants} className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Ventas</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Historial de ventas registradas</p>
        </div>
        <div className="flex gap-2 flex-wrap">
          <Link href="/ventas/nueva" className="btn-primary">
            <Plus size={16} /> Nueva Venta
          </Link>
          {['', ...ESTADOS_VENTA].map(e => (
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
                <th className="text-left p-4">Cliente</th>
                <th className="text-left p-4">Pago</th>
                <th className="text-right p-4">Total</th>
                <th className="text-center p-4">Estado</th>
                <th className="text-center p-4">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(v => (
                <tr key={v.id} className="cursor-pointer" onClick={() => setSelected(v)}>
                  <td className="font-mono text-xs text-[var(--text-muted)]">V-{v.id.substring(0, 8).toUpperCase()}</td>
                  <td className="text-[var(--text-secondary)]">{formatearFechaHora(v.fecha)}</td>
                  <td className="text-[var(--text-primary)]">{v.clienteNombre || '—'}</td>
                  <td className="text-[var(--text-muted)]">{v.metodoPago}</td>
                  <td className="text-right font-semibold text-[var(--text-primary)]">{formatearMoneda(v.total)}</td>
                  <td className="text-center"><StatusBadge estado={v.estado} /></td>
                  <td className="text-center">
                    <div className="flex items-center justify-center gap-2" onClick={e => e.stopPropagation()}>
                      <button onClick={() => setSelected(v)} className="btn-secondary flex items-center gap-1 py-1.5 px-2.5 text-xs">
                        <Eye size={12} /> Ver
                      </button>
                      {v.estado === 'pendiente' && (
                        <button onClick={() => cambiarEstado(v.id, 'completada')} className="btn-success flex items-center gap-1">
                          <CheckCircle2 size={12} /> Completar
                        </button>
                      )}
                      {v.estado !== 'cancelada' && (
                        <button onClick={() => cambiarEstado(v.id, 'cancelada')} className="btn-danger flex items-center gap-1">
                          <Ban size={12} /> Cancelar
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr><td colSpan={7} className="p-12 text-center text-[var(--text-muted)]">No hay ventas</td></tr>
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
            className="card p-6 w-full max-w-lg space-y-4 mx-4"
          >
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-[var(--text-primary)]">Detalle de Venta</h2>
              <button onClick={() => setSelected(null)} className="text-[var(--text-muted)] hover:text-[var(--text-primary)] transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div className="bg-[var(--bg-tertiary)] rounded-xl px-4 py-3">
                <p className="text-xs text-[var(--text-muted)] mb-1">Folio</p>
                <p className="text-[var(--text-primary)] font-mono">V-{selected.id.substring(0, 8).toUpperCase()}</p>
              </div>
              <div className="bg-[var(--bg-tertiary)] rounded-xl px-4 py-3">
                <p className="text-xs text-[var(--text-muted)] mb-1">Fecha</p>
                <p className="text-[var(--text-primary)]">{formatearFechaHora(selected.fecha)}</p>
              </div>
              <div className="bg-[var(--bg-tertiary)] rounded-xl px-4 py-3">
                <p className="text-xs text-[var(--text-muted)] mb-1">Cliente</p>
                <p className="text-[var(--text-primary)]">{selected.clienteNombre || '—'}</p>
              </div>
              <div className="bg-[var(--bg-tertiary)] rounded-xl px-4 py-3">
                <p className="text-xs text-[var(--text-muted)] mb-1">Metodo de pago</p>
                <p className="text-[var(--text-primary)]">{selected.metodoPago}</p>
              </div>
              <div className="bg-[var(--bg-tertiary)] rounded-xl px-4 py-3">
                <p className="text-xs text-[var(--text-muted)] mb-1">Estado</p>
                <StatusBadge estado={selected.estado} />
              </div>
            </div>

            <div className="card overflow-hidden">
              <table className="w-full text-sm">
                <thead>
                  <tr><th className="text-left p-3">Producto</th><th className="text-right p-3">Cant.</th><th className="text-right p-3">P/U</th><th className="text-right p-3">Subtotal</th></tr>
                </thead>
                <tbody>
                  {selected.items.map((item, i) => (
                    <tr key={i}>
                      <td className="text-[var(--text-primary)]">{item.productoNombre}</td>
                      <td className="text-right text-[var(--text-secondary)]">{item.cantidad}</td>
                      <td className="text-right text-[var(--text-secondary)]">{formatearMoneda(item.precioUnitario)}</td>
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
          </motion.div>
        </motion.div>
      )}
    </motion.div>
  );
}
