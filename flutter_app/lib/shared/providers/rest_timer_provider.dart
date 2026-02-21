import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

/// Immutable state for the rest timer.
class RestTimerState {
  final String status; // 'idle', 'running', 'paused', 'complete'
  final int durationSeconds;
  final int remainingSeconds;
  final DateTime? startedAt;
  final String? exerciseName;

  const RestTimerState({
    required this.status,
    required this.durationSeconds,
    required this.remainingSeconds,
    this.startedAt,
    this.exerciseName,
  });

  RestTimerState copyWith({
    String? status,
    int? durationSeconds,
    int? remainingSeconds,
    DateTime? startedAt,
    String? exerciseName,
  }) {
    return RestTimerState(
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      startedAt: startedAt ?? this.startedAt,
      exerciseName: exerciseName ?? this.exerciseName,
    );
  }

  String get displayTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (durationSeconds == 0) return 0;
    return remainingSeconds / durationSeconds;
  }

  bool get isRunning => status == 'running';
  bool get isPaused => status == 'paused';
  bool get isComplete => status == 'complete';
  bool get isIdle => status == 'idle';
}

class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _timer;
  _LifecycleObserver? _lifecycleObserver;

  @override
  RestTimerState build() {
    _lifecycleObserver = _LifecycleObserver(
      onResumed: _recalculateRemainingTime,
      onPaused: _pauseTimerForBackground,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    ref.onDispose(() {
      _timer?.cancel();
      if (_lifecycleObserver != null) {
        WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
      }
    });

    return const RestTimerState(
      status: 'idle',
      durationSeconds: 0,
      remainingSeconds: 0,
    );
  }

  void startRest(int durationSeconds, [String? exerciseName]) {
    _timer?.cancel();
    state = RestTimerState(
      status: 'running',
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      startedAt: DateTime.now(),
      exerciseName: exerciseName,
    );
    _startCountdown();
  }

  void pause() {
    if (state.status != 'running') return;
    _timer?.cancel();
    state = state.copyWith(status: 'paused');
  }

  void resume() {
    if (state.status != 'paused') return;
    state = state.copyWith(
      status: 'running',
      startedAt: DateTime.now().subtract(
        Duration(seconds: state.durationSeconds - state.remainingSeconds),
      ),
    );
    _startCountdown();
  }

  void skip() {
    _timer?.cancel();
    state = state.copyWith(status: 'complete', remainingSeconds: 0);
  }

  void cancel() {
    _timer?.cancel();
    state = const RestTimerState(
      status: 'idle',
      durationSeconds: 0,
      remainingSeconds: 0,
    );
  }

  void addTime([int seconds = 15]) {
    if (state.isIdle) return;
    state = state.copyWith(
      durationSeconds: state.durationSeconds + seconds,
      remainingSeconds: state.remainingSeconds + seconds,
    );
  }

  void subtractTime([int seconds = 15]) {
    if (state.isIdle) return;
    final newRemaining =
        (state.remainingSeconds - seconds).clamp(0, state.durationSeconds);
    if (newRemaining <= 0) {
      _completeTimer();
    } else {
      state = state.copyWith(remainingSeconds: newRemaining);
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        timer.cancel();
        _completeTimer();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void _completeTimer() {
    state = state.copyWith(status: 'complete', remainingSeconds: 0);
    _triggerVibration();
  }

  void _pauseTimerForBackground() {
    // Only cancel the timer — does NOT change status to 'paused'.
    // This preserves the 'running' status so _recalculateRemainingTime
    // can correctly recalculate elapsed time on foreground return.
    if (state.isRunning) _timer?.cancel();
  }

  void _recalculateRemainingTime() {
    if (!state.isRunning && !state.isPaused) return;
    if (state.startedAt == null) return;

    final elapsed = DateTime.now().difference(state.startedAt!).inSeconds;
    final remaining = state.durationSeconds - elapsed;

    if (remaining <= 0) {
      _completeTimer();
    } else {
      state = state.copyWith(remainingSeconds: remaining);
      if (state.isRunning) _startCountdown();
    }
  }

  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 500);
      }
    } catch (_) {
      // Vibration not available on all platforms — ignore errors
    }
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResumed;
  final VoidCallback onPaused;

  _LifecycleObserver({required this.onResumed, required this.onPaused});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    } else if (state == AppLifecycleState.paused) {
      onPaused();
    }
  }
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(
  RestTimerNotifier.new,
);
