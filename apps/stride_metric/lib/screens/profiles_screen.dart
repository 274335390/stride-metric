import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../l10n/app_localizations.dart';
import '../ui/app_theme.dart';
import '../ui/widgets.dart';
import 'settings_screen.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          AppPageHeader(
            title: l10n.t('profilesTitle'),
            trailing: IconButton.outlined(
              tooltip: l10n.t('settings'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsScreen(state: state)),
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
          const SizedBox(height: 26),
          SectionTitle(
            l10n.t('myProfiles'),
            action: TextButton.icon(
              onPressed: () => _openEditor(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.t('new')),
            ),
          ),
          const SizedBox(height: 10),
          ...state.profiles.map(
            (profile) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: teal.withValues(alpha: .1),
                    child: const Icon(Icons.person_outline, color: teal),
                  ),
                  title: Text(
                    profile.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${l10n.audience(profile.audience)} · ${l10n.t('leftFoot')} ${formatLength(profile.leftFootMm, state.unit)} · ${l10n.t('rightFoot')} ${formatLength(profile.rightFootMm, state.unit)} · ${l10n.widthName(profile.width)}',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openEditor(context, profile),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, ShoeProfile? profile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditorScreen(
          state: state,
          isNew: profile == null,
          profile:
              profile ??
              ShoeProfile(
                name: context.l10n.t('newProfile'),
                audience: Audience.women,
                leftFootMm: 250,
                rightFootMm: 250,
              ),
        ),
      ),
    );
  }
}

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.isNew,
  });
  final AppState state;
  final ShoeProfile profile;
  final bool isNew;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final TextEditingController name;
  late Audience audience;
  late double left;
  late double right;
  late String width;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.profile.name);
    audience = widget.profile.audience;
    left = widget.profile.leftFootMm;
    right = widget.profile.rightFootMm;
    width = widget.profile.width;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('editProfile')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                minTileHeight: 72,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: teal.withValues(alpha: .1),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    color: teal,
                    size: 34,
                  ),
                ),
                title: Text(
                  l10n.t('avatar'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(l10n.t('chooseImage')),
                trailing: const Icon(Icons.image_outlined),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SizedBox(
                    height: 66,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            l10n.t('profileName'),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: name,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  SizedBox(
                    height: 66,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            l10n.t('defaultShoeType'),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: AudienceSegment(
                              value: audience,
                              onChanged: (value) =>
                                  setState(() => audience = value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionTitle(l10n.t('measurements')),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _MeasureTile(
                    label: l10n.t('leftFoot'),
                    value: formatLength(left, widget.state.unit),
                    onTap: () => _pickLength(true),
                  ),
                  const Divider(),
                  _MeasureTile(
                    label: l10n.t('rightFoot'),
                    value: formatLength(right, widget.state.unit),
                    onTap: () => _pickLength(false),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(l10n.t('footWidth')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.widthName(width),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: _pickWidth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.t('saveProfileButton'),
              onPressed: () async {
                final trimmedName = name.text.trim();
                if (trimmedName.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.t('enterName'))));
                  return;
                }
                await widget.state.saveProfile(
                  ShoeProfile(
                    name: trimmedName,
                    audience: audience,
                    leftFootMm: left,
                    rightFootMm: right,
                    width: width,
                  ),
                  originalName: widget.isNew ? null : widget.profile.name,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.t('profileSaved'))));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLength(bool isLeft) async {
    final rows = widget.state.catalog.rowsFor(audience);
    var pending = isLeft ? left : right;
    final selected = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final selectedIndex = rows.indexWhere(
            (row) => row.footMm == pending,
          );
          final estimatedHeight = 86 + 14 + (rows.length / 5).ceil() * 50 + 68;
          final contentHeight = estimatedHeight
              .clamp(258.0, MediaQuery.sizeOf(context).height * .66)
              .toDouble();

          return BottomSheetFrame(
            title: context.l10n.t(isLeft ? 'chooseLeft' : 'chooseRight'),
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
                        _ProfileLengthStepButton(
                          icon: Icons.remove_rounded,
                          enabled: selectedIndex > 0,
                          onPressed: () => setSheetState(
                            () => pending = rows[selectedIndex - 1].footMm,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            formatLength(pending, widget.state.unit),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        _ProfileLengthStepButton(
                          icon: Icons.add_rounded,
                          enabled:
                              selectedIndex >= 0 &&
                              selectedIndex < rows.length - 1,
                          onPressed: () => setSheetState(
                            () => pending = rows[selectedIndex + 1].footMm,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
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
                        final isSelected = mm == pending;
                        return FilledButton.tonal(
                          onPressed: () =>
                              setSheetState(() => pending = mm),
                          style: FilledButton.styleFrom(
                            backgroundColor: isSelected ? blue : null,
                            foregroundColor: isSelected ? Colors.white : null,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: Text(
                            compactNumber(
                              displayLength(mm, widget.state.unit),
                              maxDecimals:
                                  widget.state.unit == LengthUnit.inch ? 2 : 1,
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
                    onPressed: () => Navigator.pop(context, pending),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selected == null) return;
    setState(() {
      if (isLeft) {
        left = selected;
      } else {
        right = selected;
      }
    });
  }

  Future<void> _pickWidth() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => BottomSheetFrame(
        title: context.l10n.t('chooseWidth'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['narrow', 'regular', 'wide']
              .map(
                (item) => ListTile(
                  title: Text(context.l10n.widthName(item)),
                  trailing: width == item
                      ? const Icon(Icons.check_circle, color: teal)
                      : null,
                  onTap: () => Navigator.pop(context, item),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (selected != null) setState(() => width = selected);
  }
}

class _ProfileLengthStepButton extends StatelessWidget {
  const _ProfileLengthStepButton({
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

class _MeasureTile extends StatelessWidget {
  const _MeasureTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
