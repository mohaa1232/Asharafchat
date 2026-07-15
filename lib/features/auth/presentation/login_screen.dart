import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authRepo = AuthRepository();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePhone = true;
  bool _loading = false;

  Future<void> _sendOtp() async {
    setState(() => _loading = true);
    await _authRepo.sendOtp(
      phoneNumber: _phoneController.text.trim(),
      onCodeSent: (verificationId) {
        setState(() => _loading = false);
        if (mounted) context.push('/otp', extra: verificationId);
      },
      onFailed: (e) {
        setState(() => _loading = false);
        _showError(e.message ?? 'Phone verification failed');
      },
    );
  }

  Future<void> _signInWithEmail() async {
    setState(() => _loading = true);
    try {
      await _authRepo.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/chats');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _authRepo.signInWithGoogle();
      if (mounted) context.go('/chats');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeepBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 72),
              const SizedBox(height: 12),
              const Text('AsharafChat',
                  style: TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Simple. Secure. Reliable.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ToggleButtons(
                      isSelected: [_usePhone, !_usePhone],
                      onPressed: (i) => setState(() => _usePhone = i == 0),
                      borderRadius: BorderRadius.circular(12),
                      children: const [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Phone')),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Email')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_usePhone) ...[
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: '+254 7XX XXX XXX',
                            prefixIcon: Icon(Icons.phone)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _sendOtp,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Send OTP'),
                      ),
                    ] else ...[
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email', prefixIcon: Icon(Icons.email)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _signInWithEmail,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Sign In'),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Create an account'),
                      ),
                    ],
                    const Divider(height: 24),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Continue with Google'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
