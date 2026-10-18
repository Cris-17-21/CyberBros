import 'package:cyber_bros/features/trip_planner/presentation/stop_lab_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpLab(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: StopLabScreen()));
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.textContaining(text));
  await tester.tap(find.textContaining(text));
  // La prueba espera 30 ms antes de calcular y luego recalcula los paraderos.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('laboratorio: personas reales producen un paradero visible', (tester) async {
    await _pumpLab(tester);
    expect(find.text('Ninguno por ahora. Un paradero solo aparece cuando hay evidencia suficiente.'), findsOneWidget);

    await _tap(tester, '5 personas esperan');
    expect(find.textContaining('VISIBLE'), findsOneWidget);
    expect(find.textContaining('5 fuentes independientes'), findsOneWidget);
    // Todo lo del laboratorio se rotula como simulado.
    expect(find.text('SIMULADO'), findsWidgets);
  });

  testWidgets('laboratorio: el ataque del carrito no crea ningún paradero', (tester) async {
    await _pumpLab(tester);
    await _tap(tester, 'Carrito: 99 teléfonos caminando');
    expect(find.textContaining('VISIBLE'), findsNothing);
    expect(find.textContaining('Movimiento peatonal sostenido'), findsOneWidget);
    expect(find.text('99×'), findsOneWidget);
  });

  testWidgets('laboratorio: los bots de una misma IP quedan en cuarentena', (tester) async {
    await _pumpLab(tester);
    await _tap(tester, '20 bots de una misma IP');
    expect(find.textContaining('VISIBLE'), findsNothing);
    expect(find.text('EN CUARENTENA'), findsOneWidget);
  });

  testWidgets('laboratorio: revertir el lote de bots elimina su paradero', (tester) async {
    await _pumpLab(tester);
    await _tap(tester, '20 bots de una misma IP');
    expect(find.text('EN CUARENTENA'), findsOneWidget);
    await _tap(tester, 'Revertir lote de bots');
    expect(find.text('EN CUARENTENA'), findsNothing);
  });
}
