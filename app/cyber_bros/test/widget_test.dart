import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_bros/app/cyberon_app.dart';

void main() {
  testWidgets('muestra el acceso de demostración de Cyberon', (
    tester,
  ) async {
    await tester.pumpWidget(const CyberonApp());

    expect(find.text('Qué bueno verte'), findsOneWidget);
    expect(find.text('Explorar sin cuenta'), findsOneWidget);

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
