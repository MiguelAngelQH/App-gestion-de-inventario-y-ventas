class ItemCompra {
  String productoId;
  String productoNombre;
  String categoria;
  String presentacionId;
  String presentacionNombre;
  double factor;
  double cantidad;
  double costoUnitario;

  ItemCompra({
    required this.productoId,
    required this.productoNombre,
    required this.categoria,
    required this.presentacionId,
    required this.presentacionNombre,
    this.factor = 1,
    this.cantidad = 1,
    required this.costoUnitario,
  });

  double get subtotal => cantidad * costoUnitario;

  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'productoNombre': productoNombre,
        'categoria': categoria,
        'presentacionId': presentacionId,
        'presentacionNombre': presentacionNombre,
        'factor': factor,
        'cantidad': cantidad,
        'costoUnitario': costoUnitario,
        'subtotal': subtotal,
      };

  factory ItemCompra.fromMap(Map<String, dynamic> map) => ItemCompra(
        productoId: map['productoId'] ?? '',
        productoNombre: map['productoNombre'] ?? '',
        categoria: map['categoria'] ?? 'General',
        presentacionId: map['presentacionId'] ?? '',
        presentacionNombre: map['presentacionNombre'] ?? '',
        factor: (map['factor'] as num?)?.toDouble() ?? 1,
        cantidad: (map['cantidad'] as num?)?.toDouble() ?? 1,
        costoUnitario: (map['costoUnitario'] ?? 0).toDouble(),
      );
}

class Compra {
  final String id;
  DateTime fecha;
  String proveedorId;
  String proveedorNombre;
  List<ItemCompra> items;
  double total;
  String estado;

  Compra({
    required this.id,
    required this.fecha,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.items,
    required this.total,
    this.estado = 'pendiente',
  });

  String get folio {
    try {
      return 'C-${id.substring(0, 8).toUpperCase()}';
    } catch (_) {
      return 'C-XXXX';
    }
  }

  Map<String, dynamic> toMap() => {
        'fecha': fecha.toIso8601String(),
        'proveedorId': proveedorId,
        'proveedorNombre': proveedorNombre,
        'items': items.map((i) => i.toMap()).toList(),
        'total': total,
        'estado': estado,
      };

  factory Compra.fromMap(Map<String, dynamic> map) => Compra(
        id: map['id'] ?? '',
        fecha: DateTime.parse(map['fecha']),
        proveedorId: map['proveedorId'] ?? '',
        proveedorNombre: map['proveedorNombre'] ?? '',
        items: (map['items'] as List<dynamic>? ?? [])
            .map((i) => ItemCompra.fromMap(i as Map<String, dynamic>))
            .toList(),
        total: (map['total'] ?? 0).toDouble(),
        estado: map['estado'] ?? 'pendiente',
      );
}
