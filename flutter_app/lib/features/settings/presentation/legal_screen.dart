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
By accessing and using **Sundee Fundee**, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.

## 2. Eligibility
You must be at least 18 years of age to use this application. By using Sundee Fundee, you represent and warrant that you meet this age requirement.

## 3. User Accounts
You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.

## 4. Intellectual Property
All content, including but not limited to training programs, algorithms, UI design, logos, and text, is the property of Sundee Fundee and Dustin Ober. You may not reproduce, distribute, or create derivative works without explicit permission.

## 5. Prohibited Conduct
You agree not to use the app for any unlawful purpose or to interfere with the proper functioning of the service. This includes attempting to circumvent security measures or reverse-engineer the application logic.

## 6. Termination
We reserve the right to terminate or suspend your access to the service at any time, without prior notice, for conduct that we believe violates these Terms or is harmful to other users or the service itself.

## 7. Governing Law
These Terms are governed by the laws of the Commonwealth of Virginia, United States, without regard to its conflict of law principles.
""";

const String _privacy = """
## 1. Information We Collect
We collect information to provide a personalized training experience:
- **Identifiers:** Name and email address (via Google Sign-In or email registration).
- **Fitness Data:** 1RM (One Rep Max) data, workout logs, and strength progression.
- **Sensitive Data:** Menstrual cycle dates (start/end) and related symptoms to adjust training intensity.

## 2. How We Use Your Data
Your data is used strictly for:
- Generating personalized training programs based on your hormonal phases.
- Tracking your strength progress over time.
- Improving app functionality and user experience.

## 3. Data Storage and Security
We use **Firebase (Google Cloud)** for secure data storage and authentication. We implement industry-standard security measures to protect your personal and sensitive health information. However, no method of electronic storage is 100% secure.

## 4. Data Sharing
We **do not sell** your personal or health data to third parties. Data is only shared with service providers (like Firebase) to the extent necessary to operate the application.

## 5. Your Rights
You have the right to:
- Access the data we have stored about you.
- Request the deletion of your account and all associated data.
- Opt-out of any non-essential data collection.

## 6. Children's Privacy
Sundee Fundee is not intended for use by individuals under the age of 13 (or 16 in some jurisdictions). We do not knowingly collect data from children.
""";

const String _disclaimer = """
## 1. Not Medical Advice
**Sundee Fundee is for informational and fitness purposes only.** The training recommendations provided are based on general hormonal research and are not a substitute for professional medical advice, diagnosis, or treatment.

## 2. No Contraceptive Use
This application is **not** a contraceptive tool and should not be used to prevent pregnancy or for any diagnostic reproductive health purposes.

## 3. Physical Liability & Risk
**WARNING:** Weightlifting carries inherent risks of serious injury or death. 
- You voluntarily assume all risks associated with the physical activities suggested by this app.
- **Consult a physician** before starting any new exercise program, especially one involving heavy resistance training.
- Do not ignore professional medical advice or delay seeking it because of something you have read in this app.

## 4. Accuracy of Information
While we strive for accuracy, cycle-syncing science is an evolving field. We make no guarantees regarding the effectiveness or accuracy of the generated programs for your specific physiological needs.

## 5. Limitation of Liability
To the maximum extent permitted by law, Dustin Ober and Sundee Fundee shall not be liable for any direct, indirect, incidental, or consequential damages resulting from your use of the application or participation in the suggested training programs.
""";
