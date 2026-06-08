import 'package:flutter/material.dart';
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
import 'package:smart_ventas/views/forgot_password_screen.dart';
import 'package:smart_ventas/views/home_screen.dart';
import 'package:smart_ventas/views/register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthViewModel authViewModel;
  final ProductoViewModel productoViewModel;
  final VentaViewModel ventaViewModel;
  final CompraViewModel compraViewModel;
  final DashboardViewModel dashboardViewModel;
  final CobrarViewModel cobrarViewModel;
  final PagarViewModel pagarViewModel;
  final ReporteViewModel reporteViewModel;
  final ConfigViewModel configViewModel;

  const LoginScreen({
    super.key,
    required this.authViewModel,
    required this.productoViewModel,
    required this.ventaViewModel,
    required this.compraViewModel,
    required this.dashboardViewModel,
    required this.cobrarViewModel,
    required this.pagarViewModel,
    required this.reporteViewModel,
    required this.configViewModel,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.authViewModel.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            authViewModel: widget.authViewModel,
            productoViewModel: widget.productoViewModel,
            ventaViewModel: widget.ventaViewModel,
            compraViewModel: widget.compraViewModel,
            dashboardViewModel: widget.dashboardViewModel,
            cobrarViewModel: widget.cobrarViewModel,
            pagarViewModel: widget.pagarViewModel,
            reporteViewModel: widget.reporteViewModel,
            configViewModel: widget.configViewModel,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.authViewModel,
        builder: (context, _) {
          final error = widget.authViewModel.error;
          final isLoading = widget.authViewModel.isLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.store_rounded,
                            size: 44,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.appTagline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 48),
                        if (error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              error,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa tu correo';
                            }
                            if (!v.contains('@')) {
                              return 'Correo inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(
                                    authViewModel: widget.authViewModel,
                                  ),
                                ),
                              );
                            },
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: isLoading ? null : _login,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Iniciar Sesión'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('¿No tienes cuenta?'),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterScreen(
                                      authViewModel: widget.authViewModel,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Regístrate'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
