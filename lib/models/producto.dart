class Presentacion {
  String id;
  String nombreVisual;
  String unidad;
  double precio;
  double costo;
  double factor;

  Presentacion({
    String? id,
    required this.nombreVisual,
    required this.unidad,
    required this.precio,
    required this.costo,
    required this.factor,
  }) : id = id ?? '';

  double get ganancia => precio - costo;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombreVisual': nombreVisual,
        'unidad': unidad,
        'precio': precio,
        'costo': costo,
        'factor': factor,
      };

  factory Presentacion.fromMap(Map<String, dynamic> map) => Presentacion(
        id: map['id'] ?? '',
        nombreVisual: map['nombreVisual'] ?? '',
        unidad: map['unidad'] ?? 'unidad',
        precio: (map['precio'] as num?)?.toDouble() ?? 0,
        costo: (map['costo'] as num?)?.toDouble() ?? 0,
        factor: (map['factor'] as num?)?.toDouble() ?? 1,
      );

  Presentacion copyWith({
    String? nombreVisual,
    String? unidad,
    double? precio,
    double? costo,
    double? factor,
  }) =>
      Presentacion(
        id: id,
        nombreVisual: nombreVisual ?? this.nombreVisual,
        unidad: unidad ?? this.unidad,
        precio: precio ?? this.precio,
        costo: costo ?? this.costo,
        factor: factor ?? this.factor,
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
  String unidadBase;
  double stockTotal;
  double precio;
  double costo;
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
    required this.unidadBase,
    this.stockTotal = 0,
    this.precio = 0,
    this.costo = 0,
    List<Presentacion>? presentaciones,
    DateTime? fechaCreacion,
  })  : presentaciones = presentaciones ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  bool get stockBajo => stockTotal <= 5;
  double get ganancia => precio - costo;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'codigoBarras': codigoBarras,
        'categoria': categoria,
        'marca': marca,
        'proveedorId': proveedorId,
        'proveedorNombre': proveedorNombre,
        'unidadBase': unidadBase,
        'stockTotal': stockTotal,
        'precio': precio,
        'costo': costo,
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
      unidadBase: map['unidadBase'] ?? 'unidad',
      stockTotal: (map['stockTotal'] as num?)?.toDouble() ??
          (map['stock'] as num?)?.toDouble() ??
          0,
      precio: (map['precio'] as num?)?.toDouble() ?? 0,
      costo: (map['costo'] as num?)?.toDouble() ?? 0,
      presentaciones: presentacionesRaw
              ?.map((p) => Presentacion.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
    );
  }
}
