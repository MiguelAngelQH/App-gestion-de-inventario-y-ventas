import 'package:smart_ventas/models/cliente.dart';
import 'package:smart_ventas/models/compra.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/models/venta.dart';
import 'package:uuid/uuid.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._();
  factory MockDataService() => _instance;
  MockDataService._() {
    _init();
  }

  late List<Producto> _productos;
  late List<Cliente> _clientes;
  late List<Proveedor> _proveedores;
  late List<Venta> _ventas;
  late List<Compra> _compras;

  List<Producto> get productos => List.unmodifiable(_productos);
  List<Cliente> get clientes => List.unmodifiable(_clientes);
  List<Proveedor> get proveedores => List.unmodifiable(_proveedores);
  List<Venta> get ventas => List.unmodifiable(_ventas);
  List<Compra> get compras => List.unmodifiable(_compras);

  final _uuid = const Uuid();

  Presentacion _pres({
    required String nombreVisual,
    required String unidad,
    required double precio,
    required double costo,
    double factor = 1,
  }) =>
      Presentacion(
        id: _uuid.v4(),
        nombreVisual: nombreVisual,
        unidad: unidad,
        precio: precio,
        costo: costo,
        factor: factor,
      );

  void _init() {
    final pres1 = _pres(
        nombreVisual: 'Por Kilo',
        unidad: 'kg',
        precio: 22.50,
        costo: 18.00);
    final pres2 = _pres(
        nombreVisual: 'Por Kilo',
        unidad: 'kg',
        precio: 28.00,
        costo: 22.00);
    final pres3 = _pres(
        nombreVisual: 'Por Litro',
        unidad: 'lt',
        precio: 35.00,
        costo: 28.50);
    final pres4 = _pres(
        nombreVisual: 'Por Unidad',
        unidad: 'unidad',
        precio: 16.00,
        costo: 12.00);
    final pres5 = _pres(
        nombreVisual: 'Por Litro',
        unidad: 'lt',
        precio: 45.00,
        costo: 36.00);
    final pres6 = _pres(
        nombreVisual: 'Por Unidad',
        unidad: 'unidad',
        precio: 32.00,
        costo: 25.00);
    final pres7 = _pres(
        nombreVisual: 'Por Litro',
        unidad: 'lt',
        precio: 18.50,
        costo: 14.00);
    final pres8 = _pres(
        nombreVisual: 'Por Litro',
        unidad: 'lt',
        precio: 24.00,
        costo: 18.00);
    final pres9 = _pres(
        nombreVisual: 'Por Paquete',
        unidad: 'unidad',
        precio: 28.50,
        costo: 22.00);
    final pres10 = _pres(
        nombreVisual: 'Por Unidad',
        unidad: 'unidad',
        precio: 55.00,
        costo: 42.00);
    final pres11 = _pres(
        nombreVisual: 'Por Botella',
        unidad: 'unidad',
        precio: 28.00,
        costo: 22.00);
    final pres12 = _pres(
        nombreVisual: 'Por Caja',
        unidad: 'unidad',
        precio: 32.00,
        costo: 25.00);
    final pres13 = _pres(
        nombreVisual: 'Por Lata',
        unidad: 'unidad',
        precio: 15.00,
        costo: 11.00);
    final pres14 = _pres(
        nombreVisual: 'Por Paquete',
        unidad: 'unidad',
        precio: 14.50,
        costo: 10.50);
    final pres15 = _pres(
        nombreVisual: 'Por Unidad',
        unidad: 'unidad',
        precio: 28.00,
        costo: 21.00);

    _productos = [
      Producto(id: '1', nombre: 'Arroz Blanco 1kg', descripcion: 'Arroz blanco de grano largo', unidadBase: 'kg', stockTotal: 45, presentaciones: [pres1]),
      Producto(id: '2', nombre: 'Frijoles Negros 900g', descripcion: 'Frijoles negros seleccionados', unidadBase: 'kg', stockTotal: 30, presentaciones: [pres2]),
      Producto(id: '3', nombre: 'Aceite Vegetal 1L', descripcion: 'Aceite vegetal comestible', unidadBase: 'lt', stockTotal: 20, presentaciones: [pres3]),
      Producto(id: '4', nombre: 'Refresco Cola 600ml', descripcion: 'Refresco de cola', unidadBase: 'unidad', stockTotal: 60, presentaciones: [pres4]),
      Producto(id: '5', nombre: 'Jabón Líquido Ropa 1L', descripcion: 'Jabón líquido para ropa', unidadBase: 'lt', stockTotal: 3, presentaciones: [pres5]),
      Producto(id: '6', nombre: 'Pan Blanco 680g', descripcion: 'Pan blanco de caja', unidadBase: 'unidad', stockTotal: 15, presentaciones: [pres6]),
      Producto(id: '7', nombre: 'Leche Entera 1L', descripcion: 'Leche pasteurizada entera', unidadBase: 'lt', stockTotal: 2, presentaciones: [pres7]),
      Producto(id: '8', nombre: 'Cloro 2L', descripcion: 'Cloro para limpieza', unidadBase: 'lt', stockTotal: 25, presentaciones: [pres8]),
      Producto(id: '9', nombre: 'Papel Higiénico 4 rollos', descripcion: 'Papel higiénico', unidadBase: 'unidad', stockTotal: 1, presentaciones: [pres9]),
      Producto(id: '10', nombre: 'Shampoo 400ml', descripcion: 'Shampoo para todo tipo de cabello', unidadBase: 'unidad', stockTotal: 8, presentaciones: [pres10]),
      Producto(id: '11', nombre: 'Coca Cola 2L', descripcion: 'Refresco de cola', unidadBase: 'unidad', stockTotal: 4, presentaciones: [pres11]),
      Producto(id: '12', nombre: 'Detergente 800g', descripcion: 'Detergente en polvo', unidadBase: 'unidad', stockTotal: 18, presentaciones: [pres12]),
      Producto(id: '13', nombre: 'Cerveza Lata 355ml', descripcion: 'Cerveza clara en lata', unidadBase: 'unidad', stockTotal: 48, presentaciones: [pres13]),
      Producto(id: '14', nombre: 'Galletas María 170g', descripcion: 'Galletas tipo María', unidadBase: 'unidad', stockTotal: 35, presentaciones: [pres14]),
      Producto(id: '15', nombre: 'Pasta Dental 90g', descripcion: 'Pasta dental con flúor', unidadBase: 'unidad', stockTotal: 12, presentaciones: [pres15]),
    ];

    _clientes = [
      Cliente(id: '1', nombre: 'María García', telefono: '555-0101', email: 'maria@email.com', direccion: 'Calle Principal 123', deuda: 450.00),
      Cliente(id: '2', nombre: 'Juan Pérez', telefono: '555-0102', email: 'juan@email.com', direccion: 'Av. Central 456', deuda: 0),
      Cliente(id: '3', nombre: 'Ana López', telefono: '555-0103', email: 'ana@email.com', direccion: 'Calle Secundaria 789', deuda: 1200.50),
      Cliente(id: '4', nombre: 'Carlos Martínez', telefono: '555-0104', email: 'carlos@email.com', direccion: 'Blvd. Norte 321', deuda: 320.00),
      Cliente(id: '5', nombre: 'Sofía Ramírez', telefono: '555-0105', email: 'sofia@email.com', direccion: 'Calle Sur 654', deuda: 0),
    ];

    _proveedores = [
      Proveedor(id: '1', nombre: 'Distribuidora Alimenticia SA', telefono: '555-0201', email: 'ventas@dalimenticia.com', direccion: 'Av. Industrial 100', saldoPendiente: 3500.00),
      Proveedor(id: '2', nombre: 'Bebidas del Norte', telefono: '555-0202', email: 'pedidos@bebidasnorte.com', direccion: 'Calle Comercio 200', saldoPendiente: 2100.00),
      Proveedor(id: '3', nombre: 'Limpieza Total SRL', telefono: '555-0203', email: 'info@limpiezatotal.com', direccion: 'Av. Progreso 300', saldoPendiente: 0),
      Proveedor(id: '4', nombre: 'Higiene Personal SA', telefono: '555-0204', email: 'ventas@higienepersonal.com', direccion: 'Blvd. Salud 400', saldoPendiente: 1850.00),
      Proveedor(id: '5', nombre: 'Abarrotes Mayoristas', telefono: '555-0205', email: 'pedidos@abarrotesmy.com', direccion: 'Zona Industrial 500', saldoPendiente: 4200.00),
    ];

    final now = DateTime.now();
    final p = _productos;

    ItemVenta iv(int prodIdx, double cant, double pu, {double costo = 0}) =>
        ItemVenta(
          productoId: p[prodIdx].id,
          productoNombre: p[prodIdx].nombre,
          categoria: p[prodIdx].categoria,
          presentacionId: p[prodIdx].presentaciones.first.id,
          presentacionNombre: p[prodIdx].presentaciones.first.nombreVisual,
          factor: p[prodIdx].presentaciones.first.factor,
          cantidad: cant,
          precioUnitario: pu,
          costoUnitario: costo > 0 ? costo : p[prodIdx].presentaciones.first.costo,
        );

    ItemCompra ic(int prodIdx, double cant, double cu) => ItemCompra(
          productoId: p[prodIdx].id,
          productoNombre: p[prodIdx].nombre,
          categoria: p[prodIdx].categoria,
          presentacionId: p[prodIdx].presentaciones.first.id,
          presentacionNombre: p[prodIdx].presentaciones.first.nombreVisual,
          factor: p[prodIdx].presentaciones.first.factor,
          cantidad: cant,
          costoUnitario: cu,
        );

    _ventas = [
      Venta(id: 'v001', fecha: now.subtract(const Duration(hours: 2)), clienteId: _clientes[0].id, clienteNombre: _clientes[0].nombre, items: [iv(0, 2, 22.50), iv(3, 3, 16.00), iv(13, 1, 14.50)], total: 107.50, metodoPago: 'Efectivo', estado: 'completada'),
      Venta(id: 'v002', fecha: now.subtract(const Duration(hours: 5)), clienteId: _clientes[1].id, clienteNombre: _clientes[1].nombre, items: [iv(4, 1, 45.00), iv(6, 2, 18.50)], total: 82.00, metodoPago: 'Tarjeta Débito', estado: 'completada'),
      Venta(id: 'v003', fecha: now.subtract(const Duration(days: 1)), clienteId: _clientes[2].id, clienteNombre: _clientes[2].nombre, items: [iv(9, 1, 55.00), iv(1, 2, 28.00), iv(2, 1, 35.00), iv(14, 2, 28.00)], total: 202.00, metodoPago: 'Tarjeta Crédito', estado: 'completada'),
      Venta(id: 'v004', fecha: now.subtract(const Duration(days: 1)), items: [iv(10, 3, 28.00), iv(12, 6, 15.00)], total: 174.00, metodoPago: 'Efectivo', estado: 'completada'),
      Venta(id: 'v005', fecha: now.subtract(const Duration(days: 2)), clienteId: _clientes[3].id, clienteNombre: _clientes[3].nombre, items: [iv(0, 5, 22.50), iv(2, 2, 35.00), iv(7, 1, 24.00)], total: 206.50, metodoPago: 'Transferencia', estado: 'pendiente'),
      Venta(id: 'v006', fecha: now.subtract(const Duration(days: 3)), items: [iv(11, 2, 32.00), iv(1, 3, 28.00)], total: 148.00, metodoPago: 'Efectivo', estado: 'completada'),
      Venta(id: 'v007', fecha: now.subtract(const Duration(days: 4)), clienteId: _clientes[0].id, clienteNombre: _clientes[0].nombre, items: [iv(5, 2, 32.00), iv(8, 4, 28.50), iv(3, 2, 16.00)], total: 210.00, metodoPago: 'Efectivo', estado: 'completada'),
      Venta(id: 'v008', fecha: now.subtract(const Duration(days: 5)), clienteId: _clientes[4].id, clienteNombre: _clientes[4].nombre, items: [iv(12, 12, 15.00), iv(13, 5, 14.50)], total: 252.50, metodoPago: 'Tarjeta Débito', estado: 'completada'),
    ];

    _compras = [
      Compra(id: 'c001', fecha: now.subtract(const Duration(days: 3)), proveedorId: _proveedores[0].id, proveedorNombre: _proveedores[0].nombre, items: [ic(0, 30, 18.00), ic(1, 20, 22.00), ic(5, 15, 25.00)], total: 1355.00, estado: 'recibida'),
      Compra(id: 'c002', fecha: now.subtract(const Duration(days: 2)), proveedorId: _proveedores[1].id, proveedorNombre: _proveedores[1].nombre, items: [ic(3, 50, 12.00), ic(10, 30, 22.00), ic(12, 48, 11.00)], total: 1788.00, estado: 'pendiente'),
      Compra(id: 'c003', fecha: now.subtract(const Duration(days: 5)), proveedorId: _proveedores[2].id, proveedorNombre: _proveedores[2].nombre, items: [ic(4, 20, 36.00), ic(7, 25, 18.00), ic(11, 15, 25.00)], total: 1545.00, estado: 'recibida'),
      Compra(id: 'c004', fecha: now.subtract(const Duration(days: 7)), proveedorId: _proveedores[3].id, proveedorNombre: _proveedores[3].nombre, items: [ic(9, 10, 42.00), ic(14, 20, 21.00)], total: 840.00, estado: 'recibida'),
      Compra(id: 'c005', fecha: now.subtract(const Duration(days: 1)), proveedorId: _proveedores[4].id, proveedorNombre: _proveedores[4].nombre, items: [ic(0, 50, 18.00), ic(1, 40, 22.00), ic(2, 25, 28.50)], total: 2492.50, estado: 'pendiente'),
    ];
  }

  int get productosStockBajo => _productos.where((p) => p.stockBajo).length;

  int get ventasHoy => _ventas.where((v) => v.fecha.day == DateTime.now().day && v.estado == 'completada').length;

  double get totalVentasHoy => _ventas.where((v) => v.fecha.day == DateTime.now().day && v.estado == 'completada').fold(0, (sum, v) => sum + v.total);

  double get totalVentasSemana => _ventas.where((v) => v.fecha.isAfter(DateTime.now().subtract(const Duration(days: 7))) && v.estado == 'completada').fold(0, (sum, v) => sum + v.total);

  double get totalVentasMes => _ventas.where((v) => v.fecha.month == DateTime.now().month && v.fecha.year == DateTime.now().year && v.estado == 'completada').fold(0, (sum, v) => sum + v.total);

  double get totalComprasPendientes => _compras.where((c) => c.estado == 'pendiente').fold(0, (sum, c) => sum + c.total);

  double get totalCuentasCobrar => _clientes.fold(0, (sum, c) => sum + c.deuda);

  double get totalCuentasPagar => _proveedores.fold(0, (sum, p) => sum + p.saldoPendiente);

  double get gananciaTotal => _ventas.where((v) => v.estado == 'completada').fold(0, (sum, v) {
        final costo = v.items.fold(0.0, (s, i) => s + (i.cantidad * i.costoUnitario));
        return sum + (v.total - costo);
      });

  List<Venta> get ultimasVentas {
    final sorted = List<Venta>.from(_ventas);
    sorted.sort((a, b) => b.fecha.compareTo(a.fecha));
    return sorted.take(5).toList();
  }

  Map<String, double> get ventasPorCategoria {
    final map = <String, double>{};
    for (final venta in _ventas) {
      if (venta.estado == 'completada') {
        for (final item in venta.items) {
          map.update(item.categoria, (v) => v + item.subtotal, ifAbsent: () => item.subtotal);
        }
      }
    }
    return map;
  }

  Map<DateTime, double> get ventasUltimos7Dias {
    final map = <DateTime, double>{};
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      map[DateTime(day.year, day.month, day.day)] = 0;
    }
    for (final venta in _ventas) {
      if (venta.estado == 'completada') {
        final day = DateTime(venta.fecha.year, venta.fecha.month, venta.fecha.day);
        if (map.containsKey(day)) map[day] = map[day]! + venta.total;
      }
    }
    return map;
  }

  List<Producto> get topProductos {
    final conteo = <String, int>{};
    for (final venta in _ventas) {
      for (final item in venta.items) {
        conteo.update(item.productoId, (v) => v + item.cantidad.toInt(), ifAbsent: () => item.cantidad.toInt());
      }
    }
    final sorted = _productos.toList()
      ..sort((a, b) => (conteo[b.id] ?? 0).compareTo(conteo[a.id] ?? 0));
    return sorted.take(5).toList();
  }
}
