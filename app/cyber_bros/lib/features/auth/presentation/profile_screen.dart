import 'package:flutter/material.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/palette.dart';
import '../../trip_planner/data/guest_history.dart';
import '../../trip_planner/presentation/stop_lab_screen.dart';
import '../../trip_planner/presentation/trip_history_screen.dart';
import '../data/auth_service.dart';
import '../data/auth_session.dart';

/// Perfil: datos de la cuenta, resumen de viajes y acciones de sesión.
/// Sin sesión invita a crear una cuenta, sin bloquear el uso como invitado.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService.instance;
  late Future<List<GuestTripSnapshot>> _trips = GuestHistoryRepository.instance
      .list();

  void _goToLogin() =>
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Tus viajes siguen guardados en tu cuenta. Podrás verlos al volver a entrar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _auth.signOut();
    if (mounted) _goToLogin();
  }

  Future<void> _editName(AuthSession session) async {
    final controller = TextEditingController(text: session.displayName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre para mostrar'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.trim().isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _auth.updateDisplayName(newName);
      messenger.showSnackBar(const SnackBar(content: Text('Nombre actualizado.')));
    } on AuthException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListenableBuilder(
        listenable: _auth,
        builder: (context, _) {
          final session = _auth.session;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _Header(session: session),
                  const SizedBox(height: 16),
                  _Stats(trips: _trips, signedIn: session != null),
                  const SizedBox(height: 16),
                  if (session == null)
                    _GuestCard(onSignIn: _goToLogin)
                  else ...[
                    _Section(
                      title: 'Mi cuenta',
                      children: [
                        _InfoTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Nombre',
                          value: session.displayName?.trim().isNotEmpty == true
                              ? session.displayName!
                              : 'Sin nombre',
                          onTap: () => _editName(session),
                        ),
                        _InfoTile(
                          icon: Icons.mail_outline_rounded,
                          label: 'Correo',
                          value: session.email,
                        ),
                        const _InfoTile(
                          icon: Icons.cloud_done_outlined,
                          label: 'Sincronización',
                          value: 'Tus viajes se guardan en tu cuenta',
                          valueColor: Palette.confirmed,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const _NotificationSettings(),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Atajos',
                    children: [
                      _ActionTile(
                        icon: Icons.science_outlined,
                        label: 'Laboratorio: paraderos de facto (demo)',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const StopLabScreen(),
                          ),
                        ),
                      ),
                      _ActionTile(
                        icon: Icons.directions_bus_outlined,
                        label: 'Mis viajes',
                        onTap: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TripHistoryScreen(),
                              ),
                            )
                            .then(
                              (_) => setState(
                                () => _trips = GuestHistoryRepository.instance
                                    .list(),
                              ),
                            ),
                      ),
                    ],
                  ),
                  if (session != null) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Cyberon no guarda trazas de tu ubicación. Los estados de tus viajes se registran manualmente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Palette.inkMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final signedIn = session != null;
    final name = signedIn ? session!.label : 'Invitado';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Palette.primaryDark, Palette.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Palette.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white54, width: 2),
            ),
            child: signedIn
                ? Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  signedIn ? session!.email : 'Sin cuenta en este dispositivo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        signedIn
                            ? Icons.verified_user_outlined
                            : Icons.explore_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        signedIn ? 'Cuenta Cyberon' : 'Modo invitado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.trips, required this.signedIn});

  final Future<List<GuestTripSnapshot>> trips;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GuestTripSnapshot>>(
      future: trips,
      builder: (context, snapshot) {
        final list = snapshot.data ?? const <GuestTripSnapshot>[];
        final loading = !snapshot.hasData && !snapshot.hasError;
        final completed = list
            .where((trip) => trip.status == GuestTripStatus.completed)
            .length;
        final spent = list.fold<int>(0, (sum, trip) => sum + trip.spentCents);
        String value(String text) => loading ? '–' : text;
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.route_outlined,
                label: 'Viajes',
                value: value('${list.length}'),
                color: Palette.primary,
                background: Palette.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.flag_outlined,
                label: 'Completados',
                value: value('$completed'),
                color: Palette.confirmed,
                background: Palette.confirmedBg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.payments_outlined,
                label: 'Gastado',
                value: value('S/ ${(spent / 100).toStringAsFixed(2)}'),
                color: Palette.estimated,
                background: Palette.estimatedBg,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Palette.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Palette.inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Palette.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_upload_outlined, color: Palette.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Guarda tus viajes en tu cuenta',
                  style: TextStyle(
                    color: Palette.primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Como invitado tus viajes se guardan solo en este celular por 30 días. Con una cuenta los ves en todos tus dispositivos y no se pierden.',
            style: TextStyle(color: Palette.inkMuted, height: 1.35),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onSignIn,
            child: const Text('Iniciar sesión o crear cuenta'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Palette.inkMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 60,
      leading: Icon(icon, color: Palette.inkMuted),
      title: Text(
        label,
        style: const TextStyle(color: Palette.inkMuted, fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: valueColor ?? Palette.ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.edit_outlined, size: 18, color: Palette.inkMuted),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 56,
      leading: Icon(icon, color: Palette.primary),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Palette.ink),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

/// Ajustes de notificaciones: un interruptor general y uno por tipo de aviso.
class _NotificationSettings extends StatelessWidget {
  const _NotificationSettings();

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!service.supported) {
          return const _Section(
            title: 'Notificaciones',
            children: [
              _InfoTile(
                icon: Icons.notifications_off_outlined,
                label: 'No disponibles',
                value: 'Los avisos funcionan en la app de Android',
              ),
            ],
          );
        }
        return _Section(
          title: 'Notificaciones',
          children: [
            SwitchListTile(
              value: service.enabled,
              onChanged: (value) async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await service.setEnabled(value);
                if (!ok) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Activa el permiso de notificaciones de Cyberon en los ajustes del teléfono.',
                      ),
                    ),
                  );
                }
              },
              secondary: const Icon(
                Icons.notifications_active_outlined,
                color: Palette.primary,
              ),
              title: const Text(
                'Avisos de viaje',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Paso a paso mientras viajas y recordatorios',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
            if (service.enabled) ...[
              for (final kind in NotificationKind.values)
                SwitchListTile(
                  value: service.isKindEnabled(kind),
                  onChanged: (value) => service.setKind(kind, value),
                  contentPadding: const EdgeInsets.only(left: 56, right: 16),
                  dense: true,
                  title: Text(
                    kind.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    kind.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.send_outlined, color: Palette.primary),
                title: const Text(
                  'Enviar una notificación de prueba',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final sent = await service.sendTest();
                  if (!sent) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo mostrar la notificación.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
