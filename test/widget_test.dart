import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ventas/main.dart';

void main() {
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(SmartVentasApp(initialThemeMode: ThemeMode.light));
    expect(find.text('SmartVentas'), findsOneWidget);
  });
}
