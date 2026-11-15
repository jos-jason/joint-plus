import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tokens.dart';
import '../../widgets/page_header.dart';
import '../../widgets/pain_scale.dart';
import '../../widgets/stark_button.dart';
import '../../widgets/stark_primitives.dart';
import '../../widgets/timer_ring.dart';

/// Live preview of the stark primitives, for checking the look on a device.
class ComponentsScreen extends StatefulWidget {
  const ComponentsScreen({super.key});

  @override
  State<ComponentsScreen> createState() => _ComponentsScreenState();
}

class _ComponentsScreenState extends State<ComponentsScreen> {
  static const _holdSeconds = 40;

  int? _pain;
  int _elapsed = 0;
  Timer? _timer;

  void _toggleTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() => _timer = null);
      return;
    }
    if (_elapsed >= _holdSeconds) _elapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _elapsed++;
        if (_elapsed >= _holdSeconds) {
          t.cancel();
          _timer = null;
        }
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            PageHeader(title: 'Components', onBack: () => context.pop()),
            const Hairline(),
            _section('Timer ring', [
              Center(
                child: TimerRing(
                  progress: _elapsed / _holdSeconds,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${_holdSeconds - _elapsed}', style: JType.display),
                      const SizedBox(height: JSpace.xs),
                      const SectionLabel('Hold · sec'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: JSpace.lg),
              StarkButton.secondary(
                label: _timer == null ? 'Start hold' : 'Pause',
                onPressed: _toggleTimer,
              ),
            ]),
            _section('Pain scale', [
              PainScale(
                value: _pain,
                onChanged: (v) => setState(() => _pain = v),
              ),
            ]),
            _section('Buttons', [
              StarkButton(label: 'Primary', onPressed: () {}),
              const SizedBox(height: JSpace.md),
              StarkButton.secondary(label: 'Secondary', onPressed: () {}),
              const SizedBox(height: JSpace.md),
              const StarkButton(label: 'Disabled', onPressed: null),
            ]),
            _section('Type', const [
              Text('12', style: JType.display),
              SizedBox(height: JSpace.md),
              Text('Spanish Squat', style: JType.title),
              SizedBox(height: JSpace.sm),
              Text('Shins vertical, sit back', style: JType.heading),
              SizedBox(height: JSpace.sm),
              Text('Body text for cues and instructions.', style: JType.body),
              SizedBox(height: JSpace.xs),
              Text('Secondary detail text.', style: JType.secondary),
              SizedBox(height: JSpace.sm),
              SectionLabel('Section label'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String label, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(JSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionLabel(label),
              const SizedBox(height: JSpace.lg),
              ...children,
            ],
          ),
        ),
        const Hairline(),
      ],
    );
  }
}
