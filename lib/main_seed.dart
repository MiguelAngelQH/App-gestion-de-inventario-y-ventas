import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_ventas/models/producto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const _SeedApp());
}

class _SeedApp extends StatelessWidget {
  const _SeedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartVentas Seed',
      debugShowCheckedModeBanner: false,
      home: _LoginScreen(),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) return;

    setState(() => _loading = true);
    try {
      await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _SeedScreen()),
      );
    } on auth.FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message ?? "desconocido"}')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed - Iniciar sesi\u00f3n')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Ingresa tus credenciales para poblar la base de datos',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Correo electr\u00f3nico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(
                labelText: 'Contrase\u00f1a',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Iniciar sesi\u00f3n y sembrar datos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeedScreen extends StatefulWidget {
  @override
  State<_SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<_SeedScreen> {
  String _log = 'Iniciando...';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seed());
  }

  Future<void> _seed() async {
    await _logMsg('Conectando a Firestore...');

    final db = FirebaseFirestore.instance;
    final uid = auth.FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      await _logMsg('ERROR: No hay sesi\u00f3n activa');
      return;
    }

    Map<String, dynamic> withUid(Map<String, dynamic> data) =>
        {...data, 'uid': uid};

    // === PROVEEDORES ===
    await _logMsg('Creando proveedores...');

    final proveedores = {
      'Portugal': 'Distribuidora farmac\u00e9utica',
      'Alicorp S.A.': 'Alimentos, limpieza e higiene',
      'Backus S.A.': 'Bebidas y cervezas',
      'Gloria S.A.': 'L\u00e1cteos y derivados',
      'Kimberly-Clark Per\u00fa': 'Papel higi\u00e9nico y pa\u00f1ales',
      'Nestl\u00e9 Per\u00fa': 'Alimentos y cereales',
      'Molitalia S.A.': 'Fideos y conservas',
      'Colgate-Palmolive': 'Higiene personal',
      'Clorox Per\u00fa': 'Productos de limpieza',
      'Mondelez Per\u00fa': 'Galletas y snacks',
      'Coca-Cola Per\u00fa': 'Bebidas gaseosas',
      'San Fernando': 'Aves y huevos',
    };

    final provRefs = <String, String>{};
    for (final entry in proveedores.entries) {
      final ref = await db.collection('proveedores').add(withUid({
        'nombre': entry.key,
        'telefono': '',
        'email': '',
        'direccion': '',
        'saldoPendiente': 0,
        'estado': 'pagado',
      }));
      provRefs[entry.key] = ref.id;
      await _logMsg('  + ${entry.key}');
    }

    // === PRODUCTOS ===
    await _logMsg('Creando productos...');

    final productosData = [
      _Pd('Dextrometorfano Jarabe 120ml', 'Para la tos seca', 'Portugal', 6.50, 15, 12.00,
          categoria: 'General', marca: 'Portugal'),
      _Pd('Paracetamol 500mg x30 tab', 'Analg\u00e9sico y antifebril', 'Portugal', 2.50, 20, 4.50,
          categoria: 'General', marca: 'Gen\u00e9rico'),
      _Pd('Ibuprofeno 400mg x20 tab', 'Antiinflamatorio', 'Portugal', 3.00, 18, 5.00,
          categoria: 'General', marca: 'Gen\u00e9rico'),
      _Pd('Amoxicilina 500mg x21 cap', 'Antibiótico', 'Portugal', 5.00, 10, 8.50,
          categoria: 'General', marca: 'Gen\u00e9rico'),
      _Pd('Loratadina 10mg x10 tab', 'Antial\u00e9rgico', 'Portugal', 3.50, 14, 6.00,
          categoria: 'General', marca: 'Gen\u00e9rico'),
      _Pd('Omeprazol 20mg x14 cap', 'Protector g\u00e1strico', 'Portugal', 4.00, 12, 7.00,
          categoria: 'General', marca: 'Gen\u00e9rico'),
      _Pd('Alcohol Medicinal 500ml', 'Desinfectante de uso externo', 'Portugal', 3.00, 25, 5.00,
          categoria: 'General', marca: 'Portugal'),
      _Pd('Algod\u00f3n x100g', 'Algod\u00f3n hidr\u00f3filo', 'Portugal', 2.20, 15, 4.00,
          categoria: 'General', marca: 'Portugal'),

      _Pd('Arroz Coste\u00f1o x1kg', 'Arroz extra', 'Alicorp S.A.', 3.20, 30, 4.80,
          categoria: 'Alimentos', marca: 'Coste\u00f1o'),
      _Pd('Fideos Don Vittorio x500g', 'Fideos de s\u00e9mola', 'Alicorp S.A.', 2.00, 25, 3.20,
          categoria: 'Alimentos', marca: 'Don Vittorio'),
      _Pd('Aceite Primor x1L', 'Aceite vegetal', 'Alicorp S.A.', 5.50, 12, 8.50,
          categoria: 'Alimentos', marca: 'Primor'),
      _Pd('Az\u00facar Rubia x1kg', 'Az\u00facar rubia', 'Alicorp S.A.', 2.80, 40, 4.20,
          categoria: 'Alimentos', marca: 'Coste\u00f1o'),
      _Pd('Harina Past. Blanca Flor x1kg', 'Harina preparada', 'Alicorp S.A.', 2.50, 18, 3.80,
          categoria: 'Alimentos', marca: 'Blanca Flor'),
      _Pd('Lavavajillas Sapolio 500ml', 'Detergente lavaplatos', 'Alicorp S.A.', 3.20, 15, 5.00,
          categoria: 'Limpieza', marca: 'Sapolio'),
      _Pd('Jab\u00f3n Bolivar x1', 'Jab\u00f3n multiusos', 'Alicorp S.A.', 1.50, 30, 2.50,
          categoria: 'Limpieza', marca: 'Bolivar'),
      _Pd('Detergente Bolivar 500g', 'Detergente en polvo', 'Alicorp S.A.', 2.80, 20, 4.50,
          categoria: 'Limpieza', marca: 'Bolivar'),
      _Pd('Shampoo Sedal 200ml', 'Shampoo para el cabello', 'Alicorp S.A.', 5.00, 10, 8.00,
          categoria: 'Higiene', marca: 'Sedal'),

      _Pd('Coca-Cola 500ml', 'Gaseosa cola', 'Backus S.A.', 2.00, 48, 3.50,
          categoria: 'Bebidas', marca: 'Coca-Cola', unidad: 'botella'),
      _Pd('Inka Kola 500ml', 'Gaseosa peruana', 'Backus S.A.', 2.00, 36, 3.50,
          categoria: 'Bebidas', marca: 'Inka Kola', unidad: 'botella'),
      _Pd('Agua San Luis 625ml', 'Agua mineral', 'Backus S.A.', 1.20, 60, 2.50,
          categoria: 'Bebidas', marca: 'San Luis', unidad: 'botella'),
      _Pd('Cerveza Cristal 355ml', 'Cerveza rubia', 'Backus S.A.', 2.80, 24, 4.50,
          categoria: 'Bebidas', marca: 'Cristal', unidad: 'botella'),
      _Pd('Cerveza Pilsen 355ml', 'Cerveza rubia', 'Backus S.A.', 2.80, 20, 4.50,
          categoria: 'Bebidas', marca: 'Pilsen', unidad: 'botella'),

      _Pd('Leche Evaporada Gloria x1L', 'Leche evaporada entera', 'Gloria S.A.', 3.50, 24, 5.50,
          categoria: 'Alimentos', marca: 'Gloria'),
      _Pd('Yogurt Gloria Natural x1L', 'Yogurt batido natural', 'Gloria S.A.', 4.00, 12, 6.50,
          categoria: 'Alimentos', marca: 'Gloria'),
      _Pd('Leche Gloria UHT x1L', 'Leche fresca UHT', 'Gloria S.A.', 3.20, 18, 5.00,
          categoria: 'Alimentos', marca: 'Gloria'),

      _Pd('Papel Higi\u00e9nico Suave x4', 'Papel higi\u00e9nico', 'Kimberly-Clark Per\u00fa', 4.50, 20, 7.00,
          categoria: 'Higiene', marca: 'Suave', unidad: 'pack'),
      _Pd('Pa\u00f1ales Huggies XG x20', 'Pa\u00f1ales desechables', 'Kimberly-Clark Per\u00fa', 12.00, 8, 18.50,
          categoria: 'Higiene', marca: 'Huggies', unidad: 'pack'),

      _Pd('Caf\u00e9 Nescaf\u00e9 100g', 'Caf\u00e9 soluble', 'Nestl\u00e9 Per\u00fa', 4.50, 15, 7.00,
          categoria: 'Alimentos', marca: 'Nescaf\u00e9'),
      _Pd('Leche Condensada Ideal 395g', 'Leche condensada', 'Nestl\u00e9 Per\u00fa', 3.20, 12, 5.00,
          categoria: 'Alimentos', marca: 'Ideal'),
      _Pd('Cereal Zucaritas 400g', 'Cereal azucarado', 'Nestl\u00e9 Per\u00fa', 5.50, 10, 8.50,
          categoria: 'Alimentos', marca: 'Zucaritas'),

      _Pd('Fideos Molitalia x500g', 'Fideos de s\u00e9mola', 'Molitalia S.A.', 1.80, 20, 3.00,
          categoria: 'Alimentos', marca: 'Molitalia'),
      _Pd('At\u00fan Molitalia 170g', 'Conserva de at\u00fan', 'Molitalia S.A.', 2.80, 15, 4.50,
          categoria: 'Alimentos', marca: 'Molitalia'),

      _Pd('Pasta Dental Colgate 90ml', 'Crema dental', 'Colgate-Palmolive', 3.80, 18, 6.00,
          categoria: 'Higiene', marca: 'Colgate'),
      _Pd('Jab\u00f3n Protex x1', 'Jab\u00f3n antibacterial', 'Colgate-Palmolive', 2.50, 24, 4.00,
          categoria: 'Higiene', marca: 'Protex'),

      _Pd('Lej\u00eda Clorox 1L', 'Lej\u00eda desinfectante', 'Clorox Per\u00fa', 2.50, 15, 4.00,
          categoria: 'Limpieza', marca: 'Clorox'),
      _Pd('Desinfectante Clorox 1L', 'Desinfectante multiusos', 'Clorox Per\u00fa', 3.50, 10, 5.50,
          categoria: 'Limpieza', marca: 'Clorox'),

      _Pd('Galletas Oreo 100g', 'Galletas rellenas de crema', 'Mondelez Per\u00fa', 1.80, 24, 3.00,
          categoria: 'Alimentos', marca: 'Oreo'),
      _Pd('Galletas Chomp 100g', 'Galletas de vainilla', 'Mondelez Per\u00fa', 1.50, 30, 2.50,
          categoria: 'Alimentos', marca: 'Chomp'),

      _Pd('Sprite 500ml', 'Gaseosa lima-lim\u00f3n', 'Coca-Cola Per\u00fa', 2.00, 24, 3.50,
          categoria: 'Bebidas', marca: 'Sprite', unidad: 'botella'),
      _Pd('Fanta 500ml', 'Gaseosa naranja', 'Coca-Cola Per\u00fa', 2.00, 18, 3.50,
          categoria: 'Bebidas', marca: 'Fanta', unidad: 'botella'),

      _Pd('Huevos San Fernando x30', 'Huevos de gallina', 'San Fernando', 8.00, 10, 12.00,
          categoria: 'Alimentos', marca: 'San Fernando', unidad: 'pack'),
      _Pd('Pechuga Pollo x1kg', 'Pechuga de pollo fresca', 'San Fernando', 10.00, 8, 14.00,
          categoria: 'Alimentos', marca: 'San Fernando'),
    ];

    for (final p in productosData) {
      final provId = provRefs[p.provNombre] ?? '';
      final prodId = db.collection('productos').doc().id;

      final producto = Producto(
        id: prodId,
        nombre: p.nombre,
        descripcion: p.descripcion,
        categoria: p.categoria,
        marca: p.marca,
        proveedorId: provId,
        proveedorNombre: p.provNombre,
        stock: p.stock,
        costo: p.costo,
        presentaciones: [
          Presentacion(
            id: '${prodId}_unidad',
            nombre: 'Unidad',
            unidad: p.unidad,
            precio: p.precio,
          ),
        ],
      );

      await db.collection('productos').doc(prodId).set(
        withUid(producto.toMap()..remove('id')),
      );
      await _logMsg('  + ${p.nombre}');
    }

    await _logMsg('\n\u2705 SEED COMPLETADO');
    await _logMsg(
        '${proveedores.length} proveedores, ${productosData.length} productos');
    setState(() => _done = true);
  }

  Future<void> _logMsg(String msg) async {
    setState(() => _log += '\n$msg');
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poblar Base de Datos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (_done) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const _DoneScreen()),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Finalizar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoneScreen extends StatelessWidget {
  const _DoneScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed completado'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green.shade600),
              const SizedBox(height: 24),
              const Text(
                'Datos sembrados correctamente',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '12 proveedores y 42 productos agregados a Firebase.\n\n'
                'Ya puedes cerrar esta pantalla y abrir la app normal.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _cerrar(context),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cerrar(BuildContext context) {
    auth.FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const _LoginScreen()),
      (_) => false,
    );
  }
}

class _Pd {
  final String nombre;
  final String descripcion;
  final String provNombre;
  final double costo;
  final double stock;
  final double precio;
  final String categoria;
  final String marca;
  final String unidad;

  _Pd(
    this.nombre,
    this.descripcion,
    this.provNombre,
    this.costo,
    this.stock,
    this.precio, {
    this.categoria = 'General',
    this.marca = '',
    this.unidad = 'unidad',
  });
}
