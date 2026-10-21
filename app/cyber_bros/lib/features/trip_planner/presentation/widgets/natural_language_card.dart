import 'package:flutter/material.dart';

import '../../../../core/theme/palette.dart';
import '../../domain/condition_parser.dart';

/// "Cuéntalo con tus palabras" (RF-04): la persona escribe sus condiciones, la
/// app muestra lo que entendió como etiquetas que se pueden quitar, y solo al
/// confirmar se pasan a los controles. Es una vía alternativa, nunca la única.
class NaturalLanguageCard extends StatefulWidget {
  const NaturalLanguageCard({super.key, required this.onApply});

  /// Recibe lo entendido y los campos que la persona dejó activos.
  final void Function(ParsedConditions parsed, Set<ConditionField> accepted)
  onApply;

  @override
  State<NaturalLanguageCard> createState() => _NaturalLanguageCardState();
}

class _NaturalLanguageCardState extends State<NaturalLanguageCard> {
  static const _examples = [
    'Tengo 10 soles y no quiero caminar más de 2 cuadras',
    'Solo tengo 6 soles, sin taxi, lo más barato',
    'Voy apurado, puedo gastar 15 soles y tomar taxi',
  ];

  final _controller = TextEditingController();
  ParsedConditions? _parsed;
  final Set<ConditionField> _dismissed = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _understand() {
    FocusScope.of(context).unfocus();
    setState(() {
      _parsed = ConditionParser.parse(_controller.text);
      _dismissed.clear();
    });
  }

  void _apply() {
    final parsed = _parsed;
    if (parsed == null) return;
    final accepted = {
      for (final tag in parsed.tags)
        if (!_dismissed.contains(tag.field)) tag.field,
    };
    widget.onApply(parsed, accepted);
    setState(() => _parsed = null);
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    final accepted = parsed == null
        ? const <ConditionTag>[]
        : [
            for (final tag in parsed.tags)
              if (!_dismissed.contains(tag.field)) tag,
          ];
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.auto_awesome_rounded, color: Palette.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cuéntalo con tus palabras',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Palette.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Escribe cuánto puedes gastar y cuánto caminar. Tú revisas lo que entendimos antes de usarlo.',
            style: TextStyle(color: Palette.inkMuted, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            maxLength: maxConditionTextLength,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Ej.: Tengo 10 soles y no quiero caminar más de 2 cuadras',
              fillColor: Colors.white,
              counterText: '',
            ),
            onSubmitted: (_) => _understand(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final example in _examples)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        example,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        _controller.text = example;
                        _understand();
                      },
                      backgroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: _understand,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            child: const Text('Entender'),
          ),
          if (parsed != null) ...[
            const SizedBox(height: 14),
            if (parsed.isEmpty)
              const _Hint(
                icon: Icons.help_outline_rounded,
                text:
                    'No pudimos entender cifras en ese texto. Prueba con algo como "tengo 10 soles" o usa los controles de abajo.',
              )
            else ...[
              const Text(
                'Esto entendimos (toca la X para quitar algo):',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final tag in parsed.tags)
                    if (!_dismissed.contains(tag.field))
                      InputChip(
                        label: Text(tag.label),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        onDeleted: () =>
                            setState(() => _dismissed.add(tag.field)),
                      ),
                ],
              ),
              for (final warning in parsed.warnings)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _Hint(
                    icon: Icons.info_outline_rounded,
                    text: warning,
                    color: Palette.estimated,
                  ),
                ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: accepted.isEmpty ? null : _apply,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Usar estas condiciones'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.icon,
    required this.text,
    this.color = Palette.inkMuted,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 12.5, height: 1.3),
        ),
      ),
    ],
  );
}
