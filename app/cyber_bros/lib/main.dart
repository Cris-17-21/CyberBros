import 'package:flutter/material.dart';

import 'app/cyberon_app.dart';
import 'core/notifications/notification_service.dart';
import 'features/trip_planner/presentation/trip_history_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.instance.onTap = (payload) {
    // Tocar un aviso de llegada, feedback o recordatorio abre Mis viajes.
    if (payload == 'history') {
      cyberonNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const TripHistoryScreen()),
      );
    }
  };
  await NotificationService.instance.init();
  runApp(const CyberonApp());
}
