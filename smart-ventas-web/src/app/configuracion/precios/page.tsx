'use client';

import { useEffect, useState, useCallback } from 'react';
import { motion } from 'framer-motion';
import { Save, X } from 'lucide-react';
import { Producto, formatearMoneda } from '@/lib/types';

interface FlatItem {
  productoId: string;
  productoNombre: string;
  presentacionId: string;
  presentacionNombre: string;
  precio: number;
  costo: number;
}

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.04, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 12 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.3 } },
};

export default function PreciosPage() {
  const [items, setItems] = useState<FlatItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [editPrecio, setEditPrecio] = useState<{ idx: number; val: string } | null>(null);
  const [editCosto, setEditCosto] = useState<{ idx: number; val: string } | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    try {
      const res = await fetch('/api/productos');
      const data: Producto[] = await res.json();
      const flat: FlatItem[] = [];
      for (const p of Array.isArray(data) ? data : []) {
        for (const pr of p.presentaciones || []) {
          flat.push({
            productoId: p.id,
            productoNombre: p.nombre,
            presentacionId: pr.id,
            presentacionNombre: pr.nombreVisual,
            precio: pr.precio,
            costo: pr.costo,
          });
        }
      }
      setItems(flat);
    } catch {
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const savePrecio = async (idx: number) => {
    if (!editPrecio || editPrecio.idx !== idx) return;
    const item = items[idx];
    const val = parseFloat(editPrecio.val);
    if (isNaN(val) || val < 0) return;
    setSaving(true);
    try {
      const res = await fetch(`/api/productos/precio`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ productoId: item.productoId, presentacionId: item.presentacionId, precio: val }),
      });
      if (res.ok) {
        const updated = [...items];
        updated[idx] = { ...updated[idx], precio: val };
        setItems(updated);
      }
    } finally {
      setEditPrecio(null);
      setSaving(false);
    }
  };

  const saveCosto = async (idx: number) => {
    if (!editCosto || editCosto.idx !== idx) return;
    const item = items[idx];
    const val = parseFloat(editCosto.val);
    if (isNaN(val) || val < 0) return;
    setSaving(true);
    try {
      const res = await fetch(`/api/productos/precio`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ productoId: item.productoId, presentacionId: item.presentacionId, costo: val }),
      });
      if (res.ok) {
        const updated = [...items];
        updated[idx] = { ...updated[idx], costo: val };
        setItems(updated);
      }
    } finally {
      setEditCosto(null);
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando precios...</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-5">
      <motion.div variants={itemVariants} className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Configuración de Precios</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            {items.length} presentación(es) — toca un valor para editarlo
          </p>
        </div>
      </motion.div>

      <motion.div variants={itemVariants} className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr>
                <th>Producto</th>
                <th>Presentación</th>
                <th className="text-right">Precio</th>
                <th className="text-right">Costo</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item, idx) => (
                <tr key={`${item.productoId}-${item.presentacionId}`}>
                  <td className="font-medium text-[var(--text-primary)]">{item.productoNombre}</td>
                  <td className="text-[var(--text-secondary)]">{item.presentacionNombre}</td>
                  <td className="text-right">
                    {editPrecio?.idx === idx ? (
                      <div className="flex items-center justify-end gap-1">
                        <span className="text-[var(--text-muted)] text-xs">S/</span>
                        <input
                          type="number"
                          step="0.01"
                          className="w-24 text-right text-sm px-2 py-1 rounded border border-blue-500"
                          value={editPrecio.val}
                          onChange={e => setEditPrecio({ idx, val: e.target.value })}
                          autoFocus
                          onKeyDown={e => {
                            if (e.key === 'Enter') savePrecio(idx);
                            if (e.key === 'Escape') setEditPrecio(null);
                          }}
                        />
                        <button onClick={() => savePrecio(idx)} className="text-green-600 hover:text-green-800" disabled={saving}>
                          <Save size={14} />
                        </button>
                        <button onClick={() => setEditPrecio(null)} className="text-red-500 hover:text-red-700">
                          <X size={14} />
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => setEditPrecio({ idx, val: item.precio.toFixed(2) })}
                        className="font-medium text-blue-600 dark:text-blue-400 hover:underline"
                      >
                        {formatearMoneda(item.precio)}
                      </button>
                    )}
                  </td>
                  <td className="text-right">
                    {editCosto?.idx === idx ? (
                      <div className="flex items-center justify-end gap-1">
                        <span className="text-[var(--text-muted)] text-xs">S/</span>
                        <input
                          type="number"
                          step="0.01"
                          className="w-24 text-right text-sm px-2 py-1 rounded border border-blue-500"
                          value={editCosto.val}
                          onChange={e => setEditCosto({ idx, val: e.target.value })}
                          autoFocus
                          onKeyDown={e => {
                            if (e.key === 'Enter') saveCosto(idx);
                            if (e.key === 'Escape') setEditCosto(null);
                          }}
                        />
                        <button onClick={() => saveCosto(idx)} className="text-green-600 hover:text-green-800" disabled={saving}>
                          <Save size={14} />
                        </button>
                        <button onClick={() => setEditCosto(null)} className="text-red-500 hover:text-red-700">
                          <X size={14} />
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => setEditCosto({ idx, val: item.costo.toFixed(2) })}
                        className="font-medium text-green-600 dark:text-green-400 hover:underline"
                      >
                        {formatearMoneda(item.costo)}
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {items.length === 0 && (
                <tr><td colSpan={4} className="p-12 text-center text-[var(--text-muted)]">No hay productos con presentaciones</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </motion.div>
    </motion.div>
  );
}
