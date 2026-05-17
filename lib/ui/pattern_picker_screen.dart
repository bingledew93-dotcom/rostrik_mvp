import 'package:flutter/material.dart';

import 'pattern_picker_body.dart';

/// Post-onboarding pattern picker.
///
/// Thin Scaffold wrapper around [PatternPickerBody] with no roster-type
/// restriction — surfaces all three category sections (Rotating Swings,
/// Day Only Swings, Night Only Swings) plus the Custom Builder escape
/// hatch.
///
/// Routed from `RosterScreen`'s AppBar and from Settings → "Add
/// another rotation". On successful generation (preset or Custom
/// Builder), pops back to the previous route.
class PatternPickerScreen extends StatelessWidget {
  const PatternPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a pattern')),
      body: PatternPickerBody(
        onGenerated: () => Navigator.of(context).pop(),
      ),
    );
  }
}
