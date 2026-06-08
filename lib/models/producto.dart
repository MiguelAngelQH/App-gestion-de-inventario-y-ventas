class Producto {
  final String id;
  String nombre;
  String descripcion;
  double precio;
  double costo;
  int stock;
  String codigoBarras;
  String categoria;
  DateTime fechaCreacion;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.precio,
    required this.costo,
    this.stock = 0,
    this.codigoBarras = '',
    this.categoria = 'General',
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  double get ganancia => precio - costo;

  bool get stockBajo => stock <= 5;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'costo': costo,
        'stock': stock,
        'codigoBarras': codigoBarras,
        'categoria': categoria,
        'fechaCreacion': fechaCreacion.toIso8601String(),
      };

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
        id: map['id'],
        nombre: map['nombre'],
        descripcion: map['descripcion'] ?? '',
        precio: map['precio'],
        costo: map['costo'],
        stock: map['stock'],
        codigoBarras: map['codigoBarras'] ?? '',
        categoria: map['categoria'] ?? 'General',
        fechaCreacion: DateTime.parse(map['fechaCreacion']),
      );
}
