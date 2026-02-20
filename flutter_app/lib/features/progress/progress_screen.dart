import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('progress-screen'),
      appBar: AppBar(title: const Text('Progress')),
      body: const Center(
        child: Text('Progress charts will appear here'),
      ),
    );
  }
}
