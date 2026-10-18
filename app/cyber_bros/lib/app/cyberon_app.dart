import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
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
      home: const LoginScreen(),
      routes: {
        '/planner': (_) => const PlannerHomeScreen(),
      },
    );
  }
}
