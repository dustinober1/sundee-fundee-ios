import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class RecoverableAccessBanner extends StatelessWidget {
  const RecoverableAccessBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.retryAttempt,
    this.maxRetries,
    this.title = 'Connection issue',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final int? retryAttempt;
  final int? maxRetries;

  @override
  Widget build(BuildContext context) {
    final bool showAttempt = retryAttempt != null && maxRetries != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.wifi_tethering_error_rounded,
                size: 18,
                color: Colors.amber.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (showAttempt) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Retry ${retryAttempt!}/$maxRetries',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Checklist: check connection, keep app open, then retry.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
