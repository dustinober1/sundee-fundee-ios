import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/app/theme.dart';

void main() {
  test('theme token contrast meets WCAG AA for key text pairs', () {
    expect(
      _contrastRatio(AppColors.textPrimary, AppColors.surfaceLight),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(AppColors.textSecondary, AppColors.surfaceLight),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(AppColors.brandPrimary, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(AppColors.brandSecondary, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(AppColors.brandSecondary, AppColors.surfaceLight),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double _contrastRatio(Color a, Color b) {
  final double l1 = a.computeLuminance();
  final double l2 = b.computeLuminance();
  final double lighter = l1 > l2 ? l1 : l2;
  final double darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}
