class AppConstants {
  static const String appName = 'SmartVentas';
  static const String appTagline = 'Gestión inteligente para tu negocio';
  static const String appVersion = '1.2.0';

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

  // URL del servidor web para reportes avanzados (dashboard vía API).
  // Se puede configurar con --dart-define=SERVER_URL=http://xxx
  static String get apiBaseUrl {
    const defaultUrl = 'http://172.16.10.31:30349';
    try {
      return const String.fromEnvironment('SERVER_URL',
          defaultValue: defaultUrl);
    } catch (_) {
      return defaultUrl;
    }
  }
}
