import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_gate.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkVerified(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    await FirebaseAuth.instance.currentUser?.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (refreshedUser != null && refreshedUser.emailVerified) {
      _timer?.cancel();
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
      );
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not verified yet. Please check your inbox and click the link.')),
      );
    }
  }

  Future<void> _resendLink() async {
    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification link sent again. Check your inbox.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send link. Try again in a moment.')),
        );
      }
    }
    if (mounted) setState(() => _isResending = false);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_unread_outlined,
                  size: 70, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              const Text(
                'Verify your email address',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'We sent a verification link to:\n$email',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 30),
              _isChecking
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () => _checkVerified(),
                child: const Text("I've verified, continue"),
              ),
              const SizedBox(height: 15),
              _isResending
                  ? const CircularProgressIndicator()
                  : TextButton(
                onPressed: _resendLink,
                child: const Text('Resend verification link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}