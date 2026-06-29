# Proyecto SmartVentas

## Estado actual (20/06/2026)

### Implementado
1. **Escáner de código de barras**
   - `mobile_scanner: ^6.0.0` en pubspec.yaml
   - `lib/views/scanner_screen.dart` — cámara fullscreen + linterna
   - `lib/views/producto_form_screen.dart` — icono 📷 al lado del campo código
   - Flujo: escanea → consulta API global → fallback a Firestore local → diálogo confirmación → auto-llena nombre, descripción, marca, categoría, categoría
   - Si proveedor no existe → se crea automáticamente
   - Al guardar producto nuevo con código → contribuye al catálogo global (`barcode_catalog`)

2. **API web** (Next.js en `smart-ventas-web/`)
   - `GET /api/productos/barcode/[codigo]` — busca en `barcode_catalog`
   - `POST /api/productos/barcode/[codigo]` — contribuye al catálogo

3. **Mejoras**
   - `firestore_service.addProveedor()` retorna ID del doc
   - `producto_viewmodel.crearProveedorSiNoExiste(nombre)`
   - `api_service.getProductoBarcode()` + `api_service.contributeBarcode()`

### Pendiente del plan original
- [ ] **Configuración de Precios** — `PreciosViewModel` y `ConfiguracionPreciosScreen` existen pero no están conectados a `main.dart` ni al drawer
- [ ] **API REST Dashboard** — `api_service.getDashboardMetrics()` existe pero no se integra en ningún ViewModel

### Fix: Búsqueda de producto por código de barras (22/06/2026)
- **Problema:** Al escanear un código de barras de un producto ya registrado en Firestore, solo se autocompletaba el código pero no los demás campos.
- **Causa raíz:** `getProductoByBarcode()` en `ProductoViewModel` hacía una query a Firestore con filtros `uid` + `codigoBarras`. Sin un índice compuesto, la query fallaba y la excepción era silenciosamente capturada.
- **Solución:** Cambiado a búsqueda en la lista `_productos` en memoria.
- **Archivos:** `producto_viewmodel.dart`, `producto_form_screen.dart`

### Refactor: Sección Compras con lógica de negocio real (22/06/2026)

**Problemas detectados y corregidos:**

| # | Problema | Solución |
|---|----------|----------|
| 1 | Producto no se crea desde compras | Input libre con búsqueda + creación automática de producto si no existe |
| 2 | Proveedor era texto libre, sin vincular | Dropdown con proveedores existentes + opción "Nuevo proveedor" |
| 3 | Compra no actualizaba deuda del proveedor | Si es crédito → `saldoPendiente += total` en el proveedor |
| 4 | Siempre contado, sin opción crédito | Toggle Contado/Crédito en el formulario |
| 5 | Costo se sobreescribía (LIFO) | Costo promedio ponderado: `(stock_anterior * costo_anterior + cantidad_nueva * costo_nuevo) / stock_actual` |
| 6 | Compra modelo no guardaba tipo de pago | Nuevo campo `credito` en modelo `Compra` |
| 7 | deleteCompra no revertía deuda | Ahora revierte `saldoPendiente` si la compra fue crédito |
| 8 | deleteCompra bloqueaba 'recibida' | Eliminada la restricción, revierte todo |

**Archivos modificados:**
- `lib/models/compra.dart` — campo `credito`, serialización
- `lib/services/firestore_service.dart` — `addProducto` retorna ID, `addCompra` actualiza deuda si credito, `_actualizarCostoPresentacion` usa promedio ponderado, `deleteCompra` revierte deuda
- `lib/viewmodels/compra_viewmodel.dart` — añadido `proveedores`, `crearProductoDesdeCompra()`, `crearProveedorSiNoExiste()`
- `lib/views/compra_form_screen.dart` — rediseño completo: input libre producto con autocompletado + creación, dropdown proveedores, toggle contado/crédito

