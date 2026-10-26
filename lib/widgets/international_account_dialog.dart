import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// No OTP or external email provider. The account is only a login credential;
/// masjid/transfer authorization still requires Platform Admin approval.
Future<bool> openInternationalAccount(BuildContext context, {
  required FirebaseAuth auth, required String email, bool create = true,
}) async => await showDialog<bool>(context: context, barrierDismissible: false,
  builder: (_) => _AccountDialog(auth: auth, email: email.trim().toLowerCase(), create: create)) ?? false;
class _AccountDialog extends StatefulWidget {
  final FirebaseAuth auth;
  final String email;
  final bool create;
  const _AccountDialog({required this.auth, required this.email, required this.create});
  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}
class _AccountDialogState extends State<_AccountDialog> {
  final password = TextEditingController(), confirm = TextEditingController();
  late bool create = widget.create;
  bool busy = false, hide = true;
  String? error;
  Future<void> submit() async {
    if (password.text.length < 6 || (create && password.text != confirm.text)) {
      setState(() => error = create ? 'Use at least 6 characters and match both passwords.' : 'Enter your password.');return;
    }
    setState(() { busy = true; error = null; });
    try {
      if (create) {
        await widget.auth.createUserWithEmailAndPassword(email: widget.email, password: password.text);
      } else {
        await widget.auth.signInWithEmailAndPassword(email: widget.email, password: password.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.code == 'email-already-in-use'
          ? 'This email already has an account. Choose Sign in below.'
          : e.code == 'weak-password' ? 'Choose a stronger password.'
          : 'Could not continue. Check your email/password and try again.');
    } catch (_) { if (mounted) setState(() => error = 'Check your connection and try again.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> resetPassword() async {
    setState(() { busy = true; error = null; });
    try {
      await widget.auth.sendPasswordResetEmail(email: widget.email);
      if (mounted) setState(() => error = 'If this account supports password reset, check your email for the reset link.');
    } catch (_) { if (mounted) setState(() => error = 'Could not request a reset. Please try later.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { password.dispose(); confirm.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !busy, child: AlertDialog(
    title: Text(create ? 'Create admin login' : 'Admin sign in'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(widget.email), const SizedBox(height: 8),
      const Text('No OTP is required. Masjid registration and international transfers need Platform Admin approval.'),
      TextField(controller: password, enabled: !busy, obscureText: hide,
        decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(
          onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility : Icons.visibility_off)))),
      if (create) TextField(controller: confirm, enabled: !busy, obscureText: true,
        decoration: const InputDecoration(labelText: 'Confirm password')),
      if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(error!)),
      TextButton(onPressed: busy ? null : () => setState(() { create = !create; error = null; password.clear(); confirm.clear(); }),
        child: Text(create ? 'Already have an account? Sign in' : 'New admin? Create account')),
      if (!create) TextButton(onPressed: busy ? null : resetPassword, child: const Text('Forgot password?')),
    ])),
    actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
      FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Please wait...' : 'Continue'))],
  ));
}
