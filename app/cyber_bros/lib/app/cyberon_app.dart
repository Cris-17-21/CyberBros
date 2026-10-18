import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/trip_planner/presentation/planner_home_screen.dart';

class CyberonApp extends StatelessWidget {
  const CyberonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyberon',
      debugShowCheckedModeBanner: false,
      theme: buildCyberonTheme(),
      home: const _SessionGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/planner': (_) => const PlannerHomeScreen(),
      },
    );
  }
}

/// Recupera la sesión guardada: con sesión abre el planificador, sin ella el
/// login (que siempre permite continuar como invitado).
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  late final Future<void> _restoring = AuthService.instance.restore();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _restoring,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return AuthService.instance.isSignedIn
            ? const PlannerHomeScreen()
            : const LoginScreen();
      },
    );
  }
}
