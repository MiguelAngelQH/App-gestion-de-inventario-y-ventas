class ItemVenta {
  String productoId;
  String productoNombre;
  String categoria;
  String presentacionId;
  String presentacionNombre;
  double cantidad;
  double precioUnitario;
  double costoUnitario;

  ItemVenta({
    required this.productoId,
    required this.productoNombre,
    required this.categoria,
    required this.presentacionId,
    required this.presentacionNombre,
    this.cantidad = 1,
    required this.precioUnitario,
    this.costoUnitario = 0,
  });

  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'productoNombre': productoNombre,
        'categoria': categoria,
        'presentacionId': presentacionId,
        'presentacionNombre': presentacionNombre,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'subtotal': subtotal,
        'costoUnitario': costoUnitario,
      };

  factory ItemVenta.fromMap(Map<String, dynamic> map) => ItemVenta(
        productoId: map['productoId'] ?? '',
        productoNombre: map['productoNombre'] ?? '',
        categoria: map['categoria'] ?? 'General',
        presentacionId: map['presentacionId'] ?? '',
        presentacionNombre: map['presentacionNombre'] ?? '',
        cantidad: (map['cantidad'] as num?)?.toDouble() ?? 1,
        precioUnitario: (map['precioUnitario'] ?? 0).toDouble(),
        costoUnitario: (map['costoUnitario'] ?? 0).toDouble(),
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
