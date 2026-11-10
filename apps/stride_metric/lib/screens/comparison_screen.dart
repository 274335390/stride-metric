import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../l10n/app_localizations.dart';
import '../ui/app_theme.dart';
import '../ui/widgets.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  bool brandMode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final standardRows = state.catalog.rowsFor(state.audience);
    final matchingBrands = state.catalog.brandsFor(state.audience);
    final brand = matchingBrands
        .where((item) => item.name == state.selectedBrand)
        .firstOrNull;
    final table = brandMode && brand != null
        ? _brandTable(brand, state.audience, l10n)
        : _standardTable(standardRows, state.audience, state.unit, l10n);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(title: l10n.t('tableTitle')),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: InputDecoration(
                      hintText: brandMode
                          ? l10n.t('searchBrand')
                          : l10n.t('searchStandard'),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              height: brandMode ? 148 : 66,
              child: _PinnedFilters(
                audience: state.audience,
                brandMode: brandMode,
                brand: brand,
                fallbackName: state.selectedBrand,
                count: brand?.rows.length ?? 0,
                onAudienceChanged: state.setAudience,
                onModeChanged: (value) => setState(() => brandMode = value),
                onChooseBrand: () => _chooseBrand(context, matchingBrands),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TableHeaderDelegate(columns: table.columns),
          ),
          if (brandMode && brand == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 46,
                        color: blue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.t(
                          'unavailable',
                          args: {
                            'brand': state.selectedBrand,
                            'audience': l10n.audience(state.audience),
                          },
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => _chooseBrand(context, matchingBrands),
                        child: Text(l10n.t('chooseOther')),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: table.rows.length,
              itemBuilder: (context, index) => _TableRow(
                values: table.rows[index],
                highlighted: table.highlightedIndex == index,
                odd: index.isOdd,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Future<void> _chooseBrand(
    BuildContext context,
    List<BrandDataset> brands,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BottomSheetFrame(
        title: context.l10n.t('chooseBrand'),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .6,
          child: ListView.separated(
            itemCount: brands.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final brand = brands[index];
              final selected = brand.name == widget.state.selectedBrand;
              return ListTile(
                tileColor: selected
                    ? teal.withValues(alpha: .08)
                    : Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: selected ? teal : Theme.of(context).dividerColor,
                  ),
                ),
                leading: _BrandLogo(name: brand.name),
                title: Text(
                  brand.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  context.l10n.t(
                    'officialSizes',
                    args: {'count': brand.rows.length},
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_circle, color: teal)
                    : const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, brand.name),
              );
            },
          ),
        ),
      ),
    );
    if (selected != null) await widget.state.setBrand(selected);
  }
}

class _TableData {
  const _TableData({
    required this.columns,
    required this.rows,
    this.highlightedIndex,
  });
  final List<String> columns;
  final List<List<String>> rows;
  final int? highlightedIndex;
}

_TableData _standardTable(
  List<StandardSizeRow> source,
  Audience audience,
  LengthUnit unit,
  AppLocalizations l10n,
) {
  final complement = unit == LengthUnit.inch ? 'cm' : 'in';
  final rows = source
      .map((row) {
        return [
          compactNumber(
            displayLength(row.footMm, unit),
            maxDecimals: unit == LengthUnit.inch ? 2 : 1,
          ),
          compactNumber(row.eu),
          compactNumber(row.uk),
          compactNumber(row.usFor(audience)),
          compactNumber(row.jp),
          compactNumber(row.kr),
          unit == LengthUnit.inch
              ? compactNumber(row.footMm / 10)
              : compactNumber(row.footMm / 25.4),
        ];
      })
      .toList(growable: false);
  final highlight = source.indexWhere((row) => (row.footMm - 260).abs() < .01);
  return _TableData(
    columns: [unit.symbol, 'EU', 'UK', 'US', 'JP', 'KR', complement],
    rows: rows,
    highlightedIndex: highlight < 0 ? null : highlight,
  );
}

