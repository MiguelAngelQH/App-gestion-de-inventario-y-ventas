import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_ventas/services/fcm_service.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/viewmodels/config_viewmodel.dart';
import 'package:smart_ventas/viewmodels/precios_viewmodel.dart';
import 'package:smart_ventas/views/configuracion_precios_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  final ConfigViewModel viewModel;

  const ConfiguracionScreen({super.key, required this.viewModel});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  String? _token;
  bool _copiado = false;
  late final PreciosViewModel _preciosVM;

  @override
  void initState() {
    super.initState();
    _token = FcmService().token;
    FcmService().onTokenChanged = (t) {
      if (mounted) setState(() => _token = t);
    };
    _preciosVM = PreciosViewModel();
  }

  @override
  void dispose() {
    _preciosVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Información de la Empresa',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('Nombre del Negocio'),
                      subtitle: Text(vm.businessName),
                      trailing: const Icon(Icons.edit),
                      onTap: () =>
                          _editarTexto(context, 'Nombre del Negocio',
                              vm.businessName, vm.setBusinessName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.pin_drop),
                      title: const Text('Dirección'),
                      subtitle:
                          Text(vm.address.isEmpty ? 'Agregar dirección' : vm.address),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _editarTexto(
                          context, 'Dirección', vm.address, vm.setAddress),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Teléfono'),
                      subtitle:
                          Text(vm.phone.isEmpty ? 'Agregar teléfono' : vm.phone),
                      trailing: const Icon(Icons.edit),
                      onTap: () =>
                          _editarTexto(context, 'Teléfono', vm.phone, vm.setPhone),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Productos',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.price_change_outlined),
                      title: const Text('Configuración de Precios'),
                      subtitle: const Text('Editar precios y costos de todas las presentaciones'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConfiguracionPreciosScreen(
                            viewModel: _preciosVM,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Preferencias',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Notificaciones'),
                      subtitle: const Text(
                          'Recibir alertas de stock bajo'),
                      value: vm.notificationsEnabled,
                      onChanged: (v) => vm.setNotificationsEnabled(v),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.monetization_on_outlined),
                      title: const Text('Moneda'),
                      subtitle: const Text('S/ (Sol Peruano)'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Tema'),
                      subtitle: Text(
                          vm.themeMode == ThemeMode.dark
                              ? 'Oscuro'
                              : 'Claro'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _cambiarTema(context, vm),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Acerca de',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Versión'),
                      subtitle: Text(AppConstants.appVersion),
                    ),
                    if (_token != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            const Icon(Icons.notifications_active),
                        title: const Text('Token FCM'),
                        subtitle: Text(
                          _token!,
                          style: const TextStyle(fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(_copiado ? Icons.check : Icons.copy),
                          onPressed: _copiar,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _copiar() {
    if (_token == null) return;
    Clipboard.setData(ClipboardData(text: _token!));
    setState(() => _copiado = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiado = false);
    });
  }

  void _editarTexto(BuildContext context, String titulo,
      String valorActual, Future<void> Function(String) onSave) {
    final controller = TextEditingController(text: valorActual);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _cambiarTema(BuildContext context, ConfigViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final dialogTheme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.light_mode,
                  color: vm.themeMode == ThemeMode.light
                      ? dialogTheme.colorScheme.primary
                      : null,
                ),
                title: const Text('Claro'),
                trailing: vm.themeMode == ThemeMode.light
                    ? Icon(Icons.check,
                        color: dialogTheme.colorScheme.primary)
                    : null,
                onTap: () {
                  vm.setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.dark_mode,
                  color: vm.themeMode == ThemeMode.dark
                      ? dialogTheme.colorScheme.primary
                      : null,
                ),
                title: const Text('Oscuro'),
                trailing: vm.themeMode == ThemeMode.dark
                    ? Icon(Icons.check,
                        color: dialogTheme.colorScheme.primary)
                    : null,
                onTap: () {
                  vm.setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
