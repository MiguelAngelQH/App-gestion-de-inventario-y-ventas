import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_ventas/services/fcm_service.dart';
import 'package:smart_ventas/services/firestore_service.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/viewmodels/auth_viewmodel.dart';
import 'package:smart_ventas/viewmodels/cobrar_viewmodel.dart';
import 'package:smart_ventas/viewmodels/compra_viewmodel.dart';
import 'package:smart_ventas/viewmodels/config_viewmodel.dart';
import 'package:smart_ventas/viewmodels/dashboard_viewmodel.dart';
import 'package:smart_ventas/viewmodels/pagar_viewmodel.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/viewmodels/reporte_viewmodel.dart';
import 'package:smart_ventas/viewmodels/venta_viewmodel.dart';
import 'package:smart_ventas/views/home_screen.dart';
import 'package:smart_ventas/views/login_screen.dart';
import 'package:smart_ventas/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    if (details.exception
        .toString()
        .contains("_dependents.isEmpty")) {
      return;
    }
    FlutterError.presentError(details);
  };

  await Firebase.initializeApp();
  await FcmService().init();

  ThemeMode initialThemeMode = ThemeMode.light;
  try {
    final firestore = FirestoreService();
    final configData = await firestore.getConfig();
    final themeStr = configData['themeMode'] as String?;
    initialThemeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
  } catch (_) {}

  runApp(SmartVentasApp(initialThemeMode: initialThemeMode));
}

class SmartVentasApp extends StatefulWidget {
  const SmartVentasApp({super.key, required this.initialThemeMode});

  final ThemeMode initialThemeMode;

  @override
  State<SmartVentasApp> createState() => _SmartVentasAppState();
}

class _SmartVentasAppState extends State<SmartVentasApp> {
  final _appKey = GlobalKey();
  bool _splashComplete = false;

  final _authViewModel = AuthViewModel();
  final _productoViewModel = ProductoViewModel();
  final _ventaViewModel = VentaViewModel();
  final _compraViewModel = CompraViewModel();
  final _configViewModel = ConfigViewModel();
  late final _dashboardViewModel = DashboardViewModel(configVM: _configViewModel);
  final _cobrarViewModel = CobrarViewModel();
  final _pagarViewModel = PagarViewModel();
  final _reporteViewModel = ReporteViewModel();

  @override
  void initState() {
    super.initState();
    _configViewModel.onThemeChanged = () {
      if (mounted) setState(() {});
    };
  }

  void _onSplashComplete() {
    setState(() {
      _splashComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: _appKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: _configViewModel.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: _splashComplete
          ? (_authViewModel.isAuthenticated
              ? HomeScreen(
                  authViewModel: _authViewModel,
                  productoViewModel: _productoViewModel,
                  ventaViewModel: _ventaViewModel,
                  compraViewModel: _compraViewModel,
                  dashboardViewModel: _dashboardViewModel,
                  cobrarViewModel: _cobrarViewModel,
                  pagarViewModel: _pagarViewModel,
                  reporteViewModel: _reporteViewModel,
                  configViewModel: _configViewModel,
                )
              : LoginScreen(
                  authViewModel: _authViewModel,
                  productoViewModel: _productoViewModel,
                  ventaViewModel: _ventaViewModel,
                  compraViewModel: _compraViewModel,
                  dashboardViewModel: _dashboardViewModel,
                  cobrarViewModel: _cobrarViewModel,
                  pagarViewModel: _pagarViewModel,
                  reporteViewModel: _reporteViewModel,
                  configViewModel: _configViewModel,
                ))
          : SplashScreen(
              authViewModel: _authViewModel,
              onSplashComplete: _onSplashComplete,
            ),
    );
  }

  static const _primaryColor = Color(0xFF00695C);
  static const _secondaryColor = Color(0xFFFF8F00);
  static const _tertiaryColor = Color(0xFF7B1FA2);

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFB2DFDB),
      onPrimaryContainer: const Color(0xFF00251A),
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFFECB3),
      onSecondaryContainer: const Color(0xFF3E2723),
      tertiary: _tertiaryColor,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE1BEE7),
      surface: Colors.white,
      onSurface: const Color(0xFF1C1B1F),
      surfaceContainerLow: const Color(0xFFF5F5F5),
      surfaceContainerHighest: const Color(0xFFE8E8E8),
      error: const Color(0xFFD32F2F),
      outlineVariant: const Color(0xFFCAC4D0),
    );

    return _buildThemeData(colorScheme);
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.dark(
      primary: const Color(0xFF80CBC4),
      onPrimary: const Color(0xFF00382A),
      primaryContainer: const Color(0xFF005043),
      onPrimaryContainer: const Color(0xFFB2DFDB),
      secondary: const Color(0xFFFFD54F),
      onSecondary: const Color(0xFF3E2723),
      secondaryContainer: const Color(0xFF5D4037),
      onSecondaryContainer: const Color(0xFFFFECB3),
      tertiary: const Color(0xFFCE93D8),
      onTertiary: const Color(0xFF3E1A5E),
      tertiaryContainer: const Color(0xFF5C2E7A),
      surface: const Color(0xFF1C1B1F),
      onSurface: const Color(0xFFE6E1E5),
      surfaceContainerLow: const Color(0xFF252529),
      surfaceContainerHighest: const Color(0xFF38383B),
      error: const Color(0xFFEF5350),
      outlineVariant: const Color(0xFF49454F),
    );

    return _buildThemeData(colorScheme);
  }

  ThemeData _buildThemeData(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 4,
        height: 68,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
              letterSpacing: 0.2,
            );
          }
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              size: 24,
              color: colorScheme.primary,
            );
          }
          return IconThemeData(
            size: 22,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        extendedIconLabelSpacing: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 0.5,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
