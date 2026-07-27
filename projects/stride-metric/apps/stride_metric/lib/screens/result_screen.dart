import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../l10n/app_localizations.dart';
import '../ui/app_theme.dart';
import '../ui/widgets.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.state, required this.result});

  final AppState state;
  final ConversionResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final row = result.row;
    final known = result.input == ConversionInput.knownSize;
    final mainLabel = known ? result.inputSystem!.label : l10n.t('footLength');
    final mainValue = known
        ? compactNumber(result.inputValue)
        : formatLength(row.footMm, state.unit);
    final complementaryLabel = state.unit == LengthUnit.inch ? 'cm' : 'in';
    final complementaryValue = state.unit == LengthUnit.inch
        ? row.footMm / 10
        : row.footMm / 25.4;
    final cells = <(String, num?)>[
      if (!(known && result.inputSystem == SizeSystem.eu)) ('EU', row.eu),
      if (!(known && result.inputSystem == SizeSystem.uk)) ('UK', row.uk),
      if (!(known && result.inputSystem == SizeSystem.us))
        ('US', row.usFor(result.audience)),
      if (!(known && result.inputSystem == SizeSystem.jp)) ('JP', row.jp),
      if (!(known && result.inputSystem == SizeSystem.kr)) ('KR', row.kr),
      (complementaryLabel, complementaryValue),
    ];
    final brandMatches = state.catalog.nearestBrandMatches(
      row.footMm,
      result.audience,
      limit: 3,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.t('result'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          l10n.t(
                            known ? 'fromSize' : 'fromFoot',
                            args: {'audience': l10n.audience(result.audience)},
                          ),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  Container(
                    height: 156,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Text(
                          mainLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              mainValue,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionTitle(l10n.t('corresponding')),
                  const SizedBox(height: 10),
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cells.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.65,
                          ),
                      itemBuilder: (context, index) {
                        final cell = cells[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: index % 3 == 2
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                              bottom: index >= cells.length - 3
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cell.$1,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                compactNumber(cell.$2),
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: teal, size: 19),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.t('brandVariance'),
                            style: const TextStyle(fontSize: 13, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (brandMatches.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SectionTitle(l10n.t('brandReference')),
                    const SizedBox(height: 10),
                    Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < brandMatches.length;
                            index++
                          ) ...[
                            _BrandMatchRow(match: brandMatches[index]),
                            if (index != brandMatches.length - 1)
                              const Divider(),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _saveProfile(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(l10n.t('saveProfile')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(l10n.t('convertAgain')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: l10n.t('myProfiles'));
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('saveProfile')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.t('profileName'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.t('save')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    await state.saveProfile(
      ShoeProfile(
        name: name,
        audience: result.audience,
        leftFootMm: result.row.footMm,
        rightFootMm: result.row.footMm,
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('savedTo', args: {'name': name}))),
    );
  }
}

class _BrandMatchRow extends StatelessWidget {
  const _BrandMatchRow({required this.match});

  final BrandSizeMatch match;

  @override
  Widget build(BuildContext context) {
    String value(Object? raw) {
      if (raw == null) return '—';
      if (raw is num) return compactNumber(raw);
      return '$raw'.replaceFirst(RegExp(r'\.0$'), '');
    }

    final cells = [
      ('US', match.us),
      ('UK', match.uk),
      ('EU', match.eu),
      (context.l10n.t('shoeLabel'), match.label),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              match.brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          ...cells.map(
            (item) => Expanded(
              child: Column(
                children: [
                  Text(
                    item.$1,
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value(item.$2),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
