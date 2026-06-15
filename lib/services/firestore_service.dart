import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_ventas/models/cliente.dart';
import 'package:smart_ventas/models/compra.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/models/venta.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  CollectionReference<Map<String, dynamic>> _coll(String name) =>
      _db.collection(name);

  Map<String, dynamic> _withUid(Map<String, dynamic> data) =>
      {...data, 'uid': _uid};

  CollectionReference<Map<String, dynamic>> get _productos => _coll('productos');
  CollectionReference<Map<String, dynamic>> get _ventas => _coll('ventas');
  CollectionReference<Map<String, dynamic>> get _compras => _coll('compras');
  CollectionReference<Map<String, dynamic>> get _clientes => _coll('clientes');
  CollectionReference<Map<String, dynamic>> get _proveedores => _coll('proveedores');
  CollectionReference<Map<String, dynamic>> get _pagosCobrar => _coll('pagos_cobrar');
  CollectionReference<Map<String, dynamic>> get _pagosPagar => _coll('pagos_pagar');
  CollectionReference<Map<String, dynamic>> get _config => _coll('config');

  Query<Map<String, dynamic>> _userQuery(
          CollectionReference<Map<String, dynamic>> ref) =>
      ref.where('uid', isEqualTo: _uid);

  // ============ PRODUCTOS ============

  Stream<List<Producto>> getProductos() =>
      _userQuery(_productos).snapshots().map((snap) =>
          snap.docs.map((doc) => Producto.fromMap({
                ...doc.data(),
                'id': doc.id,
              })).toList());

  Future<void> addProducto(Producto p) =>
      _productos.add(_withUid(p.toMap()..remove('id')));

  Future<void> updateProducto(Producto p) =>
      _productos.doc(p.id).update(p.toMap()..remove('id'));

  Future<void> deleteProducto(String id) => _productos.doc(id).delete();

  Future<Producto?> getProducto(String id) async {
    final doc = await _productos.doc(id).get();
    if (!doc.exists) return null;
    return Producto.fromMap({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    });
  }

  // ============ VENTAS ============

  Stream<List<Venta>> getVentas() =>
      _userQuery(_ventas).snapshots().map(
          (snap) => snap.docs
              .map((doc) => Venta.fromMap({
                    ...doc.data(),
                    'id': doc.id,
                  }))
              .toList());

  Future<String> addVenta(Venta v) async {
    final batch = _db.batch();

    final ventaRef = _ventas.doc();
    batch.set(ventaRef, _withUid(v.toMap()..remove('id')));

    for (final item in v.items) {
      final prodRef = _productos.doc(item.productoId);
      batch.update(prodRef, {
        'stockTotal': FieldValue.increment(-(item.cantidad * item.factor)),
      });
    }

    await batch.commit();
    return ventaRef.id;
  }

  Future<void> updateVentaEstado(String id, String estado) =>
      _ventas.doc(id).update({'estado': estado});

  // ============ COMPRAS ============

  Stream<List<Compra>> getCompras() =>
      _userQuery(_compras).snapshots().map(
          (snap) => snap.docs
              .map((doc) => Compra.fromMap({
                    ...doc.data(),
                    'id': doc.id,
                  }))
              .toList());

  Future<String> addCompra(Compra c) async {
    final batch = _db.batch();

    final compraRef = _compras.doc();
    batch.set(compraRef, _withUid(c.toMap()..remove('id')));

    for (final item in c.items) {
      final prodRef = _productos.doc(item.productoId);
      batch.update(prodRef, {
        'stockTotal': FieldValue.increment(item.cantidad * item.factor),
      });
    }

    await batch.commit();

    for (final item in c.items) {
      await _actualizarCostoPresentacion(item.productoId, item.presentacionId, item.costoUnitario);
    }

    return compraRef.id;
  }

  Future<void> _actualizarCostoPresentacion(
      String productoId, String presentacionId, double nuevoCosto) async {
    final doc = await _productos.doc(productoId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final presentaciones = (data['presentaciones'] as List<dynamic>?)
            ?.map((p) => Map<String, dynamic>.from(p as Map))
            .toList() ??
        [];
    bool updated = false;
    for (final p in presentaciones) {
      if (p['id'] == presentacionId) {
        p['costo'] = nuevoCosto;
        updated = true;
        break;
      }
    }
    if (updated) {
      await _productos.doc(productoId).update({'presentaciones': presentaciones});
    }
  }

  Future<void> updateCompraEstado(String id, String estado) =>
      _compras.doc(id).update({'estado': estado});

  // ============ CLIENTES ============

  Stream<List<Cliente>> getClientes() =>
      _userQuery(_clientes).snapshots().map((snap) =>
          snap.docs.map((doc) => Cliente.fromMap({
                ...doc.data(),
                'id': doc.id,
              })).toList());

  Future<void> addCliente(Cliente c) =>
      _clientes.add(_withUid(c.toMap()..remove('id')));

  Future<void> updateCliente(Cliente c) =>
      _clientes.doc(c.id).update(c.toMap()..remove('id'));

  Future<void> registrarPagoCobrar(
      String clienteId, double monto, String nota) async {
    final batch = _db.batch();
    final clienteRef = _clientes.doc(clienteId);
    batch.update(clienteRef, {
      'deuda': FieldValue.increment(-monto),
    });
    final pagoRef = _pagosCobrar.doc();
    batch.set(pagoRef, _withUid({
      'clienteId': clienteId,
      'monto': monto,
      'fecha': DateTime.now().toIso8601String(),
      'nota': nota,
    }));
    await batch.commit();
    final doc = await clienteRef.get();
    if (doc.exists && ((doc.data()?['deuda'] ?? 0) as num) <= 0) {
      await clienteRef.update({'estado': 'pagado'});
    }
  }

  Future<void> actualizarEstadoCliente(
          String clienteId, String estado) async =>
      _clientes.doc(clienteId).update({'estado': estado});

  // ============ PROVEEDORES ============

  Stream<List<Proveedor>> getProveedores() =>
      _userQuery(_proveedores).snapshots().map((snap) =>
          snap.docs.map((doc) => Proveedor.fromMap({
                ...doc.data(),
                'id': doc.id,
              })).toList());

  Future<void> addProveedor(Proveedor p) =>
      _proveedores.add(_withUid(p.toMap()..remove('id')));

  Future<void> updateProveedor(Proveedor p) =>
      _proveedores.doc(p.id).update(p.toMap()..remove('id'));

  Future<void> registrarPagoPagar(
      String proveedorId, double monto, String nota) async {
    final batch = _db.batch();
    final proveedorRef = _proveedores.doc(proveedorId);
    batch.update(proveedorRef, {
      'saldoPendiente': FieldValue.increment(-monto),
    });
    final pagoRef = _pagosPagar.doc();
    batch.set(pagoRef, _withUid({
      'proveedorId': proveedorId,
      'monto': monto,
      'fecha': DateTime.now().toIso8601String(),
      'nota': nota,
    }));
    await batch.commit();
    final doc = await proveedorRef.get();
    if (doc.exists && ((doc.data()?['saldoPendiente'] ?? 0) as num) <= 0) {
      await proveedorRef.update({'estado': 'pagado'});
    }
  }

  Future<void> actualizarEstadoProveedor(
          String proveedorId, String estado) async =>
      _proveedores.doc(proveedorId).update({'estado': estado});

  // ============ DASHBOARD / REPORTES ============

  Future<double> totalVentasHoy() async {
    try {
      final start = DateTime.now();
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = startDay.add(const Duration(days: 1));
      final snap = await _userQuery(_ventas)
          .where('fecha', isGreaterThanOrEqualTo: startDay.toIso8601String())
          .where('fecha', isLessThan: endDay.toIso8601String())
          .get();
      double total = 0;
      for (final d in snap.docs) {
        total += (d.data()['total'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<double> totalVentasPeriodo(DateTime desde, DateTime hasta) async {
    try {
      final snap = await _userQuery(_ventas)
          .where('fecha', isGreaterThanOrEqualTo: desde.toIso8601String())
          .where('fecha', isLessThan: hasta.toIso8601String())
          .get();
      double total = 0;
      for (final d in snap.docs) {
        total += (d.data()['total'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<double> totalComprasPeriodo(DateTime desde, DateTime hasta) async {
    try {
      final snap = await _userQuery(_compras)
          .where('fecha', isGreaterThanOrEqualTo: desde.toIso8601String())
          .where('fecha', isLessThan: hasta.toIso8601String())
          .get();
      double total = 0;
      for (final d in snap.docs) {
        total += (d.data()['total'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<int> ventasCountHoy() async {
    try {
      final start = DateTime.now();
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = startDay.add(const Duration(days: 1));
      final snap = await _userQuery(_ventas)
          .where('fecha', isGreaterThanOrEqualTo: startDay.toIso8601String())
          .where('fecha', isLessThan: endDay.toIso8601String())
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> productosStockBajoCount() async {
    try {
      final snap =
          await _userQuery(_productos).where('stockTotal', isLessThanOrEqualTo: 5).get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<double> totalCuentasCobrar() async {
    try {
      final snap = await _userQuery(_clientes).get();
      double total = 0;
      for (final d in snap.docs) {
        total += (d.data()['deuda'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<double> totalCuentasPagar() async {
    try {
      final snap = await _userQuery(_proveedores).get();
      double total = 0;
      for (final d in snap.docs) {
        total += (d.data()['saldoPendiente'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<double> totalGanancia() async {
    try {
      final snap = await _userQuery(_ventas).get();
      double ganancia = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        double costoTotal = 0;
        for (final item in items) {
          final costoUnitario = (item['costoUnitario'] ?? 0).toDouble();
          final cantidad = (item['cantidad'] ?? 0).toDouble();
          costoTotal += costoUnitario * cantidad;
        }
        final total = (data['total'] ?? 0).toDouble();
        ganancia += total - costoTotal;
      }
      return ganancia;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Venta>> ultimasVentas({int limit = 5}) async {
    try {
      final snap = await _userQuery(_ventas).get();
      final ventas = snap.docs.map((doc) {
        final data = doc.data();
        return Venta.fromMap({...data, 'id': doc.id});
      }).toList();
      ventas.sort((a, b) => b.fecha.compareTo(a.fecha));
      return ventas.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, double>> ventasPorCategoria() async {
    try {
      final snap = await _userQuery(_ventas).get();
      final map = <String, double>{};
      for (final doc in snap.docs) {
        final items = doc.data()['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final cat = item['categoria'] as String? ?? 'General';
          final subtotal = (item['subtotal'] ?? 0).toDouble();
          map.update(cat, (v) => v + subtotal, ifAbsent: () => subtotal);
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<Map<DateTime, double>> ventasUltimos7Dias() async {
    try {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
      final end = start.add(const Duration(days: 7));
      final snap = await _userQuery(_ventas)
          .where('fecha', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('fecha', isLessThan: end.toIso8601String())
          .get();
      final map = <DateTime, double>{};
      for (int i = 0; i < 7; i++) {
        map[start.add(Duration(days: i))] = 0;
      }
      for (final doc in snap.docs) {
        final data = doc.data();
        final fecha = DateTime.parse(data['fecha']);
        final day = DateTime(fecha.year, fecha.month, fecha.day);
        if (map.containsKey(day)) {
          map[day] = map[day]! + ((data['total'] as num?)?.toDouble() ?? 0);
        }
      }
      return map;
    } catch (_) {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
      final map = <DateTime, double>{};
      for (int i = 0; i < 7; i++) {
        map[start.add(Duration(days: i))] = 0;
      }
      return map;
    }
  }

  Future<List<Producto>> topProductos({int limit = 5}) async {
    try {
      final snap = await _userQuery(_ventas).get();
      final conteo = <String, int>{};
      for (final doc in snap.docs) {
        final items = doc.data()['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final id = item['productoId'] as String? ?? '';
          final cant = (item['cantidad'] ?? 0) as int;
          conteo.update(id, (v) => v + cant, ifAbsent: () => cant);
        }
      }
      final sorted = conteo.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topIds = sorted.take(limit).map((e) => e.key).toList();
      final productos = <Producto>[];
      for (final id in topIds) {
        final p = await getProducto(id);
        if (p != null) productos.add(p);
      }
      return productos;
    } catch (_) {
      return [];
    }
  }

  Future<bool> verificarStockBajo() async {
    final snap =
        await _userQuery(_productos).where('stockTotal', isLessThanOrEqualTo: 5).get();
    return snap.docs.isNotEmpty;
  }

  Future<List<Cliente>> clientesProximosVencer({int dias = 3}) async {
    try {
      final hoy = DateTime.now();
      final limite = hoy.add(Duration(days: dias));
      final snap = await _userQuery(_clientes).get();
      final result = <Cliente>[];
      for (final doc in snap.docs) {
        final c = Cliente.fromMap({...doc.data(), 'id': doc.id});
        if (c.estado == 'pendiente' &&
            c.deuda > 0 &&
            c.fechaVencimiento != null &&
            c.fechaVencimiento!.isAfter(hoy) &&
            c.fechaVencimiento!.isBefore(limite)) {
          result.add(c);
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<List<Proveedor>> proveedoresProximosVencer({int dias = 3}) async {
    try {
      final hoy = DateTime.now();
      final limite = hoy.add(Duration(days: dias));
      final snap = await _userQuery(_proveedores).get();
      final result = <Proveedor>[];
      for (final doc in snap.docs) {
        final p = Proveedor.fromMap({...doc.data(), 'id': doc.id});
        if (p.estado == 'pendiente' &&
            p.saldoPendiente > 0 &&
            p.fechaVencimiento != null &&
            p.fechaVencimiento!.isAfter(hoy) &&
            p.fechaVencimiento!.isBefore(limite)) {
          result.add(p);
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Stream<QuerySnapshot<Object?>> streamVentas() =>
      _ventas.where('uid', isEqualTo: _uid).snapshots();

  // ============ PRESENTACIONES ============

  Future<void> actualizarPrecioPresentacion(
      String productoId, String presentacionId, double nuevoPrecio) async {
    final doc = await _productos.doc(productoId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final presentaciones = (data['presentaciones'] as List<dynamic>?)
            ?.map((p) => Map<String, dynamic>.from(p as Map))
            .toList() ??
        [];
    for (final p in presentaciones) {
      if (p['id'] == presentacionId) {
        p['precio'] = nuevoPrecio;
        break;
      }
    }
    await _productos.doc(productoId).update({'presentaciones': presentaciones});
  }

  Future<void> actualizarCostoPresentacion(
      String productoId, String presentacionId, double nuevoCosto) async {
    final doc = await _productos.doc(productoId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final presentaciones = (data['presentaciones'] as List<dynamic>?)
            ?.map((p) => Map<String, dynamic>.from(p as Map))
            .toList() ??
        [];
    for (final p in presentaciones) {
      if (p['id'] == presentacionId) {
        p['costo'] = nuevoCosto;
        break;
      }
    }
    await _productos.doc(productoId).update({'presentaciones': presentaciones});
  }

  // ============ CONFIG ============

  Future<Map<String, dynamic>> getConfig() async {
    final doc = await _config.doc(_uid).get();
    return doc.data() ?? {};
  }

  Future<void> updateConfig(Map<String, dynamic> data) async {
    await _config.doc(_uid).set(_withUid(data), SetOptions(merge: true));
  }
}
