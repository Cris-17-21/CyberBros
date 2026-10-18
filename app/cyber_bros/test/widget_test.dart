import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_bros/app/cyberon_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sin sesión muestra el login con acceso de invitado', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CyberonApp());
    // Espera a que la puerta de sesión termine de recuperar la sesión guardada.
    await tester.pumpAndSettle();

    expect(find.text('Qué bueno verte'), findsOneWidget);
    expect(find.text('Explorar sin cuenta'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
