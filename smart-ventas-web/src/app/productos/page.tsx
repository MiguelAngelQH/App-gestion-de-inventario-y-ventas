'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Search, SlidersHorizontal, Plus, Package, Pencil, Trash2, X } from 'lucide-react';
import { Producto, Presentacion, formatearMoneda, CATEGORIAS, UNIDADES_MEDIDA } from '@/lib/types';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

interface FormPres {
  id: string;
  nombreVisual: string;
  unidad: string;
  precio: number;
  costo: number;
  factor: number;
}

let presCounter = 0;
function newPres(): FormPres {
  return { id: `new_${++presCounter}`, nombreVisual: '', unidad: 'kg', precio: 0, costo: 0, factor: 1 };
}

export default function ProductosPage() {
  const [productos, setProductos] = useState<Producto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [filterCat, setFilterCat] = useState('');
  const [showLowStock, setShowLowStock] = useState(false);
  const [formOpen, setFormOpen] = useState(false);
  const [editando, setEditando] = useState<Producto | null>(null);
  const [form, setForm] = useState({
    nombre: '', descripcion: '', codigoBarras: '', categoria: 'General',
    unidadBase: 'kg', stockTotal: 0, presentaciones: [] as FormPres[],
  });

  const load = async () => {
    try {
      setError('');
      const res = await fetch('/api/productos');
      const data = await res.json();
      setProductos(Array.isArray(data) ? data : []);
      if (!res.ok) setError(data.error || 'Error al cargar productos');
    } catch {
      setError('Error de conexion al cargar productos');
      setProductos([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const filtered = Array.isArray(productos)
    ? productos.filter(p => {
        if (search && !p.nombre.toLowerCase().includes(search.toLowerCase()) && !p.codigoBarras.toLowerCase().includes(search.toLowerCase())) return false;
        if (filterCat && p.categoria !== filterCat) return false;
        if (showLowStock && p.stockTotal > 5) return false;
        return true;
      })
    : [];

  const addPres = () => setForm({ ...form, presentaciones: [...form.presentaciones, newPres()] });
  const removePres = (idx: number) => {
    const updated = form.presentaciones.filter((_, i) => i !== idx);
    setForm({ ...form, presentaciones: updated });
  };
  const updatePres = (idx: number, field: keyof FormPres, value: string | number) => {
    const updated = [...form.presentaciones];
    (updated[idx] as any)[field] = value;
    if (field === 'unidad' && value === form.unidadBase) {
      updated[idx].factor = 1;
    }
    setForm({ ...form, presentaciones: updated });
  };

  const guardar = async () => {
    const presentaciones = form.presentaciones.map(p => ({
      id: p.id.startsWith('new_') ? crypto.randomUUID() : p.id,
      nombreVisual: p.nombreVisual,
      unidad: p.unidad,
      precio: p.precio,
      costo: p.costo,
      factor: p.factor,
    }));
    const body = editando
      ? { ...form, presentaciones, id: editando.id }
      : { ...form, presentaciones };
    const url = editando ? `/api/productos?id=${editando.id}` : '/api/productos';
    const method = editando ? 'PUT' : 'POST';
    await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    setFormOpen(false);
    setEditando(null);
    setForm({ nombre: '', descripcion: '', codigoBarras: '', categoria: 'General', unidadBase: 'kg', stockTotal: 0, presentaciones: [] });
    load();
  };

  const eliminar = async (id: string) => {
    if (!confirm('¿Eliminar producto?')) return;
    await fetch(`/api/productos?id=${id}`, { method: 'DELETE' });
    load();
  };

  const openEdit = (p: Producto) => {
    setEditando(p);
    setForm({
      nombre: p.nombre,
      descripcion: p.descripcion,
      codigoBarras: p.codigoBarras,
      categoria: p.categoria,
      unidadBase: p.unidadBase,
      stockTotal: p.stockTotal,
      presentaciones: (p.presentaciones || []).map(pr => ({
        id: pr.id,
        nombreVisual: pr.nombreVisual,
        unidad: pr.unidad,
        precio: pr.precio,
        costo: pr.costo,
        factor: pr.factor,
      })),
    });
    setFormOpen(true);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando productos...</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-5">
      <motion.div variants={itemVariants} className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Productos</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Gestiona tu inventario de productos</p>
        </div>
        <button onClick={() => { setEditando(null); setForm({ nombre: '', descripcion: '', codigoBarras: '', categoria: 'General', unidadBase: 'kg', stockTotal: 0, presentaciones: [newPres()] }); setFormOpen(true); }} className="btn-primary">
          <Plus size={16} /> Nuevo Producto
        </button>
      </motion.div>

      {error && (
        <motion.div variants={itemVariants} className="bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-600 dark:text-red-400 p-3 rounded-xl text-sm">{error}</motion.div>
      )}

      <motion.div variants={itemVariants} className="flex flex-wrap gap-3 items-center">
        <div className="relative flex-1 min-w-[200px]">
          <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
          <input type="text" placeholder="Buscar por nombre o codigo..." value={search} onChange={e => setSearch(e.target.value)} className="w-full pl-10 pr-4 py-2.5" />
        </div>
        <div className="relative">
          <SlidersHorizontal size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)] pointer-events-none" />
          <select value={filterCat} onChange={e => setFilterCat(e.target.value)} className="pl-10 pr-4 py-2.5 min-w-[160px] appearance-none cursor-pointer">
            <option value="">Todas las categorias</option>
            {CATEGORIAS.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
        <label className="flex items-center gap-2 text-sm text-[var(--text-secondary)] cursor-pointer select-none px-3 py-2.5 card">
          <input type="checkbox" checked={showLowStock} onChange={e => setShowLowStock(e.target.checked)} className="w-4 h-4 rounded accent-blue-600" />
          Stock bajo
        </label>
      </motion.div>

      <motion.div variants={itemVariants} className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr><th>Producto</th><th>Categoria</th><th>Presentaciones</th><th className="text-right">Stock</th><th className="text-center">Codigo</th><th className="text-center">Acciones</th></tr>
            </thead>
            <tbody>
              {filtered.map(p => (
                <tr key={p.id}>
                  <td>
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-xl bg-blue-50 dark:bg-blue-500/10 border border-blue-100 dark:border-blue-500/20 flex items-center justify-center">
                        <Package size={16} className="text-blue-600 dark:text-blue-400" />
                      </div>
                      <span className="font-medium text-[var(--text-primary)]">{p.nombre}</span>
                    </div>
                  </td>
                  <td className="text-[var(--text-secondary)]">{p.categoria}</td>
                  <td>
                    <div className="flex flex-wrap gap-1">
                      {(p.presentaciones || []).map(pr => (
                        <span key={pr.id} className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-blue-50 dark:bg-blue-500/10 text-xs font-medium text-blue-700 dark:text-blue-300">
                          {formatearMoneda(pr.precio)}/{pr.unidad}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className={`text-right font-medium ${p.stockTotal <= 5 ? 'text-red-600 dark:text-red-400' : 'text-[var(--text-primary)]'}`}>
                    {p.stockTotal} {p.unidadBase}
                  </td>
                  <td className="text-center text-[var(--text-muted)] text-xs">{p.codigoBarras || '—'}</td>
                  <td>
                    <div className="flex items-center justify-center gap-2">
                      <button onClick={() => openEdit(p)} className="btn-success"><Pencil size={12} /> Editar</button>
                      <button onClick={() => eliminar(p.id)} className="btn-danger"><Trash2 size={12} /> Eliminar</button>
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr><td colSpan={6} className="p-12 text-center text-[var(--text-muted)]">No hay productos</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </motion.div>

      {formOpen && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="fixed inset-0 bg-black/30 dark:bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 overflow-y-auto py-8" onClick={() => setFormOpen(false)}>
          <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} onClick={e => e.stopPropagation()} className="card p-6 w-full max-w-lg space-y-4 mx-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-[var(--text-primary)]">{editando ? 'Editar' : 'Nuevo'} Producto</h2>
              <button onClick={() => setFormOpen(false)} className="text-[var(--text-muted)] hover:text-[var(--text-primary)] transition-colors"><X size={20} /></button>
            </div>
            <input placeholder="Nombre" value={form.nombre} onChange={e => setForm({ ...form, nombre: e.target.value })} className="w-full" />
            <input placeholder="Descripcion" value={form.descripcion} onChange={e => setForm({ ...form, descripcion: e.target.value })} className="w-full" />
            <div className="grid grid-cols-2 gap-3">
              <select value={form.unidadBase} onChange={e => setForm({ ...form, unidadBase: e.target.value })} className="w-full">
                {UNIDADES_MEDIDA.map(u => <option key={u} value={u}>{u}</option>)}
              </select>
              <input type="number" step="0.01" placeholder="Stock Total" value={form.stockTotal} onChange={e => setForm({ ...form, stockTotal: parseFloat(e.target.value) || 0 })} />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <select value={form.categoria} onChange={e => setForm({ ...form, categoria: e.target.value })} className="w-full">
                {CATEGORIAS.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
              <input placeholder="Codigo de barras" value={form.codigoBarras} onChange={e => setForm({ ...form, codigoBarras: e.target.value })} />
            </div>

            <div className="border-t border-[var(--border)] pt-4">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-semibold text-[var(--text-primary)]">Presentaciones</h3>
                <button onClick={addPres} className="btn-secondary text-xs py-1 px-3">+ Agregar</button>
              </div>
              {form.presentaciones.length === 0 && (
                <p className="text-xs text-[var(--text-muted)] text-center py-4">Agrega al menos una presentacion</p>
              )}
              {form.presentaciones.map((pres, idx) => (
                <div key={idx} className="border border-[var(--border)] rounded-lg p-3 mb-3 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-[var(--text-secondary)]">Presentacion {idx + 1}</span>
                    <button onClick={() => removePres(idx)} className="text-red-500 hover:text-red-700"><X size={14} /></button>
                  </div>
                  <input placeholder="Nombre visual (ej: Por Kilo)" value={pres.nombreVisual} onChange={e => updatePres(idx, 'nombreVisual', e.target.value)} className="w-full text-sm" />
                  <div className="grid grid-cols-3 gap-2">
                    <select value={pres.unidad} onChange={e => updatePres(idx, 'unidad', e.target.value)} className="w-full text-sm">
                      {UNIDADES_MEDIDA.map(u => <option key={u} value={u}>{u}</option>)}
                    </select>
                    <input type="number" step="0.01" placeholder="Factor" value={pres.factor} onChange={e => updatePres(idx, 'factor', parseFloat(e.target.value) || 1)} className="w-full text-sm" />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <input type="number" step="0.01" placeholder="Precio" value={pres.precio} onChange={e => updatePres(idx, 'precio', parseFloat(e.target.value) || 0)} className="w-full text-sm" />
                    <input type="number" step="0.01" placeholder="Costo" value={pres.costo} onChange={e => updatePres(idx, 'costo', parseFloat(e.target.value) || 0)} className="w-full text-sm" />
                  </div>
                </div>
              ))}
            </div>

            <div className="flex gap-3 justify-end pt-2">
              <button onClick={() => setFormOpen(false)} className="btn-secondary">Cancelar</button>
              <button onClick={guardar} className="btn-primary">Guardar</button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </motion.div>
  );
}
