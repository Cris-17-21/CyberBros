import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../../auth/data/auth_service.dart';
import '../data/shared_taxi_store.dart';

/// Reparte el taxi del tramo puente con otras personas que van al mismo tramo.
class SharedTaxiScreen extends StatefulWidget {
  const SharedTaxiScreen({super.key, required this.request});

  final SharedTaxiRequest request;

  @override
  State<SharedTaxiScreen> createState() => _SharedTaxiScreenState();
}

class _SharedTaxiScreenState extends State<SharedTaxiScreen> {
  final _store = SharedTaxiStore.instance;
  Timer? _poll;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  SharedTaxiRoom? _room;
  List<SharedTaxiRoom> _nearby = const [];
  int _maxPeople = 3;
  int _waitMinutes = 20;

  SharedTaxiRequest get _request => widget.request;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!_store.signedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final room = await _store.myRoom();
      final nearby = room == null
          ? await _store.findNearby(_request)
          : const <SharedTaxiRoom>[];
      if (!mounted) return;
      setState(() {
        _room = room;
        _nearby = nearby;
        _error = null;
        _loading = false;
      });
    } on TaxiException catch (error) {
      if (!mounted) return;
      setState(() {
        if (!silent) _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _load(silent: true);
    } on TaxiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() => _run(() async {
    final room = await _store.create(
      _request,
      maxPeople: _maxPeople,
      waitFor: Duration(minutes: _waitMinutes),
    );
    if (mounted) setState(() => _room = room);
  });

  Future<void> _join(SharedTaxiRoom room) => _run(() async {
    final joined = await _store.join(room);
    if (mounted) setState(() => _room = joined);
  });

  Future<void> _leave(SharedTaxiRoom room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir de la sala'),
        content: Text(
          room.ownerUid == _myUid
              ? 'Como creaste la sala, al salir se cerrará para todas las personas.'
              : 'Dejarás tu lugar y el precio se repartirá entre quienes se queden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Quedarme'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await _store.leave(room);
      if (mounted) setState(() => _room = null);
    });
  }

  String? get _myUid => AuthService.instance.session?.userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(title: const Text('Taxi compartido')),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _Hero(request: _request),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  _Notice(text: _error!, error: true),
                  const SizedBox(height: 12),
                ],
                if (!_store.signedIn)
                  _LoginPrompt(
                    onSignIn: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (_) => false),
                  )
                else if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_room != null)
                  _RoomView(
                    room: _room!,
                    busy: _busy,
                    onLeave: () => _leave(_room!),
                  )
                else ...[
                  _SavingsTable(taxiCents: _request.taxiCents, selected: _maxPeople),
                  const SizedBox(height: 20),
                  _NearbySection(
                    rooms: _nearby,
                    busy: _busy,
                    onJoin: _join,
                  ),
                  const SizedBox(height: 20),
                  _CreateCard(
                    maxPeople: _maxPeople,
                    waitMinutes: _waitMinutes,
                    taxiCents: _request.taxiCents,
                    busy: _busy,
                    onPeople: (value) => setState(() => _maxPeople = value),
                    onWait: (value) => setState(() => _waitMinutes = value),
                    onCreate: _create,
                  ),
                ],
                const SizedBox(height: 20),
                const _SafetyCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- piezas

String _soles(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';

class _Hero extends StatelessWidget {
  const _Hero({required this.request});

  final SharedTaxiRequest request;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFC2410C), Palette.taxi],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Palette.taxi.withValues(alpha: 0.28),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_taxi_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Reparte el taxi de este tramo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          request.fromLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Icon(Icons.south_rounded, color: Colors.white70, size: 18),
        ),
        Text(
          request.toLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tú solo: ${_soles(request.taxiCents)} · '
                  '${request.distanceMetres >= 1000 ? '${(request.distanceMetres / 1000).toStringAsFixed(1)} km' : '${request.distanceMetres} m'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Text(
                'estimado',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SavingsTable extends StatelessWidget {
  const _SavingsTable({required this.taxiCents, required this.selected});

  final int taxiCents;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final share = (taxiCents / selected).ceil();
    final saving = taxiCents - share;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('Lo que pagarías por persona'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var people = 1; people <= 4; people++)
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: people == 4 ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: people == selected
                        ? Palette.taxi
                        : people == 1
                        ? Palette.surface
                        : Palette.taxiBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: people == selected
                          ? Palette.taxi
                          : people == 1
                          ? Palette.border
                          : const Color(0xFFFDBA74),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        people == 1 ? 'Solo' : '$people personas',
                        style: TextStyle(
                          color: people == selected
                              ? Colors.white
                              : people == 1
                              ? Palette.inkMuted
                              : Palette.taxi,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          _soles((taxiCents / people).ceil()),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: people == selected
                                ? Colors.white
                                : Palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          selected == 1
              ? 'Elige cuántas personas serían para ver cuánto ahorras.'
              : 'Con $selected personas pagas ${_soles(share)} en vez de ${_soles(taxiCents)}: ahorras ${_soles(saving)}.',
          style: const TextStyle(
            color: Palette.confirmed,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Precio estimado del taxi dividido entre las personas. Confirma el precio real en tu app de taxi antes de subir.',
          style: TextStyle(color: Palette.inkMuted, fontSize: 12, height: 1.3),
        ),
      ],
    );
  }
}

