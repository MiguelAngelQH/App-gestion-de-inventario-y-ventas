'use client';

import { useEffect, useState } from 'react';
import { Producto, formatearMoneda, CATEGORIAS } from '@/lib/types';
import StatusBadge from '@/components/StatusBadge';

export default function ProductosPage() {
  const [productos, setProductos] = useState<Producto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [filterCat, setFilterCat] = useState('');
  const [showLowStock, setShowLowStock] = useState(false);
  const [formOpen, setFormOpen] = useState(false);
  const [editando, setEditando] = useState<Producto | null>(null);
  const [form, setForm] = useState({ nombre: '', descripcion: '', precio: 0, costo: 0, stock: 0, codigoBarras: '', categoria: 'General' });

  const load = async () => {
    try {
      setError('');
      const res = await fetch('/api/productos');
      const data = await res.json();
      setProductos(Array.isArray(data) ? data : []);
      if (!res.ok) setError(data.error || 'Error al cargar productos');
    } catch {
      setError('Error de conexión al cargar productos');
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
        if (showLowStock && p.stock > 5) return false;
        return true;
      })
    : [];

  const guardar = async () => {
    const body = editando ? { ...form, id: editando.id } : form;
    const url = editando ? `/api/productos?id=${editando.id}` : '/api/productos';
    const method = editando ? 'PUT' : 'POST';
    await fetch(url, { method, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    setFormOpen(false);
    setEditando(null);
    setForm({ nombre: '', descripcion: '', precio: 0, costo: 0, stock: 0, codigoBarras: '', categoria: 'General' });
    load();
  };

  const eliminar = async (id: string) => {
    if (!confirm('¿Eliminar producto?')) return;
    await fetch(`/api/productos?id=${id}`, { method: 'DELETE' });
    load();
  };

  if (loading) return <div className="text-slate-500">Cargando productos...</div>;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-800">Productos</h1>
        <button onClick={() => { setEditando(null); setForm({ nombre: '', descripcion: '', precio: 0, costo: 0, stock: 0, codigoBarras: '', categoria: 'General' }); setFormOpen(true); }} className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">+ Nuevo Producto</button>
      </div>

      {error && <div className="bg-red-50 text-red-600 p-3 rounded-lg text-sm">{error}</div>}

      <div className="flex flex-wrap gap-3">
        <input type="text" placeholder="Buscar por nombre o código..." value={search} onChange={e => setSearch(e.target.value)} className="border border-slate-300 rounded-lg px-3 py-2 text-sm flex-1 min-w-[200px]" />
        <select value={filterCat} onChange={e => setFilterCat(e.target.value)} className="border border-slate-300 rounded-lg px-3 py-2 text-sm">
          <option value="">Todas las categorías</option>
          {CATEGORIAS.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
        <label className="flex items-center gap-2 text-sm text-slate-600">
          <input type="checkbox" checked={showLowStock} onChange={e => setShowLowStock(e.target.checked)} />
          Stock bajo
        </label>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-slate-50 text-slate-600">
              <th className="text-left p-3 font-medium">Nombre</th>
              <th className="text-left p-3 font-medium">Categoría</th>
              <th className="text-right p-3 font-medium">Precio</th>
              <th className="text-right p-3 font-medium">Costo</th>
              <th className="text-right p-3 font-medium">Stock</th>
              <th className="text-right p-3 font-medium">Ganancia</th>
              <th className="text-center p-3 font-medium">Código</th>
              <th className="text-center p-3 font-medium">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(p => (
              <tr key={p.id} className="border-t border-slate-100 hover:bg-slate-50">
                <td className="p-3 font-medium text-slate-800">{p.nombre}</td>
                <td className="p-3 text-slate-500">{p.categoria}</td>
                <td className="p-3 text-right">{formatearMoneda(p.precio)}</td>
                <td className="p-3 text-right text-slate-500">{formatearMoneda(p.costo)}</td>
                <td className={`p-3 text-right font-medium ${p.stock <= 5 ? 'text-red-600' : 'text-slate-700'}`}>{p.stock}</td>
                <td className="p-3 text-right text-emerald-600 font-medium">{formatearMoneda(p.precio - p.costo)}</td>
                <td className="p-3 text-center text-slate-400 text-xs">{p.codigoBarras || '—'}</td>
                <td className="p-3 text-center space-x-2">
                  <button onClick={() => { setEditando(p); setForm({ nombre: p.nombre, descripcion: p.descripcion, precio: p.precio, costo: p.costo, stock: p.stock, codigoBarras: p.codigoBarras, categoria: p.categoria }); setFormOpen(true); }} className="text-blue-600 hover:text-blue-800 text-xs">Editar</button>
                  <button onClick={() => eliminar(p.id)} className="text-red-600 hover:text-red-800 text-xs">Eliminar</button>
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan={8} className="p-8 text-center text-slate-400">No hay productos</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {formOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md space-y-4">
            <h2 className="text-lg font-bold">{editando ? 'Editar' : 'Nuevo'} Producto</h2>
            <input placeholder="Nombre" value={form.nombre} onChange={e => setForm({ ...form, nombre: e.target.value })} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <input placeholder="Descripción" value={form.descripcion} onChange={e => setForm({ ...form, descripcion: e.target.value })} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            <div className="grid grid-cols-2 gap-3">
              <input type="number" step="0.01" placeholder="Precio" value={form.precio} onChange={e => setForm({ ...form, precio: parseFloat(e.target.value) || 0 })} className="border border-slate-300 rounded-lg px-3 py-2 text-sm" />
              <input type="number" step="0.01" placeholder="Costo" value={form.costo} onChange={e => setForm({ ...form, costo: parseFloat(e.target.value) || 0 })} className="border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <input type="number" placeholder="Stock" value={form.stock} onChange={e => setForm({ ...form, stock: parseInt(e.target.value) || 0 })} className="border border-slate-300 rounded-lg px-3 py-2 text-sm" />
              <input placeholder="Código de barras" value={form.codigoBarras} onChange={e => setForm({ ...form, codigoBarras: e.target.value })} className="border border-slate-300 rounded-lg px-3 py-2 text-sm" />
            </div>
            <select value={form.categoria} onChange={e => setForm({ ...form, categoria: e.target.value })} className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm">
              {CATEGORIAS.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
            <div className="flex gap-3 justify-end">
              <button onClick={() => setFormOpen(false)} className="px-4 py-2 text-sm text-slate-600 hover:text-slate-800">Cancelar</button>
              <button onClick={guardar} className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">Guardar</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
