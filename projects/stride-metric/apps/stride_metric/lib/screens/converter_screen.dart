import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../l10n/app_localizations.dart';
import '../ui/app_theme.dart';
import '../ui/widgets.dart';
import 'result_screen.dart';

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key, required this.state});

  final AppState state;

  Future<void> _chooseAudience(BuildContext context) async {
    final selected = await showModalBottomSheet<Audience>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (context) => BottomSheetFrame(
        title: context.l10n.t('selectShoeType'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Audience.values
              .map(
                (audience) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.audience(audience),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: state.audience == audience
                      ? const Icon(Icons.check_circle, color: teal)
                      : null,
                  onTap: () => Navigator.pop(context, audience),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (selected != null) state.setAudience(selected);
  }

  Future<void> _chooseUnit(BuildContext context) async {
    final unit = await showModalBottomSheet<LengthUnit>(
      context: context,
      builder: (context) => BottomSheetFrame(
        title: context.l10n.t('lengthUnit'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LengthUnit.values
              .map(
                (item) => ListTile(
                  title: Text(context.l10n.unitName(item)),
                  trailing: item == state.unit
                      ? const Icon(Icons.check_circle, color: teal)
                      : null,
                  onTap: () => Navigator.pop(context, item),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (unit != null) await state.setUnit(unit);
  }

  Future<void> _chooseFootLength(BuildContext context) async {
    final rows = state.catalog.rowsFor(state.audience);
    final chosen = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheetFrame(
          title: context.l10n.t('selectFootLength'),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .62,
            child: GridView.builder(
              itemCount: rows.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final mm = rows[index].footMm;
                final selected = mm == state.footMm;
                return FilledButton.tonal(
                  onPressed: () => Navigator.pop(context, mm),
                  style: FilledButton.styleFrom(
                    backgroundColor: selected ? blue : null,
                    foregroundColor: selected ? Colors.white : null,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    compactNumber(
                      displayLength(mm, state.unit),
                      maxDecimals: state.unit == LengthUnit.inch ? 2 : 1,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    if (chosen != null) state.setFootMm(chosen);
  }

  Future<void> _chooseSystem(BuildContext context) async {
    final system = await showModalBottomSheet<SizeSystem>(
      context: context,
      builder: (context) => BottomSheetFrame(
        title: context.l10n.t('selectSystem'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: SizeSystem.values
              .map(
                (item) => ListTile(
                  title: Text(item.label),
                  trailing: item == state.knownSystem
                      ? const Icon(Icons.check_circle, color: teal)
                      : null,
                  onTap: () => Navigator.pop(context, item),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (system != null) state.setKnownSystem(system);
  }

  Future<void> _chooseKnownSize(BuildContext context) async {
    final values = state.catalog
        .rowsFor(state.audience)
        .map((row) => row.valueFor(state.knownSystem, state.audience))
        .whereType<num>()
        .toSet()
        .toList();
    final chosen = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BottomSheetFrame(
        title: '${context.l10n.t('selectSize')} · ${state.knownSystem.label}',
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .58,
          child: GridView.builder(
            itemCount: values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final value = values[index];
              final selected = value == state.knownValue;
              return FilledButton.tonal(
                onPressed: () => Navigator.pop(context, value),
                style: FilledButton.styleFrom(
                  backgroundColor: selected ? blue : null,
                  foregroundColor: selected ? Colors.white : null,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  compactNumber(value),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              );
            },
          ),
        ),
      ),
    );
    if (chosen != null) state.setKnownValue(chosen);
  }

  void _convert(BuildContext context) {
    final result = state.convert();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(state: state, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recent = state.recent.isEmpty
        ? ConversionResult(
            row: state.catalog.nearest(state.footMm, state.audience),
            audience: state.audience,
            input: ConversionInput.footLength,
          )
        : state.recent.first;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          AppPageHeader(
            title: l10n.t('appTitle'),
            subtitle: l10n.t('appSubtitle'),
            trailing: OutlinedButton.icon(
              onPressed: () => _chooseUnit(context),
              icon: const Icon(Icons.straighten_rounded, size: 18),
              label: Text(state.unit.symbol),
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(l10n.t('selectKnown')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  selected: state.input == ConversionInput.footLength,
                  icon: Icons.accessibility_new_rounded,
                  title: l10n.t('knowFoot'),
                  subtitle: l10n.t(
                    'footUnit',
                    args: {'unit': state.unit.symbol},
                  ),
                  onTap: () => state.setInput(ConversionInput.footLength),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  selected: state.input == ConversionInput.knownSize,
                  icon: Icons.ice_skating_rounded,
                  title: l10n.t('knowSize'),
                  subtitle: l10n.t('anySystem'),
                  onTap: () => state.setInput(ConversionInput.knownSize),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _chooseAudience(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(82, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.audience(state.audience),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (state.input == ConversionInput.knownSize) ...[
                OutlinedButton(
                  onPressed: () => _chooseSystem(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(78, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    state.knownSystem.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => state.input == ConversionInput.footLength
                      ? _chooseFootLength(context)
                      : _chooseKnownSize(context),
                  child: Ink(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(
                          state.input == ConversionInput.footLength
                              ? l10n.t('footLength')
                              : l10n.t('size'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          state.input == ConversionInput.footLength
                              ? formatLength(state.footMm, state.unit)
                              : compactNumber(state.knownValue),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (state.input == ConversionInput.footLength) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showMeasurementHelp(context),
              icon: const Icon(Icons.info_outline, size: 16),
              label: Text(l10n.t('howMeasure')),
              style: TextButton.styleFrom(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ] else
            const SizedBox(height: 12),
          PrimaryButton(
            label: l10n.t('start'),
            onPressed: () => _convert(context),
          ),
          const SizedBox(height: 22),
          SectionTitle(l10n.t('recent')),
          const SizedBox(height: 10),
          _RecentCard(
            state: state,
            result: recent,
            onTap: () => _convert(context),
          ),
          const SizedBox(height: 28),
          const AdPlaceholder(),
        ],
      ),
    );
  }

  void _showMeasurementHelp(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => BottomSheetFrame(
        title: l10n.t('measureTitle'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HelpStep(number: '1', text: l10n.t('measure1')),
            _HelpStep(number: '2', text: l10n.t('measure2')),
            _HelpStep(number: '3', text: l10n.t('measure3')),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? teal.withValues(alpha: .08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? teal
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? teal : Theme.of(context).colorScheme.outline,
                size: 21,
              ),
            ),
            Icon(icon, color: selected ? teal : blue, size: 43),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.state,
    required this.result,
    required this.onTap,
  });

  final AppState state;
  final ConversionResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = result.row;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
          child: Row(
            children: [
              const Icon(
                Icons.accessibility_new_rounded,
                color: teal,
                size: 32,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatLength(row.footMm, state.unit),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      context.l10n.audience(result.audience),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              ...[
                ('EU', row.eu),
                ('UK', row.uk),
                ('US', row.usFor(result.audience)),
                ('JP', row.jp),
                ('KR', row.kr),
                (
                  state.unit == LengthUnit.inch ? 'cm' : 'in',
                  state.unit == LengthUnit.inch
                      ? row.footMm / 10
                      : row.footMm / 25.4,
                ),
              ].map(
                (item) => Expanded(
                  child: Column(
                    children: [
                      Text(item.$1, style: const TextStyle(fontSize: 8)),
                      const SizedBox(height: 3),
                      Text(
                        compactNumber(item.$2),
                        style: const TextStyle(
                          color: blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: teal.withValues(alpha: .12),
            foregroundColor: teal,
            child: Text(number),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
