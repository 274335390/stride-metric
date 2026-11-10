import 'dart:math' as math;

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
    var pickerAudience = state.audience;
    var rows = state.catalog.rowsFor(pickerAudience);
    var selectedMm = state.footMm;
    final chosen = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final selectedIndex = rows.indexWhere(
            (row) => row.footMm == selectedMm,
          );
          final gridRows = (rows.length / 5).ceil();
          final contentHeight = math
              .min(
                MediaQuery.sizeOf(context).height * .66,
                86 + 12 + 42 + 12 + gridRows * 50 + 14 + 54,
              )
              .toDouble();

          void selectAudience(Audience next) {
            setSheetState(() {
              pickerAudience = next;
              rows = state.catalog.rowsFor(next);
              selectedMm = rows
                  .reduce(
                    (a, b) =>
                        (a.footMm - selectedMm).abs() <=
                            (b.footMm - selectedMm).abs()
                        ? a
                        : b,
                  )
                  .footMm;
            });
          }

          return BottomSheetFrame(
            title: context.l10n.t('selectFootLength'),
            child: SizedBox(
              height: contentHeight,
              child: Column(
                children: [
                  Container(
                    height: 86,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _LengthStepButton(
                          icon: Icons.remove_rounded,
                          enabled: selectedIndex > 0,
                          onPressed: () => setSheetState(
                            () => selectedMm = rows[selectedIndex - 1].footMm,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            formatLength(selectedMm, state.unit),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        _LengthStepButton(
                          icon: Icons.add_rounded,
                          enabled:
                              selectedIndex >= 0 &&
                              selectedIndex < rows.length - 1,
                          onPressed: () => setSheetState(
                            () => selectedMm = rows[selectedIndex + 1].footMm,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<Audience>(
                    segments: [
                      ButtonSegment(
                        value: Audience.child,
                        label: Text(context.l10n.audience(Audience.child)),
                      ),
                      ButtonSegment(
                        value: state.audience == Audience.men
                            ? Audience.men
                            : Audience.women,
                        label: Text(
                          state.audience == Audience.men
                              ? context.l10n.audience(Audience.men)
                              : context.l10n.audience(Audience.women),
                        ),
                      ),
                    ],
                    selected: {pickerAudience},
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                    onSelectionChanged: (selection) =>
                        selectAudience(selection.first),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: rows.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisExtent: 42,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemBuilder: (context, index) {
                        final mm = rows[index].footMm;
                        final selected = mm == selectedMm;
                        return FilledButton.tonal(
                          onPressed: () => setSheetState(() => selectedMm = mm),
                          style: FilledButton.styleFrom(
                            backgroundColor: selected ? blue : null,
                            foregroundColor: selected ? Colors.white : null,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: Text(
                            compactNumber(
                              displayLength(mm, state.unit),
                              maxDecimals: state.unit == LengthUnit.inch
                                  ? 2
                                  : 1,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: context.l10n.t('done'),
                    onPressed: () => Navigator.pop(context, selectedMm),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (chosen != null) {
      state.setAudience(pickerAudience);
      state.setFootMm(chosen);
    }
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
          height: math.min(
            MediaQuery.sizeOf(context).height * .58,
            math.max(54, (values.length / 4).ceil() * 58),
          ),
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
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('brandUnavailable'))),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(state: state, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final previewRow = state.catalog
        .matchFootLength(state.footMm, state.audience)
        .row;
    final recent = state.recent.isEmpty && previewRow != null
        ? ConversionResult(
            row: previewRow,
            audience: state.audience,
            input: ConversionInput.footLength,
          )
        : state.recent.firstOrNull;
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
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(l10n.t('selectKnown')),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final audienceButton = OutlinedButton(
                onPressed: () => _chooseAudience(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(82, 56),
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 430 ? 10 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.audience(state.audience),
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              );
              final systemButton = OutlinedButton(
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
              );
              final valueButton = InkWell(
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
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            state.input == ConversionInput.footLength
                                ? l10n.t('footLength')
                                : l10n.t('size'),
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            state.input == ConversionInput.footLength
                                ? formatLength(state.footMm, state.unit)
                                : compactNumber(state.knownValue),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (constraints.maxWidth < 430 &&
                  state.input == ConversionInput.knownSize) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: audienceButton),
                        if (state.input == ConversionInput.knownSize) ...[
                          const SizedBox(width: 10),
                          Expanded(child: systemButton),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    valueButton,
                  ],
                );
              }

              return Row(
                children: [
                  if (constraints.maxWidth < 430)
                    Expanded(flex: 2, child: audienceButton)
                  else
                    audienceButton,
                  const SizedBox(width: 10),
                  if (state.input == ConversionInput.knownSize) ...[
                    systemButton,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: constraints.maxWidth < 430 ? 3 : 1,
                    child: valueButton,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showInputHelp(context),
              icon: const Icon(Icons.info_outline, size: 16),
              label: Text(
                l10n.t(
                  state.input == ConversionInput.footLength
                      ? 'howMeasure'
                      : 'checkSize',
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          PrimaryButton(
            label: l10n.t('start'),
            onPressed: () => _convert(context),
          ),
          const SizedBox(height: 22),
          SectionTitle(l10n.t('recent')),
          const SizedBox(height: 10),
          if (recent != null)
            _RecentCard(
              state: state,
              result: recent,
              onTap: () => _convert(context),
            ),
        ],
      ),
    );
  }

  void _showInputHelp(BuildContext context) {
    final l10n = context.l10n;
    final measuresFoot = state.input == ConversionInput.footLength;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BottomSheetFrame(
        title: l10n.t(measuresFoot ? 'measureTitle' : 'checkSize'),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .68,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (measuresFoot)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1.8,
                      child: Image.asset(
                        'assets/ui/foot-measure-guide.png',
                        fit: BoxFit.cover,
                        semanticLabel: l10n.t('measureTitle'),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 138,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: .07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Image.asset(
                            'assets/ui/shoe-outline-icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: blue.withValues(alpha: .35),
                              ),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SIZE', style: TextStyle(fontSize: 10)),
                                SizedBox(height: 3),
                                Text(
                                  'EU 41',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'US 9.5 · UK 7.5',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                for (var index = 1; index <= 3; index++)
                  _HelpStep(
                    number: '$index',
                    text: l10n.t(
                      measuresFoot ? 'measure$index' : 'checkSize$index',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LengthStepButton extends StatelessWidget {
  const _LengthStepButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(46),
        maximumSize: const Size.square(46),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: blue,
        side: BorderSide(color: blue.withValues(alpha: .24)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        constraints: const BoxConstraints(minHeight: 150),
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
            Text(
              title,
              maxLines: 3,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, height: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              textAlign: TextAlign.center,
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
