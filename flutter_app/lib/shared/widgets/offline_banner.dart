import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);

    return isOnlineAsync.when(
      data: (isOnline) {
        if (isOnline) {
          return const SizedBox.shrink();
        }
        return Container(
          key: const Key('offline-banner'),
          width: double.infinity,
          color: Colors.orange.shade800,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'You are offline',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const SizedBox.shrink(),
    );
  }
}
