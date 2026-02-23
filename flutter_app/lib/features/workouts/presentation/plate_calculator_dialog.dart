import 'package:flutter/material.dart';

class PlateCalculatorDialog extends StatefulWidget {
  const PlateCalculatorDialog({super.key});

  @override
  State<PlateCalculatorDialog> createState() => _PlateCalculatorDialogState();
}

class _PlateCalculatorDialogState extends State<PlateCalculatorDialog> {
  final TextEditingController _weightController = TextEditingController();
  Map<double, int> _plates = {};
  final double _barWeight = 45.0;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight < _barWeight) {
      setState(() {
        _plates = {};
      });
      return;
    }

    double remaining = (weight - _barWeight) / 2;
    final Map<double, int> result = {};

    // Available plates
    final plateSizes = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];

    for (final p in plateSizes) {
      if (remaining >= p) {
        int count = (remaining / p).floor();
        result[p] = count;
        remaining -= count * p;
        // Float precision fix
        remaining = double.parse(remaining.toStringAsFixed(2));
      }
    }

    setState(() {
      _plates = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Plate Calculator'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target Weight (lbs)',
              hintText: 'e.g. 225',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          if (_plates.isEmpty)
            const Text('Enter a weight greater than 45lbs.')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Per Side:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _plates.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.value}x ${entry.key}'),
                      backgroundColor: Colors.blueGrey[100],
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }
}
