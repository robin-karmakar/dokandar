import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isSending = false;
  bool _dismissed = false;

  Future<void> _resendLink() async {
    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification link sent to your email')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send link. Try again later.')),
        );
      }
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Only show for real email accounts (not phone-mapped @phone.app emails)
    final isRealEmailAccount = user?.email != null &&
        user!.email!.isNotEmpty &&
        !user.email!.endsWith('@phone.app');

    if (!isRealEmailAccount || user!.emailVerified || _dismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Please verify your email. Check your inbox.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _resendLink,
                  child: const Text('Resend', style: TextStyle(fontSize: 12.5)),
                ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}