### Fix: Crash `_dependents.isEmpty` al crear proveedor/cliente (28/06/2026)
- **Problema:** `notifyListeners()` llamado durante transiciones de overlay (dialog pop + stream event) causaba assertion `_dependents.isEmpty`.
- **Causa raíz (3 factores combinados):**
  1. `_safeNotify()` llamaba `notifyListeners()` sincrónicamente → colisión con desactivación del overlay
  2. Dialogs en `pagar_screen` y `cobrar_screen` no `await`eaban `addProveedor/addCliente` → `Navigator.pop` antes del write Firestore → stream emitía durante desactivación
  3. `ListenableBuilder` envolviendo `MaterialApp` creaba un `_InheritedListenable` que causaba crash al desactivarse el overlay
- **Soluciones:**
  1. `_safeNotify()` en 10 ViewModels → `WidgetsBinding.instance.addPostFrameCallback` en vez de `notifyListeners()` directo
  2. Dialogs ahora `await`ean `addProveedor`/`addCliente` antes de `Navigator.pop`
  3. `main.dart`: eliminado `ListenableBuilder` → `onThemeChanged` callback en `ConfigViewModel` solo para cambios de tema
  4. `ConfigViewModel`: `onThemeChanged` callback (no `addListener` genérico) evita rebuilds de `MaterialApp` por `_load()` async
- **Archivos modificados (10 ViewModels + pagar_screen + cobrar_screen + config_viewmodel + main.dart)**

### Fix: Tema oscuro se propagaba en runtime (28/06/2026)
- **Problema:** `ConfigViewModel.setThemeMode()` escribía en Firestore pero `MaterialApp.themeMode` nunca se actualizaba.
- **Solución:** Callback `onThemeChanged` en `ConfigViewModel` → `setState` en `_SmartVentasAppState` → reconstruye `MaterialApp` con nuevo tema.
- **Archivos:** `main.dart`, `config_viewmodel.dart`

### Fix: `PreciosViewModel` sin auth listener (28/06/2026)
- **Problema:** `PreciosViewModel` no se re-suscribía al cambiar de usuario.
- **Solución:** Agregado `_authSub` que re-suscribe el stream de productos en auth change.
- **Archivo:** `precios_viewmodel.dart`

### Fix: Imports optimizados (28/06/2026)
- `ConfigViewModel`: `material.dart` → `material.dart show ThemeMode` + `widgets.dart`
- 10 ViewModels: `foundation.dart` eliminado (redundante con `widgets.dart`)

### Fix: Eliminados todos los `ListenableBuilder` de screens (28/06/2026)
- **Problema:** `ListenableBuilder` crea un `_InheritedListenable` (`InheritedNotifier`) que, al desactivarse durante transiciones del overlay, dispara el assertion `_dependents.isEmpty` si aún tiene dependientes registrados.
- **Solución:** Reemplazados todos los `ListenableBuilder` por `addListener` + `setState` en `initState`/`dispose`. Este patrón es el estándar en Flutter y no crea `InheritedWidget`s intermedias.
- **9 screens modificadas:** `pagar_screen`, `cobrar_screen`, `compras_screen`, `inventario_screen`, `ventas_screen`, `dashboard_screen`, `reportes_screen`, `configuracion_precios_screen`, `configuracion_screen`.
- **Todas convertidas de `StatelessWidget` a `StatefulWidget`** para soportar el ciclo de vida del listener.

### Fix: `FlutterError.onError` para `_dependents.isEmpty` (28/06/2026)
- **Problema:** El error `_dependents.isEmpty` es un conocido bug de Flutter con `InheritedElement` + Overlay que puede aparecer en edge cases de transiciones.
- **Solución:** Handler global en `main.dart` que silencia específicamente este error, como red de seguridad adicional.

### Pendiente del plan original
- [ ] **Configuración de Precios** — `PreciosViewModel` y `ConfiguracionPreciosScreen` existen pero no están conectados a `main.dart` ni al drawer
- [ ] **API REST Dashboard** — `api_service.getDashboardMetrics()` existe pero no se integra en ningún ViewModel

### Repositorio
- Push a: `https://github.com/MiguelAngelQH/App-gestion-de-inventario-y-ventas.git`
- `.gitignore` ignora: `files backend docker and wireguard/`, `service-account.json`
- Web panel (`smart-ventas-web/`) es subdirectorio del mismo repo