_TableData _brandTable(
  BrandDataset brand,
  Audience audience,
  AppLocalizations l10n,
) {
  final columns = brand.columns;
  int indexOf(List<String> candidates) {
    for (final candidate in candidates) {
      final index = columns.indexOf(candidate);
      if (index >= 0) return index;
    }
    return -1;
  }

  final footIndex = indexOf([
    'footLengthMm',
    'heelToeMm',
    'heelToeCm',
    'footLengthCm',
    'lengthCm',
    'footLengthIn',
    'lengthIn',
  ]);
  final euIndex = indexOf(['eu', 'euDisplay', 'de']);
  final ukIndex = indexOf(['uk']);
  final usIndex = audience == Audience.men
      ? indexOf(['usMen', 'us', 'usKids', 'usToddler'])
      : audience == Audience.women
      ? indexOf(['usWomen', 'us', 'usKids', 'usToddler'])
      : indexOf(['usKids', 'us', 'usYouth', 'usToddler']);
  final labelIndex = indexOf([
    'jpLabelCm',
    'jpLabelMm',
    'cmLabel',
    'cmJpLabel',
    'japanLabelCm',
  ]);
  String read(List<dynamic> row, int index) =>
      index < 0 || index >= row.length || row[index] == null
      ? '—'
      : row[index].toString().replaceFirst(RegExp(r'\.0$'), '');

  return _TableData(
    columns: [l10n.t('footLength'), 'EU', 'UK', 'US', l10n.t('shoeLabel')],
    rows: brand.rows
        .map(
          (row) => [
            read(row, footIndex),
            read(row, euIndex),
            read(row, ukIndex),
            read(row, usIndex),
            read(row, labelIndex),
          ],
        )
        .toList(growable: false),
  );
}

class _TableHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TableHeaderDelegate({required this.columns});
  final List<String> columns;

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: overlapsContent ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(
            children: columns
                .map(
                  (column) => Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        column,
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TableHeaderDelegate oldDelegate) =>
      oldDelegate.columns != columns;
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.values,
    required this.highlighted,
    required this.odd,
  });
  final List<String> values;
  final bool highlighted;
  final bool odd;

  @override
  Widget build(BuildContext context) {
    final color = highlighted
        ? blue.withValues(alpha: .10)
        : odd
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: .55),
            ),
          ),
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            children: values
                .map(
                  (value) => Expanded(
                    child: Center(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: highlighted
                              ? FontWeight.w900
                              : FontWeight.w600,
                          color: highlighted ? blue : null,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _BrandSelector extends StatelessWidget {
  const _BrandSelector({
    required this.brand,
    required this.fallbackName,
    required this.count,
    required this.onTap,
  });
  final BrandDataset? brand;
  final String fallbackName;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = brand?.name ?? fallbackName;
    return Card(
      margin: EdgeInsets.zero,
      color: blue.withValues(alpha: .05),
      child: ListTile(
        onTap: onTap,
        leading: _BrandLogo(name: name),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          count == 0
              ? context.l10n.t(
                  'unavailable',
                  args: {
                    'brand': name,
                    'audience': context.l10n.audience(Audience.women),
                  },
                )
              : context.l10n.t('officialSizes', args: {'count': count}),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.t('changeBrand'),
              style: const TextStyle(color: blue, fontSize: 12),
            ),
            const Icon(Icons.chevron_right, color: blue),
          ],
        ),
      ),
    );
  }
}

class _PinnedFilters extends StatelessWidget {
  const _PinnedFilters({
    required this.audience,
    required this.brandMode,
    required this.brand,
    required this.fallbackName,
    required this.count,
    required this.onAudienceChanged,
    required this.onModeChanged,
    required this.onChooseBrand,
  });

  final Audience audience;
  final bool brandMode;
  final BrandDataset? brand;
  final String fallbackName;
  final int count;
  final ValueChanged<Audience> onAudienceChanged;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onChooseBrand;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AudienceSegment(
                    value: audience,
                    onChanged: onAudienceChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.l10n.t('standard'),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                      ButtonSegment(
                        value: true,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.l10n.t('brand'),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                    selected: {brandMode},
                    expandedInsets: EdgeInsets.zero,
                    onSelectionChanged: (value) => onModeChanged(value.first),
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (brandMode) ...[
              const SizedBox(height: 10),
              _BrandSelector(
                brand: brand,
                fallbackName: fallbackName,
                count: count,
                onTap: onChooseBrand,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FilterHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.name});

  final String name;

  String? get asset => switch (name.toLowerCase()) {
    'adidas' => 'assets/brands/adidas.svg',
    'asics' => 'assets/brands/asics.svg',
    'converse' => 'assets/brands/converse.svg',
    'new balance' => 'assets/brands/new-balance.svg',
    'nike' => 'assets/brands/nike.svg',
    'puma' => 'assets/brands/puma.svg',
    'reebok' => 'assets/brands/reebok.svg',
    'skechers' => 'assets/brands/skechers.svg',
    'vans' => 'assets/brands/vans.svg',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: asset == null
          ? Icon(
              Icons.storefront_rounded,
              size: 25,
              color: Theme.of(context).colorScheme.onSurface,
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                asset!,
                semanticsLabel: name,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
    );
  }
}
