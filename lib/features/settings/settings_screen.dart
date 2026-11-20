import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router.dart';
import '../../data/data_providers.dart';
import '../../data/database.dart';
import '../../data/knees.dart';
import '../../widgets/knee_picker.dart';
import '../../data/export.dart';
import '../../theme/tokens.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stark_primitives.dart';
import 'reminders_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            PageHeader(title: 'Settings', onBack: () => context.pop()),
            const _KneesSection(),
            const RemindersSection(),
            const SizedBox(height: JSpace.lg),
            const Hairline(),
            const _ExportRow(),
            StarkRow(
              title: 'Components',
              subtitle: 'Design system preview',
              onTap: () => context.push(Routes.components),
            ),
            const Padding(
              padding: EdgeInsets.all(JSpace.gutter),
              child: Text(
                'Joint+ is not medical advice. Follow your clinician\'s guidance. '
                'Stop and contact them if your knee locks, gives way, swells '
                'suddenly, or you cannot bear weight.',
                style: JType.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shares everything recorded as one JSON file, via the system share sheet.
class _ExportRow extends ConsumerStatefulWidget {
  const _ExportRow();

  @override
  ConsumerState<_ExportRow> createState() => _ExportRowState();
}

class _ExportRowState extends ConsumerState<_ExportRow> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    final box = context.findRenderObject() as RenderBox?;
    try {
      final now = ref.read(clockProvider)();
      final json = encodeExport(
        await buildExport(ref.read(databaseProvider), now: now),
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(utf8.encode(json), mimeType: 'application/json'),
          ],
          fileNameOverrides: ['joint-plus-${dayKey(now)}.json'],
          subject: 'Joint+ data',
          // iPad needs to know where to anchor the share sheet.
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      debugPrint('Export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't export your data.")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StarkRow(
      title: 'Export data',
      subtitle: _busy
          ? 'Preparing…'
          : 'Sessions, check-ins and phase changes as JSON',
      onTap: _busy ? null : _export,
    );
  }
}

/// Which knees are in rehab. Changes the next session and check-in.
class _KneesSection extends ConsumerWidget {
  const _KneesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(kneeSetupProvider).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        JSpace.gutter,
        JSpace.lg,
        JSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Recovering knee'),
          const SizedBox(height: JSpace.md),
          KneePicker(
            value: setup,
            onChanged: (v) => saveKneeSetup(ref.read(databaseProvider), v),
          ),
          const SizedBox(height: JSpace.sm),
          Text(
            setup == null
                ? 'Not set: one-leg exercises say "injured leg".'
                : setup.both
                ? 'Exercises for the recovering knee run on both, one after '
                      'the other. The check-in asks about each knee.'
                : 'One-leg exercises start on the ${setup.first.label.toLowerCase()} leg.',
            style: JType.secondary,
          ),
        ],
      ),
    );
  }
}
