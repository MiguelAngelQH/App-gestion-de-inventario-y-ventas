class Presentacion {
  String id;
  String nombre;
  String unidad;
  double precio;
  double costo;
  double stock;

  Presentacion({
    String? id,
    required this.nombre,
    required this.unidad,
    required this.precio,
    required this.costo,
    this.stock = 0,
  }) : id = id ?? '';

  double get ganancia => precio - costo;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'unidad': unidad,
        'precio': precio,
        'costo': costo,
        'stock': stock,
      };

  factory Presentacion.fromMap(Map<String, dynamic> map) => Presentacion(
        id: map['id'] ?? '',
        nombre: map['nombre'] ?? map['nombreVisual'] ?? '',
        unidad: map['unidad'] ?? 'unidad',
        precio: (map['precio'] as num?)?.toDouble() ?? 0,
        costo: (map['costo'] as num?)?.toDouble() ?? 0,
        stock: (map['stock'] as num?)?.toDouble() ?? 0,
      );

  Presentacion copyWith({
    String? nombre,
    String? unidad,
    double? precio,
    double? costo,
    double? stock,
  }) =>
      Presentacion(
        id: id,
        nombre: nombre ?? this.nombre,
        unidad: unidad ?? this.unidad,
        precio: precio ?? this.precio,
        costo: costo ?? this.costo,
        stock: stock ?? this.stock,
      );
}

class Producto {
  final String id;
  String nombre;
  String descripcion;
  String codigoBarras;
  String categoria;
  String marca;
  String proveedorId;
  String proveedorNombre;
  List<Presentacion> presentaciones;
  DateTime fechaCreacion;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    this.codigoBarras = '',
    this.categoria = 'General',
    this.marca = '',
    this.proveedorId = '',
    this.proveedorNombre = '',
    List<Presentacion>? presentaciones,
    DateTime? fechaCreacion,
  })  : presentaciones = presentaciones ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  double get stockTotal => presentaciones.fold(0, (s, p) => s + p.stock);
  bool get stockBajo => stockTotal <= 5;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'codigoBarras': codigoBarras,
        'categoria': categoria,
        'marca': marca,
        'proveedorId': proveedorId,
        'proveedorNombre': proveedorNombre,
        'stockTotal': stockTotal,
        'presentaciones': presentaciones.map((p) => p.toMap()).toList(),
        'fechaCreacion': fechaCreacion.toIso8601String(),
      };

  factory Producto.fromMap(Map<String, dynamic> map) {
    final presentacionesRaw = map['presentaciones'] as List<dynamic>?;
    return Producto(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      codigoBarras: map['codigoBarras'] ?? '',
      categoria: map['categoria'] ?? 'General',
      marca: map['marca'] ?? '',
      proveedorId: map['proveedorId'] ?? '',
      proveedorNombre: map['proveedorNombre'] ?? '',
      presentaciones: presentacionesRaw
              ?.map((p) => Presentacion.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
    );
  }
}
