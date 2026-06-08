<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/v1.0.0-4CAF50?style=for-the-badge&logo=&logoColor=white" alt="Version">
</div>

<br>

<div align="center">
  <h1>SmartVentas</h1>
  <p><strong>Gestión inteligente para tu negocio</strong></p>
  <p>Aplicación móvil todo-en-uno para administrar inventarios, ventas, compras, cuentas por cobrar/pagar y generar reportes desde tu dispositivo Android.</p>
</div>

---

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Capturas de Pantalla](#-capturas-de-pantalla)
- [Tecnologías](#-tecnologías)
- [Arquitectura](#-arquitectura)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Modelos de Datos](#-modelos-de-datos)
- [Instalación](#-instalación)
- [Configuración de Firebase](#-configuración-de-firebase)
- [Uso](#-uso)
- [Roadmap](#-roadmap)
- [Licencia](#-licencia)

---

## ✨ Características

| Módulo | Funcionalidades |
|--------|----------------|
| **Dashboard** | Resumen de métricas clave: ventas hoy/semana, stock bajo, cuentas por cobrar/pagar, ganancia total |
| **Inventario** | CRUD de productos, búsqueda, filtro por categoría, filtro de stock bajo |
| **Ventas** | Registro de ventas con selección de productos, cálculo automático de total, métodos de pago |
| **Compras** | Registro de compras, actualización automática de stock y costos |
| **Cuentas por Cobrar** | Gestión de deudas de clientes, registro de pagos, estados (pendiente/pagado/vencido) |
| **Cuentas por Pagar** | Gestión de saldos con proveedores, registro de pagos |
| **Reportes** | Gráfica de ventas (7 días), ventas por categoría, top productos, métricas completas |
| **Autenticación** | Login, registro, recuperación de contraseña con Firebase Auth |
| **Notificaciones** | Alertas de stock bajo y vencimientos próximos vía FCM |
| **Configuración** | Datos del negocio, preferencias, tema, versión |

---

## 📸 Capturas de Pantalla

> _Próximamente_

---

## 🛠 Tecnologías

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| [Flutter](https://flutter.dev/) | 3.11+ | Framework de UI multiplataforma |
| [Dart](https://dart.dev/) | 3.11+ | Lenguaje de programación |
| [Firebase Auth](https://firebase.google.com/docs/auth) | ^5.5.1 | Autenticación de usuarios |
| [Cloud Firestore](https://firebase.google.com/docs/firestore) | ^5.6.5 | Base de datos NoSQL en tiempo real |
| [Firebase Messaging](https://firebase.google.com/docs/cloud-messaging) | ^15.2.4 | Notificaciones push |
| [fl_chart](https://pub.dev/packages/fl_chart) | ^0.70.2 | Gráficas interactivas |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | ^18.0.1 | Notificaciones locales |
| [uuid](https://pub.dev/packages/uuid) | ^4.5.1 | Generación de IDs únicos |

---

## 🏗 Arquitectura

El proyecto sigue el patrón **MVVM (Model-View-ViewModel)** con una capa de servicios para el acceso a datos:

```
UI (Screens)
    ↓  escucha cambios mediante ListenableBuilder
ViewModels (ChangeNotifier)
    ↓  llama métodos de servicio
Services (Firebase)
    ↓  opera sobre
Models (Dart Classes)
```

- **State Management**: `ChangeNotifier` + `ListenableBuilder` (nativo, sin dependencias externas)
- **Base de datos**: Firestore con consultas en tiempo real (`snapshots()`)
- **Aislamiento de datos**: Cada documento contiene un campo `uid` para multi-tenencia por usuario
- **Reglas de seguridad**: Validación de propiedad de datos en Firestore Security Rules

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── models/                      # Modelos de datos
│   ├── cliente.dart
│   ├── compra.dart
│   ├── producto.dart
│   ├── proveedor.dart
│   ├── usuario.dart
│   └── venta.dart
├── services/                    # Capa de servicios
│   ├── auth_service.dart        # Firebase Authentication
│   ├── fcm_service.dart         # Notificaciones push
│   ├── firestore_service.dart   # CRUD + consultas Firestore
│   └── mock_data_service.dart   # Datos de prueba
├── utils/                       # Utilidades
│   ├── constants.dart           # Constantes de la app
│   └── formatters.dart          # Formateo de moneda/fechas
├── viewmodels/                  # Lógica de negocio
│   ├── auth_viewmodel.dart
│   ├── cobrar_viewmodel.dart
│   ├── compra_viewmodel.dart
│   ├── dashboard_viewmodel.dart
│   ├── pagar_viewmodel.dart
│   ├── producto_viewmodel.dart
│   ├── reporte_viewmodel.dart
│   └── venta_viewmodel.dart
├── views/                       # Pantallas
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── inventario_screen.dart
│   ├── producto_form_screen.dart
│   ├── ventas_screen.dart
│   ├── venta_form_screen.dart
│   ├── compras_screen.dart
│   ├── compra_form_screen.dart
│   ├── cobrar_screen.dart
│   ├── pagar_screen.dart
│   ├── reportes_screen.dart
│   └── configuracion_screen.dart
└── widgets/                     # Widgets reutilizables
    └── reusable_widgets.dart
```

---

## 📦 Modelos de Datos

### Producto
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | `String` | Identificador único |
| `nombre` | `String` | Nombre del producto |
| `descripcion` | `String` | Descripción opcional |
| `precio` | `double` | Precio de venta |
| `costo` | `double` | Costo unitario |
| `stock` | `int` | Cantidad en inventario |
| `categoria` | `String` | Categoría (General, Alimentos, etc.) |
| `codigoBarras` | `String` | Código de barras opcional |

### Venta + ItemVenta
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | `String` | Folio único (V-XXXX) |
| `fecha` | `DateTime` | Fecha de venta |
| `items` | `List<ItemVenta>` | Productos vendidos |
| `total` | `double` | Monto total |
| `metodoPago` | `String` | Efectivo, Tarjeta, Transferencia, etc. |
| `estado` | `String` | Completada / Pendiente / Cancelada |

### Compra + ItemCompra
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | `String` | Folio único (C-XXXX) |
| `fecha` | `DateTime` | Fecha de compra |
| `items` | `List<ItemCompra>` | Productos comprados |
| `total` | `double` | Monto total |
| `estado` | `String` | Pendiente / Recibida / Cancelada |

### Cliente / Proveedor
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | `String` | Identificador único |
| `nombre` | `String` | Nombre o razón social |
| `telefono` | `String` | Teléfono de contacto |
| `deuda` / `saldoPendiente` | `double` | Saldo actual |
| `estado` | `String` | Pendiente / Pagado / Vencido |

---

## 🚀 Instalación

### Requisitos

- Flutter SDK 3.11 o superior
- Dart SDK 3.11 o superior
- Cuenta de Firebase con proyecto activo
- Android Studio / VS Code

### Pasos

```bash
# Clonar el repositorio
git clone https://github.com/MiguelAngelQH/App-gestion-de-inventario-y-ventas.git
cd App-gestion-de-inventario-y-ventas

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run
```

---

## 🔧 Configuración de Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Habilita **Authentication** con el método **Correo electrónico/contraseña**
3. Habilita **Cloud Firestore** en modo de prueba
4. Habilita **Cloud Messaging** (FCM) para notificaciones
5. Descarga el archivo `google-services.json` y colócalo en:
   ```
   android/app/google-services.json
   ```
6. Despliega las reglas de seguridad de `firestore.rules` y los índices de `firestore.indexes.json`

---

## 📱 Uso

1. **Regístrate** con tu correo electrónico y contraseña
2. **Agrega productos** desde la sección de Inventario
3. **Registra ventas** seleccionando productos y método de pago
4. **Administra compras** para reponer inventario
5. **Gestiona cuentas** por cobrar y pagar
6. **Consulta reportes** con métricas y gráficas

---

## 🗺 Roadmap

- [x] Autenticación de usuarios
- [x] CRUD de productos
- [x] Registro de ventas y compras
- [x] Cuentas por cobrar y pagar
- [x] Dashboard con métricas
- [x] Reportes con gráficas
- [x] Notificaciones push
- [ ] Exportar reportes a PDF/Excel
- [ ] Modo oscuro completo
- [ ] Escáner de código de barras
- [ ] Múltiples sucursales
- [ ] Respaldo en la nube
- [ ] Versión iOS

---

## 📄 Licencia

Este proyecto es de uso privado. Todos los derechos reservados.
