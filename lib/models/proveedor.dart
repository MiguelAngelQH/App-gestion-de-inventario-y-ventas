class Proveedor {
  final String id;
  String nombre;
  String telefono;
  String email;
  String direccion;
  double saldoPendiente;
  String estado;
  DateTime? fechaVencimiento;

  Proveedor({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.email = '',
    this.direccion = '',
    this.saldoPendiente = 0,
    this.estado = 'pendiente',
    this.fechaVencimiento,
  });

  bool get vencido =>
      estado == 'pendiente' &&
      fechaVencimiento != null &&
      fechaVencimiento!.isBefore(DateTime.now());

  Proveedor copyWith({
    String? nombre,
    String? telefono,
    String? email,
    String? direccion,
    double? saldoPendiente,
    String? estado,
    DateTime? fechaVencimiento,
  }) =>
      Proveedor(
        id: id,
        nombre: nombre ?? this.nombre,
        telefono: telefono ?? this.telefono,
        email: email ?? this.email,
        direccion: direccion ?? this.direccion,
        saldoPendiente: saldoPendiente ?? this.saldoPendiente,
        estado: estado ?? this.estado,
        fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'email': email,
        'direccion': direccion,
        'saldoPendiente': saldoPendiente,
        'estado': estado,
        'fechaVencimiento': fechaVencimiento?.toIso8601String(),
      };

  factory Proveedor.fromMap(Map<String, dynamic> map) => Proveedor(
        id: map['id'],
        nombre: map['nombre'],
        telefono: map['telefono'] ?? '',
        email: map['email'] ?? '',
        direccion: map['direccion'] ?? '',
        saldoPendiente: (map['saldoPendiente'] ?? 0).toDouble(),
        estado: map['estado'] ?? 'pendiente',
        fechaVencimiento: map['fechaVencimiento'] != null
            ? DateTime.parse(map['fechaVencimiento'])
            : null,
      );
}
