import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LegalScreen extends StatelessWidget {
  final int initialTabIndex;

  const LegalScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Legal & Privacy'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Terms of Service'),
              Tab(text: 'Privacy Policy'),
              Tab(text: 'Legal Disclaimer'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PolicyViewer(data: _tos),
            PolicyViewer(data: _privacy),
            PolicyViewer(data: _disclaimer),
          ],
        ),
      ),
    );
  }
}

class PolicyViewer extends StatelessWidget {
  final String data;
  const PolicyViewer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Markdown(
      data: data,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
        ),
        h2: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// --- Policy Content ---

const String _tos = """
## 1. Acceptance of Terms
By accessing **sundee-fundee**, you agree to be bound by these Terms. 

## 2. Physical Liability Waiver
**WARNING:** Weightlifting carries inherent risks. By using this program, you assume all risks of injury. Consult a physician before starting any new squat program.

## 3. Intellectual Property
Programming content is the property of Dustin Ober.
""";

const String _privacy = """
## 1. Data Collection
We collect your name, email, and 1RM squat data to track progress.

## 2. Data Usage
Data is used strictly for internal programming adjustments. We do not sell your data.
""";

const String _disclaimer = """
## 1. Governing Law
These terms are governed by the laws of the Commonwealth of Virginia.

## 2. Limitation of Liability
Dustin Ober is not liable for any injuries or damages resulting from the use of this application.
""";
