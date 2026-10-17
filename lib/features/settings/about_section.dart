import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/aero_constants.dart';
import '../../core/services/apps_service.dart';

/// About section: version, licence, repository and honest feature status.
class AboutSection extends ConsumerStatefulWidget {
  const AboutSection({super.key});

  @override
  ConsumerState<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends ConsumerState<AboutSection> {
  String _version = 'Unknown';
  String _build = '0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await const AppsService().appVersion();
    if (!mounted) return;
    setState(() {
      _version = version.version;
      _build = version.build;
    });
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: Text('$_version (build $_build)'),
        ),
        ListTile(
          leading: const Icon(Icons.balance_outlined),
          title: const Text('Licence'),
          subtitle: const Text('MIT Licence'),
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () => _open('https://github.com/Skywave22/Aerodesk/blob/main/LICENSE'),
        ),
        ListTile(
          leading: const Icon(Icons.code_outlined),
          title: const Text('Source repository'),
          subtitle: const Text('github.com/Skywave22/Aerodesk'),
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () => _open('https://github.com/Skywave22/Aerodesk'),
        ),
        const Divider(height: 24),
        Text('Feature status', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        const _StatusRow(label: 'Desktop, dock and window manager', status: 'Implemented'),
        const _StatusRow(label: 'AeroFiles file management', status: 'Implemented'),
        const _StatusRow(label: 'Notes, Calculator and Clock modules', status: 'Implemented'),
        const _StatusRow(label: 'Phone, tablet and large-screen layouts', status: 'Implemented'),
        const _StatusRow(label: 'Keyboard and mouse input', status: 'Implemented'),
        const _StatusRow(label: 'Signed release builds', status: 'Planned'),
        const _StatusRow(label: 'Optional AI add-ons', status: 'Planned · not in this app'),
        const SizedBox(height: 8),
        Text(
          '${AeroConstants.appName} contains no AI APIs, models or subscriptions. '
          'The architecture is modular so AI features can be evaluated as optional add-ons later.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final implemented = status.startsWith('Implemented');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Icon(
            implemented ? Icons.check_circle_outline : Icons.schedule_outlined,
            size: 16,
            color: implemented ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
