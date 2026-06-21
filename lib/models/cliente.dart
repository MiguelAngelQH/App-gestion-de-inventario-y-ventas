class Cliente {
  final String id;
  String nombre;
  String telefono;
  String email;
  String direccion;
  double deuda;
  String estado;
  DateTime? fechaVencimiento;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.email = '',
    this.direccion = '',
    this.deuda = 0,
    this.estado = 'pendiente',
    this.fechaVencimiento,
  });

  bool get vencido =>
      estado == 'pendiente' &&
      fechaVencimiento != null &&
      fechaVencimiento!.isBefore(DateTime.now());

  Cliente copyWith({
    String? nombre,
    String? telefono,
    String? email,
    String? direccion,
    double? deuda,
    String? estado,
    DateTime? fechaVencimiento,
  }) =>
      Cliente(
        id: id,
        nombre: nombre ?? this.nombre,
        telefono: telefono ?? this.telefono,
        email: email ?? this.email,
        direccion: direccion ?? this.direccion,
        deuda: deuda ?? this.deuda,
        estado: estado ?? this.estado,
        fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'email': email,
        'direccion': direccion,
        'deuda': deuda,
        'estado': estado,
        'fechaVencimiento': fechaVencimiento?.toIso8601String(),
      };

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
        id: map['id'],
        nombre: map['nombre'],
        telefono: map['telefono'] ?? '',
        email: map['email'] ?? '',
        direccion: map['direccion'] ?? '',
        deuda: (map['deuda'] ?? 0).toDouble(),
        estado: map['estado'] ?? 'pendiente',
        fechaVencimiento: map['fechaVencimiento'] != null
            ? DateTime.parse(map['fechaVencimiento'])
            : null,
      );
}
