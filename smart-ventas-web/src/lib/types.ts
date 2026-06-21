export interface Presentacion {
  id: string;
  nombreVisual: string;
  unidad: string;
  precio: number;
  costo: number;
  factor: number;
}

export interface Producto {
  id: string;
  nombre: string;
  descripcion: string;
  codigoBarras: string;
  categoria: string;
  marca: string;
  proveedorId: string;
  proveedorNombre: string;
  unidadBase: string;
  stockTotal: number;
  precio: number;
  costo: number;
  presentaciones: Presentacion[];
  fechaCreacion: string;
}

export interface ItemVenta {
  productoId: string;
  productoNombre: string;
  categoria: string;
  presentacionId: string;
  presentacionNombre: string;
  factor: number;
  cantidad: number;
  precioUnitario: number;
  subtotal: number;
  costoUnitario: number;
}

export interface Venta {
  id: string;
  uid: string;
  fecha: string;
  clienteId?: string;
  clienteNombre?: string;
  items: ItemVenta[];
  total: number;
  metodoPago: string;
  estado: string;
}

export interface ItemCompra {
  productoId: string;
  productoNombre: string;
  categoria: string;
  presentacionId: string;
  presentacionNombre: string;
  factor: number;
  cantidad: number;
  costoUnitario: number;
  subtotal: number;
}

export interface Compra {
  id: string;
  uid: string;
  fecha: string;
  proveedorId: string;
  proveedorNombre: string;
  items: ItemCompra[];
  total: number;
  estado: string;
}

export interface Cliente {
  id: string;
  uid: string;
  nombre: string;
  telefono: string;
  email: string;
  direccion: string;
  deuda: number;
  estado: string;
  fechaVencimiento?: string;
}

export interface Proveedor {
  id: string;
  uid: string;
  nombre: string;
  telefono: string;
  email: string;
  direccion: string;
  saldoPendiente: number;
  estado: string;
  fechaVencimiento?: string;
}

export interface DashboardMetrics {
  ventasHoy: number;
  ventasSemana: number;
  gananciaTotal: number;
  stockBajo: number;
  cuentasCobrar: number;
  cuentasPagar: number;
  ventasCountHoy: number;
}

export interface VentaPorDia {
  fecha: string;
  total: number;
}

export interface VentaPorCategoria {
  categoria: string;
  total: number;
}

export interface TopProducto {
  id: string;
  nombre: string;
  cantidad: number;
}

export const CATEGORIAS = [
  'General', 'Alimentos', 'Bebidas', 'Limpieza', 'Higiene',
  'Ropa', 'Electrónicos', 'Hogar', 'Ferretería', 'Papelería',
];

export const METODOS_PAGO = [
  'Efectivo', 'Tarjeta Débito', 'Tarjeta Crédito', 'Transferencia', 'Depósito',
];

export const UNIDADES_MEDIDA = [
  'kg', 'lb', 'lt', 'caja', 'docena', 'unidad',
];

export const ESTADOS_VENTA = ['completada', 'pendiente', 'cancelada'];
export const ESTADOS_COMPRA = ['pendiente', 'recibida', 'cancelada'];
export const ESTADOS_CLIENTE = ['pendiente', 'pagado', 'vencido'];
export const ESTADOS_PROVEEDOR = ['pendiente', 'pagado', 'vencido'];

export function formatearMoneda(valor: number): string {
  return `S/ ${valor.toFixed(2)}`;
}

export function formatearFecha(fecha: string): string {
  return new Date(fecha).toLocaleDateString('es-PE', {
    year: 'numeric', month: 'short', day: 'numeric',
  });
}

export function formatearFechaHora(fecha: string): string {
  return new Date(fecha).toLocaleString('es-PE');
}

export function parseFecha(fecha: string): Date {
  return new Date(fecha);
}
