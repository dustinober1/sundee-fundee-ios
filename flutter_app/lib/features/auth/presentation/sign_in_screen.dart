import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isWorking = false;
  String? _errorMessage;

  Future<void> _performAction(Future<void> Function() action) async {
    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });

    try {
      await action();
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = ref.read(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Welcome to Sundee Fundee',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isWorking
                      ? null
                      : () => _performAction(authRepository.signInWithApple),
                  child: const Text('Sign in with Apple'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isWorking
                      ? null
                      : () => _performAction(authRepository.signInWithGoogle),
                  child: const Text('Sign in with Google'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isWorking
                      ? null
                      : () => _performAction(authRepository.continueAsGuest),
                  child: const Text('Continue as Guest'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Email/password auth wiring is available in AuthRepository and can be attached to a form in the next UI iteration.',
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
