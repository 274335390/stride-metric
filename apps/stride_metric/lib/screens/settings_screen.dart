import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../l10n/app_localizations.dart';
import '../ui/app_theme.dart';
import '../ui/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('settings')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          SectionTitle(l10n.t('display')),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.translate_rounded,
                color: blue,
                title: l10n.t('language'),
                subtitle: state.language.nativeName,
                onTap: () => _showLanguages(context),
              ),
              _SettingsTile(
                icon: Icons.straighten_rounded,
                color: teal,
                title: l10n.t('lengthUnit'),
                subtitle: l10n.unitName(state.unit),
                onTap: () => _showUnits(context),
              ),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                color: const Color(0xFF7755EE),
                title: l10n.t('darkMode'),
                subtitle: l10n.t(state.darkMode ? 'enabled' : 'disabled'),
                trailing: Switch(
                  value: state.darkMode,
                  onChanged: state.setDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(l10n.t('data')),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.storage_rounded,
                color: const Color(0xFF0097CE),
                title: l10n.t('dataSources'),
                subtitle: l10n.t('dataSourcesSub'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _DataSourcesPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(l10n.t('help')),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.menu_book_outlined,
                color: const Color(0xFF00A3B9),
                title: l10n.t('guide'),
                subtitle: l10n.t('guideSub'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _HelpPage()),
                ),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                color: const Color(0xFF4D78D8),
                title: l10n.t('about'),
                subtitle: l10n.t('aboutSub'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _AboutPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showUnits(BuildContext context) async {
    final selected = await showModalBottomSheet<LengthUnit>(
      context: context,
      builder: (context) => BottomSheetFrame(
        title: context.l10n.t('lengthUnit'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LengthUnit.values
              .map(
                (unit) => ListTile(
                  title: Text(context.l10n.unitName(unit)),
                  trailing: state.unit == unit
                      ? const Icon(Icons.check_circle, color: teal)
                      : null,
                  onTap: () => Navigator.pop(context, unit),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (selected != null) await state.setUnit(selected);
  }

  Future<void> _showLanguages(BuildContext context) async {
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BottomSheetFrame(
        title: context.l10n.t('language'),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .66,
          child: ListView.builder(
            itemCount: AppLanguage.values.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(AppLanguage.values[index].nativeName),
              trailing: AppLanguage.values[index] == state.language
                  ? const Icon(Icons.check, color: blue)
                  : null,
              onTap: () => Navigator.pop(context, AppLanguage.values[index]),
            ),
          ),
        ),
      ),
    );
    if (selected != null) await state.setLanguage(selected);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 14,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _DataSourcesPage extends StatelessWidget {
  const _DataSourcesPage();
  @override
  Widget build(BuildContext context) => _SimplePage(
    title: context.l10n.t('dataSources'),
    children: [
      _InfoBlock(
        title: context.l10n.t('internationalStandard'),
        body:
            'ISO 19407:2023 · Footwear — Sizing — Conversion of sizing systems',
      ),
      _InfoBlock(
        title: context.l10n.t('chinaStandard'),
        body: context.l10n.t('chinaStandardBody'),
      ),
      _InfoBlock(
        title: context.l10n.t('brandCharts'),
        body: context.l10n.t('brandChartsBody'),
      ),
    ],
  );
}

class _HelpPage extends StatelessWidget {
  const _HelpPage();
  @override
  Widget build(BuildContext context) => _SimplePage(
    title: context.l10n.t('guide'),
    children: [
      _InfoBlock(
        title: context.l10n.t('guide1Title'),
        body: context.l10n.t('guide1Body'),
      ),
      _InfoBlock(
        title: context.l10n.t('guide2Title'),
        body: context.l10n.t('guide2Body'),
      ),
      _InfoBlock(
        title: context.l10n.t('guide3Title'),
        body: context.l10n.t('guide3Body'),
      ),
    ],
  );
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();
  @override
  Widget build(BuildContext context) => _SimplePage(
    title: '${context.l10n.t('about')} · StrideMetric',
    children: [
      _InfoBlock(title: context.l10n.t('version'), body: '1.0.0'),
      _InfoBlock(
        title: context.l10n.t('privacy'),
        body: context.l10n.t('privacyBody'),
      ),
      _InfoBlock(
        title: context.l10n.t('notice'),
        body: context.l10n.t('noticeBody'),
      ),
    ],
  );
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), centerTitle: true),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: children
          .expand((item) => [item, const SizedBox(height: 12)])
          .toList(growable: false),
    ),
  );
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(height: 1.5)),
        ],
      ),
    ),
  );
}