class _NearbySection extends StatelessWidget {
  const _NearbySection({
    required this.rooms,
    required this.busy,
    required this.onJoin,
  });

  final List<SharedTaxiRoom> rooms;
  final bool busy;
  final Future<void> Function(SharedTaxiRoom) onJoin;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Title('Personas que van a tu mismo tramo'),
      const SizedBox(height: 10),
      if (rooms.isEmpty)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Palette.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: Palette.inkMuted),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Por ahora nadie. Crea una sala y espera a que se sumen; también puedes jalar para actualizar.',
                  style: TextStyle(color: Palette.inkMuted, height: 1.3),
                ),
              ),
            ],
          ),
        )
      else
        for (final room in rooms)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RoomCard(room: room, busy: busy, onJoin: () => onJoin(room)),
          ),
    ],
  );
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.busy,
    required this.onJoin,
  });

  final SharedTaxiRoom room;
  final bool busy;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final minutes = room.timeLeft.inMinutes.clamp(0, 999);
    final yourShare = room.shareCents(room.members.length + 1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatars(members: room.members, max: room.maxPeople),
              const Spacer(),
              _Pill(
                icon: Icons.timer_outlined,
                text: 'Sale en ~$minutes min',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${room.ownerName} y ${room.members.length - 1} más · '
            'quedan ${room.seatsLeft} ${room.seatsLeft == 1 ? 'lugar' : 'lugares'}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Palette.ink,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Si te unes pagas ${_soles(yourShare)} en vez de ${_soles(room.taxiCents)}',
            style: const TextStyle(
              color: Palette.confirmed,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : onJoin,
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Unirme'),
            style: FilledButton.styleFrom(backgroundColor: Palette.taxi),
          ),
        ],
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  const _CreateCard({
    required this.maxPeople,
    required this.waitMinutes,
    required this.taxiCents,
    required this.busy,
    required this.onPeople,
    required this.onWait,
    required this.onCreate,
  });

  final int maxPeople;
  final int waitMinutes;
  final int taxiCents;
  final bool busy;
  final ValueChanged<int> onPeople;
  final ValueChanged<int> onWait;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Palette.taxiBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFDBA74)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('Crear una sala'),
        const SizedBox(height: 4),
        const Text(
          'Otras personas que vayan a tu tramo podrán unirse.',
          style: TextStyle(color: Palette.inkMuted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        const Text('¿Cuántas personas en total?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _Segments(
          values: const [2, 3, 4],
          selected: maxPeople,
          label: (value) => '$value personas',
          onChanged: onPeople,
        ),
        const SizedBox(height: 14),
        const Text('¿Cuánto esperas?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _Segments(
          values: const [10, 20, 30],
          selected: waitMinutes,
          label: (value) => '$value min',
          onChanged: onWait,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                _soles((taxiCents / maxPeople).ceil()),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Palette.taxi,
                  letterSpacing: -0.8,
                ),
              ),
              Text(
                'por persona si se llenan los $maxPeople lugares',
                style: const TextStyle(color: Palette.inkMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: busy ? null : onCreate,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Crear sala y esperar'),
          style: FilledButton.styleFrom(backgroundColor: Palette.taxi),
        ),
      ],
    ),
  );
}

class _Segments extends StatelessWidget {
  const _Segments({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<int> values;
  final int selected;
  final String Function(int) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final value in values)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: value == values.last ? 0 : 8),
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(label(value), textAlign: TextAlign.center),
              ),
              selected: selected == value,
              onSelected: (_) => onChanged(value),
              showCheckmark: false,
              selectedColor: Palette.taxi,
              backgroundColor: Palette.surface,
              side: BorderSide(
                color: selected == value ? Palette.taxi : Palette.border,
              ),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected == value ? Colors.white : Palette.ink,
              ),
            ),
          ),
        ),
    ],
  );
}

class _RoomView extends StatelessWidget {
  const _RoomView({
    required this.room,
    required this.busy,
    required this.onLeave,
  });

