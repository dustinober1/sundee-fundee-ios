import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isWorking = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
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
        _errorMessage = _mapAuthError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  String _mapAuthError(Object error) {
    final String message = error.toString().toLowerCase();

    if (message.contains('invalid-credential') ||
        message.contains('wrong-password') ||
        message.contains('user-not-found') ||
        message.contains('invalid-email')) {
      return 'Sign-in failed. Check your details and try again.';
    }

    if (message.contains('network') ||
        message.contains('timeout') ||
        message.contains('unavailable')) {
      return 'Could not reach the server. Please try again.';
    }

    return 'Sign-in failed. Check your details and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = ref.read(authRepositoryProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.surfaceLight,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // — Logo —
                      _buildLogo(size),
                      const SizedBox(height: 12),

                      // — App name —
                      Text(
                        'Sundee Fundee',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Strength Gained - On Your Cycle',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.brandSecondary,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 36),

                      // — Glass card —
                      _buildGlassCard(context, authRepository),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Size screenSize) {
    final double logoSize = screenSize.width < 400 ? 100 : 130;
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/main_logo.png',
          fit: BoxFit.cover,
          semanticLabel: 'Sundee Fundee logo',
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, dynamic authRepository) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.cardLight.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // — Social sign-in —
              _buildSocialButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                onPressed: _isWorking
                    ? null
                    : () => _performAction(authRepository.signInWithApple),
                filled: true,
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Continue with Google',
                onPressed: _isWorking
                    ? null
                    : () => _performAction(authRepository.signInWithGoogle),
                filled: false,
              ),

              const SizedBox(height: 24),

              // — Divider —
              Row(
                children: <Widget>[
                  Expanded(
                    child: Divider(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'or sign in with email',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Divider(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // — Email field —
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !_isWorking,
              ),
              const SizedBox(height: 14),

              // — Password field —
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_isWorking) {
                    _performAction(
                      () => authRepository.signInWithEmailPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                      ),
                    );
                  }
                },
                enabled: !_isWorking,
              ),
              const SizedBox(height: 20),

              // — Sign in button —
              _buildPrimaryButton(
                label: 'Sign In',
                onPressed: _isWorking
                    ? null
                    : () => _performAction(
                          () => authRepository.signInWithEmailPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          ),
                        ),
              ),
              const SizedBox(height: 10),

              // — Create account —
              OutlinedButton(
                onPressed: _isWorking
                    ? null
                    : () => _performAction(
                          () => authRepository.createUserWithEmailPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          ),
                        ),
                child: const Text('Create Account'),
              ),

              const SizedBox(height: 20),

              // — Guest —
              Center(
                child: TextButton(
                  onPressed: _isWorking
                      ? null
                      : () => _performAction(() async {
                            await authRepository.continueAsGuest();
                            ref.invalidate(authSessionStreamProvider);
                          }),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      decoration: TextDecoration.underline,
                      decorationColor:
                          AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // — Legal Footer —
              Wrap(
                alignment: WrapAlignment.center,
                children: <Widget>[
                  Text(
                    'By continuing, you agree to our ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                  _buildLegalLink(
                    label: 'Terms',
                    onPressed: () =>
                        context.push('/legal', extra: {'tabIndex': 0}),
                  ),
                  Text(
                    ' and ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                  _buildLegalLink(
                    label: 'Privacy Policy',
                    onPressed: () =>
                        context.push('/legal', extra: {'tabIndex': 1}),
                  ),
                ],
              ),

              // — Error —
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // — Loading indicator —
              if (_isWorking) ...<Widget>[
                const SizedBox(height: 20),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool filled,
  }) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildLegalLink({
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: <Color>[AppColors.brandPrimary, Color(0xFF2B4C6A)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
