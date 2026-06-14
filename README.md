<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Next.js-16-000000?style=for-the-badge&logo=next.js&logoColor=white" alt="Next.js">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript">
</div>

<br>

<div align="center">
  <h1>SmartVentas</h1>
  <p><strong>Gestión inteligente para tu negocio</strong></p>
  <p>Ecosistema completo de gestión empresarial: aplicación móvil Android + dashboard web.</p>
</div>

---

## 📋 Tabla de Contenidos

- [SmartVentas App (Flutter)](#smartventas-app-flutter)
  - [Características](#-características)
  - [Tecnologías](#-tecnologías)
  - [Estructura del Proyecto](#-estructura-del-proyecto)
  - [Instalación](#-instalación)
- [SmartVentas Web (Next.js)](#smartventas-web-nextjs)
  - [Características Web](#-características-web)
  - [Tecnologías Web](#-tecnologías-web)
  - [Estructura Web](#-estructura-web)
  - [Instalación Web](#-instalación-web)
- [Configuración de Firebase](#-configuración-de-firebase)
- [Roadmap](#-roadmap)
- [Licencia](#-licencia)

---

## SmartVentas App (Flutter)

Aplicación móvil Android para administrar inventarios, ventas, compras, cuentas por cobrar/pagar y generar reportes.

### ✨ Características

| Módulo | Funcionalidades |
|--------|----------------|
| **Dashboard** | Resumen de métricas clave: ventas hoy/semana, stock bajo, cuentas por cobrar/pagar, ganancia total |
| **Inventario** | CRUD de productos, búsqueda, filtro por categoría, filtro de stock bajo |
| **Ventas** | Registro de ventas con selección de productos, cálculo automático de total, métodos de pago |
| **Compras** | Registro de compras, actualización automática de stock y costos |
| **Cuentas por Cobrar** | Gestión de deudas de clientes, registro de pagos, estados |
| **Cuentas por Pagar** | Gestión de saldos con proveedores, registro de pagos |
| **Reportes** | Gráfica de ventas (7 días), ventas por categoría, top productos |
| **Autenticación** | Login, registro, recuperación de contraseña con Firebase Auth |
| **Notificaciones** | Alertas de stock bajo y vencimientos próximos vía FCM |

### 🛠 Tecnologías

| Tecnología | Propósito |
|------------|-----------|
| [Flutter](https://flutter.dev/) 3.11+ | Framework de UI multiplataforma |
| [Dart](https://dart.dev/) | Lenguaje de programación |
| [Firebase Auth](https://firebase.google.com/docs/auth) | Autenticación de usuarios |
| [Cloud Firestore](https://firebase.google.com/docs/firestore) | Base de datos NoSQL |
| [Firebase Messaging](https://firebase.google.com/docs/cloud-messaging) | Notificaciones push |
| [fl_chart](https://pub.dev/packages/fl_chart) | Gráficas interactivas |
| [API REST (HTTP)](https://pub.dev/packages/http) | Comunicación con backend dashboard |

### 🏗 Arquitectura

Patrón **MVVM** con `ChangeNotifier` + `ListenableBuilder`:

```
UI (Screens) → ViewModels (ChangeNotifier) → Services (Firebase + REST API) → Models
```

La app usa **Firestore** como almacenamiento principal (tiempo real, offline) y consume **API REST** del servidor web para métricas del dashboard como fallback optimizado.

### 📁 Estructura

```
lib/
├── main.dart
├── models/       # cliente, compra, producto, proveedor, venta
├── services/     # auth, fcm, firestore
├── viewmodels/   # lógica de negocio
├── views/        # pantallas
└── widgets/      # widgets reutilizables
```

### 🚀 Instalación

```bash
git clone https://github.com/MiguelAngelQH/App-gestion-de-inventario-y-ventas.git
cd App-gestion-de-inventario-y-ventas
flutter pub get
flutter run
```

---

## SmartVentas Web (Next.js)

Dashboard web para administración del negocio desde un navegador. Comparte la misma base de datos Firestore que la app móvil.

### ✨ Características Web

| Módulo | Funcionalidades |
|--------|----------------|
| **Dashboard** | Métricas clave: ventas del día, ganancias, productos con stock bajo |
| **Productos** | CRUD completo, búsqueda, filtro por categoría |
| **Ventas** | Registro con selección de productos y cálculo automático de total |
| **Compras** | Registro de compras con actualización de stock |
| **Clientes** | Gestión de deudas y pagos |
| **Proveedores** | Gestión de saldos y pagos |
| **Reportes** | Gráfica de ventas (7 días) y ventas por categoría |
| **Autenticación** | Login con Firebase Auth, sesión con JWT local |

### 🛠 Tecnologías Web

| Tecnología | Propósito |
|------------|-----------|
| [Next.js](https://nextjs.org/) 16 | Framework web full-stack |
| [TypeScript](https://www.typescriptlang.org/) | Lenguaje de programación |
| [Firebase Auth](https://firebase.google.com/docs/auth) | Autenticación de usuarios |
| [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup) | Acceso a Firestore desde el servidor |
| [jose](https://github.com/panva/jose) | JWT para sesiones locales |
| [Recharts](https://recharts.org/) | Gráficas interactivas |
| [Docker](https://www.docker.com/) | Contenerización para despliegue |

### 📁 Estructura Web

```
smart-ventas-web/
├── src/
│   ├── app/
│   │   ├── api/         # API routes (auth, dashboard, productos, ventas, compras, etc.)
│   │   ├── clientes/    # Página de clientes
│   │   ├── compras/     # Página de compras
│   │   ├── login/       # Página de inicio de sesión
│   │   ├── productos/   # Página de productos
│   │   ├── proveedores/ # Página de proveedores
│   │   ├── reportes/    # Página de reportes
│   │   └── ventas/      # Página de ventas
│   ├── components/      # Componentes reutilizables
│   ├── lib/             # Utilidades (auth, session, firebase-admin)
│   └── proxy.ts         # Middleware de autenticación
├── k8s/                 # Manifiestos Kubernetes
├── Dockerfile
└── package.json
```

### 🚀 Instalación Web

```bash
cd smart-ventas-web
npm install
npm run dev
```

#### Despliegue con Docker

```bash
docker build -t smart-ventas-web .
docker run -p 3000:3000 \
  -e FIREBASE_SERVICE_ACCOUNT_KEY='<JSON>' \
  -e NEXT_PUBLIC_FIREBASE_API_KEY='<KEY>' \
  smart-ventas-web
```

#### Despliegue en K3s

```bash
docker build -t zaynok/smart-ventas-web:vX .
docker push zaynok/smart-ventas-web:vX
kubectl set image deployment/smart-ventas-web web=zaynok/smart-ventas-web:vX -n 2023205111
```

---

## 🔧 Configuración de Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Habilita **Authentication** con el método **Correo electrónico/contraseña**
3. Habilita **Cloud Firestore** en modo de prueba
4. Habilita **Cloud Messaging** (FCM) para notificaciones
5. Para la app móvil: descarga `google-services.json` → `android/app/google-services.json`
6. Para la web: configura las variables de entorno con la API Key y Service Account
7. Despliega las reglas de seguridad de `firestore.rules` y los índices de `firestore.indexes.json`

---

## 🗺 Roadmap

### App Móvil
- [x] Autenticación de usuarios
- [x] CRUD de productos
- [x] Registro de ventas y compras
- [x] Cuentas por cobrar y pagar
- [x] Dashboard con métricas
- [x] Reportes con gráficas
- [x] Notificaciones push
- [x] API REST para dashboard (fallback desde servidor)
- [ ] Exportar reportes a PDF/Excel
- [ ] Modo oscuro completo
- [ ] Escáner de código de barras
- [ ] Múltiples sucursales
- [ ] Respaldo en la nube
- [ ] Versión iOS

### Web Dashboard
- [x] Autenticación con Firebase
- [x] Dashboard con métricas
- [x] CRUD de productos
- [x] Registro de ventas y compras
- [x] Gestión de clientes y proveedores
- [x] Reportes con gráficas
- [x] Filtro de ventas completadas en dashboard
- [x] Auto-refresh del dashboard (30s)
- [x] Soporte de zona horaria Ecuador (TZ)
- [ ] Exportar reportes a PDF
- [ ] Modo oscuro
- [ ] Panel de administración de usuarios

---

## 📄 Licencia

Proyecto de uso privado. Todos los derechos reservados.
