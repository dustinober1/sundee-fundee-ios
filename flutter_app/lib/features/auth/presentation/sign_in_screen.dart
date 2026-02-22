import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isWorking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
        child: SingleChildScrollView(
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
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_isWorking,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_isWorking) {
                        _performAction(() => authRepository.signInWithEmailPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            ));
                      }
                    },
                    enabled: !_isWorking,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isWorking
                        ? null
                        : () => _performAction(() => authRepository.signInWithEmailPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            )),
                    child: const Text('Sign in with Email'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isWorking
                        ? null
                        : () => _performAction(() => authRepository.createUserWithEmailPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            )),
                    child: const Text('Create Account'),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _isWorking
                        ? null
                        : () => _performAction(authRepository.continueAsGuest),
                    child: const Text('Continue as Guest'),
                  ),
                  if (_errorMessage != null) ...<Widget>[
                    const SizedBox(height: 16),
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
      ),
    );
  }
}
