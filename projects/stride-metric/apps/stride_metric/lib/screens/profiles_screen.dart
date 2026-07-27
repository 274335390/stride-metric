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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: teal.withValues(alpha: .1),
                    child: const Icon(Icons.person_outline, color: teal),
                  ),
                  title: Text(l10n.t('avatar')),
                  subtitle: Text(l10n.t('chooseImage')),
                  trailing: const Icon(Icons.image_outlined),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: l10n.t('profileName'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: AudienceSegment(
                    value: audience,
                    onChanged: (value) => setState(() => audience = value),
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
    );
  }

  Future<void> _pickLength(bool isLeft) async {
    final rows = widget.state.catalog.rowsFor(audience);
    final selected = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BottomSheetFrame(
        title: context.l10n.t(isLeft ? 'chooseLeft' : 'chooseRight'),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .58,
          child: GridView.builder(
            itemCount: rows.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) => FilledButton.tonal(
              onPressed: () => Navigator.pop(context, rows[index].footMm),
              child: Text(
                compactNumber(
                  displayLength(rows[index].footMm, widget.state.unit),
                  maxDecimals: widget.state.unit == LengthUnit.inch ? 2 : 1,
                ),
              ),
            ),
          ),
        ),
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
