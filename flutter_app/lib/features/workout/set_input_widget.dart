import 'package:flutter/material.dart';

/// Single set input row: weight field, reps field, log button.
class SetInputWidget extends StatefulWidget {
  final int setNumber;
  final int prescribedReps;
  final double? prescribedWeight;
  final bool isCompleted;
  final void Function(double weight, int reps) onLog;

  const SetInputWidget({
    super.key,
    required this.setNumber,
    required this.prescribedReps,
    this.prescribedWeight,
    required this.isCompleted,
    required this.onLog,
  });

  @override
  State<SetInputWidget> createState() => _SetInputWidgetState();
}

class _SetInputWidgetState extends State<SetInputWidget> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.prescribedWeight?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.prescribedReps.toString(),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _handleLog() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    if (weight > 0 && reps > 0) {
      widget.onLog(weight, reps);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('set-${widget.setNumber}-row'),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isCompleted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Set number badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: widget.isCompleted
                  ? Icon(Icons.check,
                      size: 18, color: theme.colorScheme.onPrimary)
                  : Text(
                      '${widget.setNumber}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Weight input
          Expanded(
            child: TextField(
              key: Key('set-${widget.setNumber}-weight-input'),
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'lbs',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              enabled: !widget.isCompleted,
            ),
          ),
          const SizedBox(width: 8),
          // Reps input
          SizedBox(
            width: 80,
            child: TextField(
              key: Key('set-${widget.setNumber}-reps-input'),
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              enabled: !widget.isCompleted,
            ),
          ),
          const SizedBox(width: 8),
          // Log button
          IconButton(
            key: Key('set-${widget.setNumber}-log-button'),
            onPressed: widget.isCompleted ? null : _handleLog,
            icon: Icon(
              widget.isCompleted
                  ? Icons.check_circle
                  : Icons.add_circle_outline,
              color: widget.isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
