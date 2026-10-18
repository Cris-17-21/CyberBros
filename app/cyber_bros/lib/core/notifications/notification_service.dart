import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Tipos de aviso que el usuario puede activar o apagar por separado.
enum NotificationKind {
  progress(
    'Viaje en curso',
    'Un aviso fijo con el paso actual mientras viajas.',
  ),
  nextStep(
    'Siguiente paso',
    'Te avisa cuando toca cambiar de tramo: caminar, abordar o bajar.',
  ),
  nearStop(
    'Cerca de tu bajada o conexión',
    'Te avisa cuando estás por llegar al final de un tramo.',
  ),
  arrival('Llegada', 'Confirma cuando llegas a tu destino.'),
  feedback(
    '¿Cómo te fue?',
    'Un recordatorio 30 minutos después de terminar para que cuentes cómo fue.',
  ),
  plannedReminder(
    'Viaje planificado',
    'Te recuerda un viaje que elegiste pero aún no iniciaste.',
  );

  const NotificationKind(this.title, this.description);

  final String title;
  final String description;
}

/// Notificaciones locales del viaje (RF-12, RF-14). No necesitan servidor ni
/// internet. En Android 13 o superior piden permiso al activarlas.
///
/// En web no hacen nada: ahí no son fiables (ver cyberon-arquitectura.md 8.5).
class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _progressId = 1001;
  static const _stageId = 1002;
  static const _nearId = 1003;
  static const _arrivalId = 1004;
  static const _plannedBase = 2000;
  static const _feedbackBase = 3000;

  static const _feedbackDelay = Duration(minutes: 30);
  static const _plannedDelay = Duration(minutes: 15);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  bool _ready = false;
  bool _enabled = true;
  final Map<NotificationKind, bool> _kinds = {
    for (final kind in NotificationKind.values) kind: true,
  };
  int _nearNotifiedStage = -1;

  /// Se llama al tocar una notificación con su `payload` (por ejemplo `history`).
  void Function(String payload)? onTap;

  bool get supported => _ready;
  bool get enabled => _enabled;
  bool isKindEnabled(NotificationKind kind) => _kinds[kind] ?? true;

  bool _allowed(NotificationKind kind) =>
      _ready && _enabled && (_kinds[kind] ?? true);

  // ------------------------------------------------------------- arranque

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Lima'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) onTap?.call(payload);
        },
      );
      _ready = true;
      await _loadPrefs();
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> _loadPrefs() async {
    try {
      _enabled = await _prefs.getBool('cyberon.notif.enabled') ?? true;
      for (final kind in NotificationKind.values) {
        _kinds[kind] = await _prefs.getBool('cyberon.notif.${kind.name}') ?? true;
      }
    } catch (_) {}
    notifyListeners();
  }

  // ------------------------------------------------------------ permisos

  /// Pide el permiso del sistema si hace falta. `true` si se pueden mostrar.
  Future<bool> ensurePermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        if (await android.areNotificationsEnabled() ?? false) return true;
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (_) {}
    return false;
  }

  /// Activa o apaga todas las notificaciones. Al activar pide el permiso; si
  /// el usuario lo niega devuelve `false` y queda apagado.
  Future<bool> setEnabled(bool value) async {
    if (value && !await ensurePermission()) {
      _enabled = false;
      await _save('cyberon.notif.enabled', false);
      notifyListeners();
      return false;
    }
    _enabled = value;
    await _save('cyberon.notif.enabled', value);
    if (!value) await cancelAll();
    notifyListeners();
    return true;
  }

  Future<void> setKind(NotificationKind kind, bool value) async {
    _kinds[kind] = value;
    await _save('cyberon.notif.${kind.name}', value);
    if (!value) {
      switch (kind) {
        case NotificationKind.progress:
          await _cancel(_progressId);
        case NotificationKind.nextStep:
          await _cancel(_stageId);
        case NotificationKind.nearStop:
          await _cancel(_nearId);
        case NotificationKind.arrival:
          await _cancel(_arrivalId);
        case NotificationKind.feedback:
        case NotificationKind.plannedReminder:
          break;
      }
    }
    notifyListeners();
  }

  Future<void> _save(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (_) {}
  }

  // ---------------------------------------------------------------- viaje

  /// El viaje empezó: deja un aviso fijo con el primer paso.
  Future<void> tripStarted({
    required String tripId,
    required String destination,
    required int stages,
    required String instruction,
  }) async {
    _nearNotifiedStage = -1;
    await cancelTripReminders(tripId);
    if (!await ensurePermission()) return;
    await _showProgress(
      destination: destination,
      stage: 0,
      stages: stages,
      instruction: instruction,
    );
  }

  /// Cambió el tramo: actualiza el aviso fijo y avisa el siguiente paso.
  Future<void> stageChanged({
    required String destination,
    required int stage,
    required int stages,
    required String instruction,
  }) async {
    _nearNotifiedStage = -1;
    await _showProgress(
      destination: destination,
      stage: stage,
      stages: stages,
      instruction: instruction,
    );
    if (!_allowed(NotificationKind.nextStep)) return;
    await _show(
      id: _stageId,
      title: 'Siguiente paso',
      body: instruction,
      channel: _alerts,
      payload: 'trip',
    );
  }

  /// Estás por llegar al final del tramo. Una sola vez por tramo.
  Future<void> nearStop({required int stage, required String place}) async {
    if (_nearNotifiedStage == stage || !_allowed(NotificationKind.nearStop)) {
      return;
    }
    _nearNotifiedStage = stage;
    await _show(
      id: _nearId,
      title: 'Ya casi llegas',
      body: 'Estás cerca de $place. Prepárate.',
      channel: _alerts,
      payload: 'trip',
    );
  }

  Future<void> arrived({
    required String tripId,
    required String destination,
  }) async {
    await _cancel(_progressId);
    await _cancel(_stageId);
    await _cancel(_nearId);
    if (_allowed(NotificationKind.arrival)) {
      await _show(
        id: _arrivalId,
        title: '¡Llegaste a tu destino!',
        body: destination,
        channel: _alerts,
        payload: 'history',
      );
    }
    await scheduleFeedbackReminder(tripId: tripId, destination: destination);
  }

  Future<void> tripAbandoned({
    required String tripId,
    required String destination,
  }) async {
    await _cancel(_progressId);
    await _cancel(_stageId);
    await _cancel(_nearId);
    await scheduleFeedbackReminder(tripId: tripId, destination: destination);
  }

  // ---------------------------------------------------------- recordatorios

  /// "¿Cómo te fue?" 30 minutos después de terminar o abandonar (RF-14).
  Future<void> scheduleFeedbackReminder({
    required String tripId,
    required String destination,
  }) async {
    if (!_allowed(NotificationKind.feedback)) return;
    await _schedule(
      id: _feedbackBase + _slot(tripId),
      delay: _feedbackDelay,
      title: '¿Cómo te fue en tu viaje?',
      body: 'Cuéntanos si pudiste llegar a $destination.',
      payload: 'history',
    );
  }

  /// Si eliges un viaje y no lo inicias, te lo recuerda a los 15 minutos.
  Future<void> schedulePlannedReminder({
    required String tripId,
    required String destination,
  }) async {
    if (!_allowed(NotificationKind.plannedReminder)) return;
    await _schedule(
      id: _plannedBase + _slot(tripId),
      delay: _plannedDelay,
      title: 'Tu viaje sigue planificado',
      body: '¿Ya sales hacia $destination? Ábrelo para empezar.',
      payload: 'history',
    );
  }

  Future<void> cancelTripReminders(String tripId) async {
    await _cancel(_plannedBase + _slot(tripId));
  }

  Future<void> cancelFeedbackReminder(String tripId) async {
    await _cancel(_feedbackBase + _slot(tripId));
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Notificación de prueba desde Mi perfil.
  Future<bool> sendTest() async {
    if (!_ready || !await ensurePermission()) return false;
    await _show(
      id: 9000,
      title: 'Cyberon',
      body: 'Así se verán tus avisos de viaje.',
      channel: _alerts,
      payload: 'history',
    );
    return true;
  }

  // ------------------------------------------------------------- internos

  static const _alerts = (
    id: 'trip_alerts',
    name: 'Avisos del viaje',
    description: 'Siguiente paso, cercanía y llegada.',
  );
  static const _reminders = (
    id: 'trip_reminders',
    name: 'Recordatorios',
    description: 'Viaje planificado y feedback.',
  );
  static const _progress = (
    id: 'trip_progress',
    name: 'Viaje en curso',
    description: 'Paso actual mientras viajas.',
  );

  /// Id estable y corto por viaje para poder cancelar su recordatorio.
  int _slot(String tripId) => tripId.hashCode & 0x7FF;

  Future<void> _showProgress({
    required String destination,
    required int stage,
    required int stages,
    required String instruction,
  }) async {
    if (!_allowed(NotificationKind.progress)) return;
    try {
      await _plugin.show(
        id: _progressId,
        title: 'Hacia $destination · Paso ${stage + 1} de $stages',
        body: instruction,
        payload: 'trip',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _progress.id,
            _progress.name,
            channelDescription: _progress.description,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: false,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required ({String id, String name, String description}) channel,
    String? payload,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _schedule({
    required int id,
    required Duration delay,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_ready || !await ensurePermission()) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        payload: payload,
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _reminders.id,
            _reminders.name,
            channelDescription: _reminders.description,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }
}
