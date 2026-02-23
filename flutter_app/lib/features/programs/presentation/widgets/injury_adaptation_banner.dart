import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/models/injury_profile_model.dart';
import '../../providers/adapted_program_provider.dart';

/// A banner widget that surfaces the injury-adaptation disclaimer and changelog
/// to users with active injuries.
///
/// **Three visual states:**
/// - **State A (disclaimer gate):** Shown when disclaimer has NOT been
///   acknowledged for all active injuries. Renders a prominent card with full
///   disclaimer text and an "I UNDERSTAND" button. Content below is gated until
///   this is acknowledged.
/// - **State B (acknowledged, expanded):** Compact card showing injury count
///   badge, changelog summary, and persistent reminder text.
/// - **State C (acknowledged, collapsed):** Minimal TextButton.icon to re-open
///   expanded state.
///
/// The widget does NOT manage its own expanded/collapsed state — the parent
/// screen manages it via [visible] + [onToggleVisibility], matching the
/// [CycleAdjustmentExplainer] pattern.
class InjuryAdaptationBanner extends StatelessWidget {
  const InjuryAdaptationBanner({
    super.key,
    required this.injuryContext,
    required this.adaptationChangelog,
    required this.visible,
    required this.onToggleVisibility,
    required this.onAcknowledgeDisclaimer,
  });

  final InjuryAdaptationContext injuryContext;
  final List<String> adaptationChangelog;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final Future<void> Function(String injuryId) onAcknowledgeDisclaimer;

  static const int _maxChangelogEntries = 4;

  @override
  Widget build(BuildContext context) {
    // State A — disclaimer gate
    if (!injuryContext.disclaimerAcknowledgedForAll) {
      return _DisclaimerGateCard(
        injuryContext: injuryContext,
        onAcknowledgeDisclaimer: onAcknowledgeDisclaimer,
      );
    }

    // State C — collapsed
    if (!visible) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onToggleVisibility,
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('Show injury adaptations'),
        ),
      );
    }

    // State B — acknowledged, expanded
    return _ExpandedAdaptationCard(
      injuryContext: injuryContext,
      adaptationChangelog: adaptationChangelog,
      maxEntries: _maxChangelogEntries,
      onToggleVisibility: onToggleVisibility,
    );
  }
}

// ---------------------------------------------------------------------------
// State A — Disclaimer Gate Card
// ---------------------------------------------------------------------------

class _DisclaimerGateCard extends StatefulWidget {
  const _DisclaimerGateCard({
    required this.injuryContext,
    required this.onAcknowledgeDisclaimer,
  });

  final InjuryAdaptationContext injuryContext;
  final Future<void> Function(String injuryId) onAcknowledgeDisclaimer;

  @override
  State<_DisclaimerGateCard> createState() => _DisclaimerGateCardState();
}

class _DisclaimerGateCardState extends State<_DisclaimerGateCard> {
  bool _acknowledging = false;

  Future<void> _handleAcknowledge() async {
    if (_acknowledging) return;
    setState(() => _acknowledging = true);
    try {
      // Call callback for each unacknowledged active injury
      for (final InjuryProfileModel injury
          in widget.injuryContext.activeInjuries) {
        await widget.onAcknowledgeDisclaimer(injury.id);
      }
    } finally {
      if (mounted) {
        setState(() => _acknowledging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.health_and_safety,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Injury-Adapted Plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This plan has been modified based on your injury profile. '
              'Exercises have been replaced with safer alternatives and recovery '
              'prep has been added.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This is not medical advice. Consult a qualified healthcare '
              'professional before beginning or modifying any exercise program. '
              'Generated guidance is not a substitute for medical advice or '
              'physical therapy.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _acknowledging ? null : _handleAcknowledge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _acknowledging
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'I UNDERSTAND',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State B — Acknowledged, Expanded Card
// ---------------------------------------------------------------------------

class _ExpandedAdaptationCard extends StatelessWidget {
  const _ExpandedAdaptationCard({
    required this.injuryContext,
    required this.adaptationChangelog,
    required this.maxEntries,
    required this.onToggleVisibility,
  });

  final InjuryAdaptationContext injuryContext;
  final List<String> adaptationChangelog;
  final int maxEntries;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final int injuryCount = injuryContext.activeInjuries.length;
    final String injuryLabel =
        injuryCount == 1 ? '1 active injury' : '$injuryCount active injuries';

    final int overflowCount =
        (adaptationChangelog.length - maxEntries).clamp(0, adaptationChangelog.length);
    final List<String> visibleEntries =
        adaptationChangelog.take(maxEntries).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header row: icon + label + badge + collapse button
            Row(
              children: <Widget>[
                const Icon(Icons.health_and_safety, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Plan adapted for $injuryLabel',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                // Badge pill
                _InjuryCountBadge(count: injuryCount),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: onToggleVisibility,
                  tooltip: 'Collapse',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            // Changelog entries
            if (adaptationChangelog.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...visibleEntries.map(
                    (String entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.swap_horiz,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (overflowCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+ $overflowCount more change${overflowCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Persistent reminder — always visible
            const Text(
              'Not medical advice. Consult a healthcare professional.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small badge pill showing injury count
// ---------------------------------------------------------------------------

class _InjuryCountBadge extends StatelessWidget {
  const _InjuryCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.orange,
        ),
      ),
    );
  }
}
