import 'package:smart_ventas/models/producto.dart';

class ItemVenta {
  Producto producto;
  int cantidad;
  double precioUnitario;

  ItemVenta({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toMap() => {
        'productoId': producto.id,
        'productoNombre': producto.nombre,
        'categoria': producto.categoria,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'subtotal': subtotal,
        'costoUnitario': producto.costo,
      };

  factory ItemVenta.fromMap(Map<String, dynamic> map) => ItemVenta(
        producto: Producto(
          id: map['productoId'],
          nombre: map['productoNombre'] ?? '',
          precio: (map['precioUnitario'] ?? 0).toDouble(),
          costo: (map['costoUnitario'] ?? 0).toDouble(),
          categoria: map['categoria'] ?? 'General',
        ),
        cantidad: map['cantidad'],
        precioUnitario: (map['precioUnitario'] ?? 0).toDouble(),
      );
}

class Venta {
  final String id;
  DateTime fecha;
  String? clienteId;
  String? clienteNombre;
  List<ItemVenta> items;
  double total;
  String metodoPago;
  String estado;

  Venta({
    required this.id,
    required this.fecha,
    this.clienteId,
    this.clienteNombre,
    required this.items,
    required this.total,
    this.metodoPago = 'Efectivo',
    this.estado = 'completada',
  });

  String get folio {
    try {
      return 'V-${id.substring(0, 8).toUpperCase()}';
    } catch (_) {
      return 'V-XXXX';
    }
  }

  Map<String, dynamic> toMap() => {
        'fecha': fecha.toIso8601String(),
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'items': items.map((i) => i.toMap()).toList(),
        'total': total,
        'metodoPago': metodoPago,
        'estado': estado,
      };

  factory Venta.fromMap(Map<String, dynamic> map) => Venta(
        id: map['id'] ?? '',
        fecha: DateTime.parse(map['fecha']),
        clienteId: map['clienteId'],
        clienteNombre: map['clienteNombre'],
        items: (map['items'] as List<dynamic>? ?? [])
            .map((i) => ItemVenta.fromMap(i as Map<String, dynamic>))
            .toList(),
        total: (map['total'] ?? 0).toDouble(),
        metodoPago: map['metodoPago'] ?? 'Efectivo',
        estado: map['estado'] ?? 'completada',
      );
}
