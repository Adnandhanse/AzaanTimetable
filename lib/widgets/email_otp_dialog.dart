import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/app_language.dart';
import '../services/email_admin_verification.dart';

Future<bool> verifyAdminEmail(BuildContext context, {
  required FirebaseAuth auth, required String email, required String countryIso,
  required String purpose, String? mobile, String? masjidId, String? callerIdToken,
}) async {
  final service = EmailAdminVerification(auth);
  final details = <String, dynamic>{'email': email.trim(), 'countryIso': countryIso,
    'purpose': purpose, 'language': AppLanguageController.instance.isUrdu ? 'ur' : 'en',
    if (mobile != null) 'mobile': mobile,
    if (masjidId != null) 'masjidId': masjidId,
    if (callerIdToken != null) 'callerIdToken': callerIdToken};
  final sent = await service.send(details); // Never show "sent" on a send failure.
  if (!context.mounted) return false;
  return await showDialog<bool>(context: context, barrierDismissible: false,
    builder: (_) => _EmailOtpDialog(service: service, details: details, sent: sent)) ?? false;
}
class _EmailOtpDialog extends StatefulWidget {
  final EmailAdminVerification service;
  final Map<String, dynamic> details, sent;
  const _EmailOtpDialog({required this.service, required this.details, required this.sent});
  @override
  State<_EmailOtpDialog> createState() => _EmailOtpDialogState();
}
class _EmailOtpDialogState extends State<_EmailOtpDialog> {
  final code = TextEditingController();
  late Map<String, dynamic> sent = widget.sent;
  Timer? timer;
  int seconds = 60;
  bool busy = false;
  String? error;
  String text(String en, String ur) => AppLanguageController.instance.isUrdu ? ur : en;
  @override
  void initState() { super.initState(); timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (mounted && seconds > 0) setState(() => seconds--);
  }); }
  @override
  void dispose() { timer?.cancel(); code.dispose(); super.dispose(); }
  Future<void> verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(code.text.trim())) {
      setState(() => error = text('Enter the 6-digit code.', '6 ہندسوں کا کوڈ درج کریں۔')); return;
    }
    setState(() { busy = true; error = null; });
    try {
      await widget.service.verify(sent['challengeId'] as String, code.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) { if (mounted) setState(() => error = EmailAdminVerification.friendly(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> resend() async {
    setState(() { busy = true; error = null; });
    try {
      final next = await widget.service.send(widget.details);
      if (mounted) setState(() { sent = next; seconds = 60; code.clear(); });
    } catch (e) { if (mounted) setState(() => error = EmailAdminVerification.friendly(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !busy, child: AlertDialog(
    title: Text(text('Check your email', 'اپنی ای میل چیک کریں')),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(text('A 6-digit verification code has been sent to ${sent['maskedEmail']}. Enter it below. It expires in 5 minutes. If you cannot find it, check your spam folder.',
        '${sent['maskedEmail']} پر 6 ہندسوں کا تصدیقی کوڈ بھیج دیا گیا ہے۔ اسے نیچے درج کریں۔ یہ 5 منٹ تک کارآمد ہے۔ ای میل نہ ملے تو اسپیم فولڈر چیک کریں۔')),
      const SizedBox(height: 16),
      TextField(controller: code, enabled: !busy, keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr, maxLength: 6,
        decoration: InputDecoration(labelText: text('Verification code', 'تصدیقی کوڈ'), errorText: error)),
      TextButton(onPressed: busy || seconds > 0 ? null : resend,
        child: Text(seconds > 0 ? text('Resend code in ${seconds}s', '$seconds سیکنڈ بعد دوبارہ کوڈ بھیجیں') : text('Resend code', 'دوبارہ کوڈ بھیجیں'))),
    ])),
    actions: [TextButton(onPressed: busy ? null : () => Navigator.of(context).pop(false),
      child: Text(text('Change email / Cancel', 'ای میل تبدیل کریں / منسوخ'))),
      FilledButton(onPressed: busy ? null : verify,
        child: Text(busy ? text('Please wait...', 'انتظار کریں۔۔۔') : text('Verify email', 'ای میل کی تصدیق کریں')))],
  ));
}
