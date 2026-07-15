import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../data/auth_repository.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authRepo = AuthRepository();
  bool _loading = false;

  Future<void> _verify(String code) async {
    setState(() => _loading = true);
    try {
      await _authRepo.confirmOtp(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      if (mounted) context.go('/chats');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid code: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Enter the 6-digit code we sent you via SMS'),
            const SizedBox(height: 24),
            Pinput(
              length: 6,
              onCompleted: _loading ? null : _verify,
            ),
            if (_loading) const Padding(
              padding: EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
