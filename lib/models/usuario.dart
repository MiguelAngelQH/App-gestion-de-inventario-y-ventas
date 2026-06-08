class Usuario {
  final String uid;
  final String email;
  final String? nombre;
  final String? fotoUrl;
  final DateTime? fechaCreacion;

  Usuario({
    required this.uid,
    required this.email,
    this.nombre,
    this.fotoUrl,
    this.fechaCreacion,
  });

  String get inicial {
    final src = (nombre ?? email);
    if (src.isEmpty) return '?';
    return src[0].toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'nombre': nombre,
        'fotoUrl': fotoUrl,
      };
}
