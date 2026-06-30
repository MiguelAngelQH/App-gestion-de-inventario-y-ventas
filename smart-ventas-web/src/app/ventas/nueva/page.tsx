'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { Plus, X, ShoppingCart, Minus, Search } from 'lucide-react';
import { Producto, formatearMoneda, METODOS_PAGO } from '@/lib/types';

interface ItemVentaForm {
  productoId: string;
  productoNombre: string;
  presentacionId: string;
  presentacionNombre: string;
  categoria: string;
  cantidad: number;
  precioUnitario: number;
  costoUnitario: number;
  subtotal: number;
}

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

export default function NuevaVentaPage() {
  const router = useRouter();
  const [productos, setProductos] = useState<Producto[]>([]);
  const [loading, setLoading] = useState(true);
  const [clienteNombre, setClienteNombre] = useState('');
  const [metodoPago, setMetodoPago] = useState('Efectivo');
  const [items, setItems] = useState<ItemVentaForm[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [showProductSelector, setShowProductSelector] = useState(false);
  const [guardando, setGuardando] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch('/api/productos');
        const data = await res.json();
        setProductos(Array.isArray(data) ? data : []);
      } catch {
        setProductos([]);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const filteredProductos = productos.filter(p =>
    !searchTerm || p.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.codigoBarras.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const total = items.reduce((sum, item) => sum + item.subtotal, 0);

  const agregarItem = (producto: Producto, presentacion: { id: string; nombre: string; precio: number }) => {
    if (items.some(i => i.productoId === producto.id && i.presentacionId === presentacion.id)) return;
    setItems([...items, {
      productoId: producto.id,
      productoNombre: producto.nombre,
      presentacionId: presentacion.id,
      presentacionNombre: presentacion.nombre,
      categoria: producto.categoria,
      cantidad: 1,
      precioUnitario: presentacion.precio,
      costoUnitario: producto.costo ?? 0,
      subtotal: presentacion.precio,
    }]);
    setShowProductSelector(false);
    setSearchTerm('');
  };

  const actualizarCantidad = (idx: number, cantidad: number) => {
    const updated = [...items];
    updated[idx] = {
      ...updated[idx],
      cantidad: Math.max(0.01, cantidad),
      subtotal: cantidad * updated[idx].precioUnitario,
    };
    setItems(updated);
  };

  const eliminarItem = (idx: number) => {
    setItems(items.filter((_, i) => i !== idx));
  };

  const guardar = async () => {
    if (items.length === 0) return;
    setGuardando(true);
    try {
      const res = await fetch('/api/ventas', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          items: items.map(i => ({
            ...i,
            cantidad: i.cantidad,
            subtotal: i.subtotal,
          })),
          total,
          metodoPago,
          clienteNombre: clienteNombre.trim() || undefined,
          estado: 'completada',
        }),
      });
      if (res.ok) {
        router.push('/ventas');
      }
    } catch {
      // error
    } finally {
      setGuardando(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
          <p className="text-sm text-[var(--text-muted)]">Cargando...</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-5 max-w-3xl mx-auto">
      <motion.div variants={itemVariants} className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Nueva Venta</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Registra una nueva venta</p>
        </div>
        <button onClick={() => router.push('/ventas')} className="btn-secondary">
          <X size={16} /> Cancelar
        </button>
      </motion.div>

      <motion.div variants={itemVariants} className="card p-5 space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <input
            placeholder="Nombre del cliente (opcional)"
            value={clienteNombre}
            onChange={e => setClienteNombre(e.target.value)}
            className="w-full"
          />
          <select value={metodoPago} onChange={e => setMetodoPago(e.target.value)} className="w-full">
            {METODOS_PAGO.map(m => <option key={m} value={m}>{m}</option>)}
          </select>
        </div>
      </motion.div>

      <motion.div variants={itemVariants} className="card p-5 space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold text-[var(--text-primary)]">Productos</h2>
          <button onClick={() => setShowProductSelector(true)} className="btn-primary text-xs">
            <Plus size={14} /> Agregar Producto
          </button>
        </div>

        {items.length === 0 ? (
          <div className="text-center py-8 text-sm text-[var(--text-muted)]">
            No hay productos agregados. Presiona "Agregar Producto" para empezar.
          </div>
        ) : (
          <div className="space-y-3">
            {items.map((item, idx) => (
              <div key={idx} className="flex items-center gap-3 p-3 rounded-xl bg-[var(--bg-tertiary)]">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-[var(--text-primary)] truncate">{item.productoNombre}</p>
                  <p className="text-xs text-[var(--text-muted)]">{item.presentacionNombre}</p>
                </div>
                <div className="flex items-center gap-2">
                  <button onClick={() => actualizarCantidad(idx, item.cantidad - 1)} className="btn-secondary p-1"><Minus size={14} /></button>
                  <input
                    type="number"
                    step="0.01"
                    value={item.cantidad}
                    onChange={e => actualizarCantidad(idx, parseFloat(e.target.value) || 0)}
                    className="w-20 text-center text-sm"
                  />
                  <button onClick={() => actualizarCantidad(idx, item.cantidad + 1)} className="btn-secondary p-1"><Plus size={14} /></button>
                </div>
                <div className="text-right min-w-[80px]">
                  <p className="text-sm font-semibold text-[var(--text-primary)]">{formatearMoneda(item.subtotal)}</p>
                  <p className="text-xs text-[var(--text-muted)]">{formatearMoneda(item.precioUnitario)} c/u</p>
                </div>
                <button onClick={() => eliminarItem(idx)} className="text-red-500 hover:text-red-700 p-1">
                  <X size={16} />
                </button>
              </div>
            ))}
          </div>
        )}

        {items.length > 0 && (
          <div className="flex justify-between items-center pt-3 border-t border-[var(--border)]">
            <span className="text-sm text-[var(--text-secondary)]">Total</span>
            <span className="text-xl font-bold text-[var(--accent)]">{formatearMoneda(total)}</span>
          </div>
        )}
      </motion.div>

      <motion.div variants={itemVariants} className="flex justify-end">
        <button
          onClick={guardar}
          disabled={items.length === 0 || guardando}
          className="btn-primary"
        >
          <ShoppingCart size={16} />
          {guardando ? 'Guardando...' : 'Completar Venta'}
        </button>
      </motion.div>

      {showProductSelector && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="fixed inset-0 bg-black/30 dark:bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
          onClick={() => setShowProductSelector(false)}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            onClick={e => e.stopPropagation()}
            className="card p-6 w-full max-w-lg mx-4 max-h-[80vh] flex flex-col"
          >
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-[var(--text-primary)]">Seleccionar Producto</h2>
              <button onClick={() => setShowProductSelector(false)} className="text-[var(--text-muted)] hover:text-[var(--text-primary)]"><X size={20} /></button>
            </div>
            <div className="relative mb-4">
              <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" />
              <input
                type="text"
                placeholder="Buscar producto..."
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5"
                autoFocus
              />
            </div>
            <div className="flex-1 overflow-y-auto space-y-2">
              {filteredProductos.map(p => (
                <div key={p.id} className="card p-3">
                  <p className="text-sm font-medium text-[var(--text-primary)]">{p.nombre}</p>
                  <p className="text-xs text-[var(--text-muted)] mb-2">Stock: {p.stock}</p>
                  <div className="flex flex-wrap gap-2">
                    {(p.presentaciones || []).map(pr => (
                      <button
                        key={pr.id}
                        onClick={() => agregarItem(p, { id: pr.id, nombre: pr.nombre || pr.unidad, precio: pr.precio })}
                        disabled={p.stock <= 0}
                        className="btn-secondary text-xs py-1 px-3 disabled:opacity-40"
                      >
                        {pr.nombre || pr.unidad} - {formatearMoneda(pr.precio)}
                      </button>
                    ))}
                  </div>
                </div>
              ))}
              {filteredProductos.length === 0 && (
                <p className="text-sm text-[var(--text-muted)] text-center py-8">No se encontraron productos</p>
              )}
            </div>
          </motion.div>
        </motion.div>
      )}
    </motion.div>
  );
}
