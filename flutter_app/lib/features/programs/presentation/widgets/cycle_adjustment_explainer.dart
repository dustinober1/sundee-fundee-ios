import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/calculations/cycle_adaptation_policy.dart';
import '../../../../domain/enums.dart';

class CycleAdjustmentExplainer extends StatelessWidget {
  const CycleAdjustmentExplainer({
    super.key,
    required this.phase,
    required this.confidence,
    required this.visible,
    required this.onToggleVisibility,
    this.showRecalculationBadge = false,
  });

  final CyclePhase? phase;
  final AdaptationConfidence confidence;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final bool showRecalculationBadge;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onToggleVisibility,
          icon: const Icon(Icons.visibility),
          label: const Text('Show cycle adjustment details'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.tune, color: AppColors.brandPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _phaseReason(phase),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _confidenceCopy(confidence),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (showRecalculationBadge) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.brandPrimary.withValues(alpha: 0.08),
                ),
                child: const Text(
                  'Updated from latest cycle edit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onToggleVisibility,
                icon: const Icon(Icons.visibility_off),
                label: const Text('Hide details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseReason(CyclePhase? value) {
    switch (value) {
      case CyclePhase.menstrual:
        return 'Cycle-adjusted: reduced load and volume for recovery support.';
      case CyclePhase.follicular:
        return 'Cycle-adjusted: neutral base progression for this phase.';
      case CyclePhase.ovulation:
        return 'Cycle-adjusted: higher intensity while energy is typically high.';
      case CyclePhase.luteal:
        return 'Cycle-adjusted: controlled intensity to protect recovery.';
      case null:
        return 'Cycle-adjusted with fallback guidance from recent cycle data.';
    }
  }

  String _confidenceCopy(AdaptationConfidence value) {
    switch (value) {
      case AdaptationConfidence.high:
        return 'Confidence: high. Adjustments are fully applied.';
      case AdaptationConfidence.medium:
        return 'Confidence: medium. Adjustments are moderately scaled.';
      case AdaptationConfidence.low:
        return 'Confidence: low. Conservative scaling is active.';
    }
  }
}
