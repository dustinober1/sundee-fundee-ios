import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  const RestTimerState({
    required this.isRunning,
    required this.durationSeconds,
    required this.remainingSeconds,
  });

  final bool isRunning;
  final int durationSeconds;
  final int remainingSeconds;

  RestTimerState copyWith({
    bool? isRunning,
    int? durationSeconds,
    int? remainingSeconds,
  }) {
    return RestTimerState(
      isRunning: isRunning ?? this.isRunning,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

class RestTimerNotifier extends AutoDisposeNotifier<RestTimerState> {
  Timer? _timer;

  @override
  RestTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const RestTimerState(
      isRunning: false,
      durationSeconds: 0,
      remainingSeconds: 0,
    );
  }

  void startTimer(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      isRunning: true,
      durationSeconds: seconds,
      remainingSeconds: seconds,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        stopTimer();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
  }

  void addTime(int seconds) {
    if (!state.isRunning) return;
    state = state.copyWith(remainingSeconds: state.remainingSeconds + seconds);
  }

  void subtractTime(int seconds) {
    if (!state.isRunning) return;
    final newTime = state.remainingSeconds - seconds;
    state = state.copyWith(remainingSeconds: newTime > 0 ? newTime : 0);
  }
}

final restTimerProvider =
    AutoDisposeNotifierProvider<RestTimerNotifier, RestTimerState>(
  RestTimerNotifier.new,
);
