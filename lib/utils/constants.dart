class AppConstants {
  static const String appName = 'SmartVentas';
  static const String appTagline = 'Gestión inteligente para tu negocio';
  static const String appVersion = '1.0.0';

  static const List<String> categorias = [
    'General',
    'Alimentos',
    'Bebidas',
    'Limpieza',
    'Higiene',
    'Ropa',
    'Electrónicos',
    'Hogar',
    'Ferretería',
    'Papelería',
  ];

  static const List<String> metodosPago = [
    'Efectivo',
    'Tarjeta Débito',
    'Tarjeta Crédito',
    'Transferencia',
    'Depósito',
  ];

  static const List<String> estadosVenta = [
    'completada',
    'pendiente',
    'cancelada',
  ];

  static const List<String> estadosCompra = [
    'pendiente',
    'recibida',
    'cancelada',
  ];

  static const int splashDuration = 2;
}