  final SharedTaxiRoom room;
  final bool busy;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final people = room.members.length;
    final minutes = room.timeLeft.inMinutes.clamp(0, 999);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _Pill(
                    icon: Icons.groups_rounded,
                    text: 'Tu sala',
                    color: Palette.confirmed,
                    background: Palette.confirmedBg,
                  ),
                  const Spacer(),
                  _Pill(
                    icon: Icons.timer_outlined,
                    text: room.expired ? 'Venció' : 'Quedan ~$minutes min',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _soles(room.shareCents(people)),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Palette.ink,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'por persona (${room.members.length} de ${room.maxPeople})',
                      style: const TextStyle(color: Palette.inkMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                room.full
                    ? '¡Sala completa! Ya pueden pedir el taxi.'
                    : 'Faltan ${room.seatsLeft} para llenar el taxi. Si se suman, el precio baja.',
                style: TextStyle(
                  color: room.full ? Palette.confirmed : Palette.inkMuted,
                  fontWeight: room.full ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              for (final member in room.members)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Palette.taxiBg,
                        child: Text(
                          member.name.isEmpty
                              ? '?'
                              : member.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Palette.taxi,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (member.uid == room.ownerUid)
                        const Text(
                          'creó la sala',
                          style: TextStyle(
                            color: Palette.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Palette.primaryLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pin_drop_rounded, color: Palette.primary),
                  SizedBox(width: 8),
                  Text(
                    'Punto de encuentro',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Palette.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                room.fromLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Van a ${room.toLabel}. Cuando estén todos, pidan el taxi en su app habitual y confirmen el precio antes de subir.',
                style: const TextStyle(color: Palette.inkMuted, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: busy ? null : onLeave,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Salir de la sala'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
            side: const BorderSide(color: Color(0xFFFCA5A5)),
          ),
        ),
      ],
    );
  }
}

class _Avatars extends StatelessWidget {
  const _Avatars({required this.members, required this.max});

  final List<TaxiMember> members;
  final int max;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < max; i++)
        Align(
          widthFactor: 0.7,
          child: CircleAvatar(
            radius: 17,
            backgroundColor: Palette.surface,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: i < members.length
                  ? Palette.taxi
                  : Palette.surfaceAlt,
              child: i < members.length
                  ? Text(
                      members[i].name.isEmpty
                          ? '?'
                          : members[i].name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    )
                  : const Icon(Icons.add, size: 15, color: Palette.inkMuted),
            ),
          ),
        ),
    ],
  );
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Palette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: Palette.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Inicia sesión para compartir taxi',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Palette.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Por seguridad, solo las personas con cuenta pueden crear o unirse a una sala. Tu recorrido queda guardado en Mis viajes.',
          style: TextStyle(color: Palette.inkMuted, height: 1.35),
        ),
        const SizedBox(height: 14),
        FilledButton(onPressed: onSignIn, child: const Text('Iniciar sesión')),
      ],
    ),
  );
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Palette.border),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, color: Palette.confirmed, size: 20),
            SizedBox(width: 8),
            Text(
              'Para viajar tranquila o tranquilo',
              style: TextStyle(fontWeight: FontWeight.w800, color: Palette.ink),
            ),
          ],
        ),
        SizedBox(height: 10),
        _Tip('Encuéntrense en el paradero, en un lugar con gente e iluminado.'),
        _Tip('Solo se muestra tu primer nombre. No compartas tu teléfono ni tu dirección.'),
        _Tip('Cyberon no contrata ni cobra el taxi: pídanlo en su app y confirmen el precio.'),
        _Tip('Si algo te incomoda, no subas. Nadie está obligado a compartir.'),
      ],
    ),
  );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 8),
          child: Icon(Icons.circle, size: 5, color: Palette.inkMuted),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Palette.inkMuted,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: Palette.ink,
      letterSpacing: -0.3,
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    this.color = Palette.inkMuted,
    this.background = Palette.surfaceAlt,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? const Color(0xFFB91C1C) : Palette.inkMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}

/// Tarjeta que invita a compartir el taxi del tramo puente. Se muestra en el
/// detalle del recorrido y durante el viaje.
class SharedTaxiEntryCard extends StatelessWidget {
  const SharedTaxiEntryCard({super.key, required this.request});

  final SharedTaxiRequest request;

  @override
  Widget build(BuildContext context) {
    final saving = request.taxiCents - (request.taxiCents / 3).ceil();
    return Material(
      color: Palette.taxiBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SharedTaxiScreen(request: request),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDBA74)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Palette.taxi.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_rounded, color: Palette.taxi),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comparte este taxi',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Palette.ink,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Entre 3 personas ahorras hasta ${_soles(saving)} cada una.',
                      style: const TextStyle(
                        color: Palette.inkMuted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Palette.taxi),
            ],
          ),
        ),
      ),
    );
  }
}
