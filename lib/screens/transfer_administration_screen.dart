import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/masjid.dart';
import '../services/auth_service.dart';
import '../services/direct_ownership_transfer.dart';
import '../services/masjid_repository.dart';
import 'otp_screen.dart';
import 'home_screen.dart';

class TransferAdministrationScreen extends StatefulWidget {
  final Masjid masjid;
  const TransferAdministrationScreen({super.key, required this.masjid});
  @override
  State<TransferAdministrationScreen> createState() => _TransferAdministrationScreenState();
}

class _TransferAdministrationScreenState extends State<TransferAdministrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _recipient = DirectOwnershipTransfer();
  final _operationId = 'transfer-${DateTime.now().microsecondsSinceEpoch}';
  bool _ready = false, _busy = false, _verified = false, _complete = false;
  String? _verificationId, _recipientMobile;
  int? _resendToken;
  int _otpAttempt = 0;
  String? _initializationError;

  @override
  void initState() { super.initState(); _initialize(); _loadOwnership(); }

  Future<void> _initialize() async {
    try {
      await _recipient.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _initializationError = 'Unable to prepare transfer. Reopen this page to try again.');
    }
  }

  String? _transferError;

  String _friendlyError(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'not-found':
          return 'The transfer service could not be found. Please contact the platform admin to complete the setup.';
        case 'unauthenticated':
          final details = error.details;
          final reason = details is Map ? details['reason'] : null;
          if (reason == 'caller-session-invalid') {
            return 'Your current-admin session needs verification. Sign in again as the current admin.';
          }
          if (reason == 'recipient-session-invalid') {
            return 'Verify the new admin phone again, then retry the transfer.';
          }
          return 'The transfer session could not be checked. Try Verify phone again. If it continues, the platform admin should check the server logs.';
        case 'permission-denied':
          return 'You do not have permission to transfer this masjid. Please contact the platform admin.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'We could not confirm the transfer. Check your connection and retry on this page.';
        case 'failed-precondition':
          return error.message ?? 'The admin details have changed or verification has expired. Please reopen this page and verify again.';
        default:
          return 'The transfer could not be completed. Please try again or contact the platform admin.';
      }
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-verification-code': return 'The OTP is incorrect. Please check and try again.';
        case 'session-expired': return 'The OTP has expired. Please request a new code.';
        case 'too-many-requests': return 'Too many OTP attempts. Please wait before trying again.';
        case 'network-request-failed': return 'Check your internet connection and try again.';
        default: return 'Phone verification could not be completed. Please try again.';
      }
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Unable to read the masjid details. Please contact the platform admin.';
    }
    if (error is StateError) return '${error.message}';
    return 'Something went wrong. Please try again.';
  }

  void _error(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_friendlyError(error)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
    ));
  }

  Future<void> _sendOtp() async {
    if (!_form.currentState!.validate()) return;
    final currentMobile = widget.masjid.adminMobile.trim();
    if (AuthService.currentUser?.phoneNumber != '+91$currentMobile') {
      setState(() => _busy = true);
      await AuthService.sendOtp(phoneNumber: '+91$currentMobile',
        onCodeSent: (id, token) {
          if (!mounted) return;
          setState(() => _busy = false);
          Navigator.of(context).push(MaterialPageRoute(builder: (otpContext) => OtpScreen(
            phoneNumber: currentMobile, verificationId: id, resendToken: token,
            onVerified: () async {
              if (!mounted) return;
              Navigator.of(otpContext).pop();
              await _sendRecipientOtp();
            })));
        }, onError: (error) { if (mounted) setState(() => _busy = false); _error(error); });
      return;
    }
    await _sendRecipientOtp();
  }

  Future<void> _sendRecipientOtp() async {
    final mobile = _mobile.text.trim();
    final token = _recipientMobile == mobile ? _resendToken : null;
    final attempt = ++_otpAttempt;
    setState(() {
      _busy = true; _verified = false; _recipientMobile = mobile;
      _verificationId = null; _transferError = null;
      _otp.clear();
    });
    try {
      await _recipient.auth.signOut();
      await _recipient.auth.verifyPhoneNumber(phoneNumber: '+91$mobile', forceResendingToken: token,
        verificationCompleted: (credential) async {
          if (!mounted || _complete || attempt != _otpAttempt) return;
          try {
            await _recipient.auth.signInWithCredential(credential);
            if (_recipient.auth.currentUser?.phoneNumber != '+91$mobile') {
              throw StateError('The verified number does not match the new admin phone.');
            }
            if (mounted && attempt == _otpAttempt) setState(() { _verified = true; _busy = false; _transferError = null; });
          } catch (error) { if (mounted) setState(() => _busy = false); _error(error); }
        },
        verificationFailed: (error) { if (!mounted || attempt != _otpAttempt) return; setState(() => _busy = false); _error(error); },
        codeSent: (id, token) {
          if (mounted && attempt == _otpAttempt) setState(() { _verificationId = id; _resendToken = token; _busy = false; });
        }, codeAutoRetrievalTimeout: (_) {});
    } catch (error) { if (mounted) setState(() => _busy = false); _error(error); }
  }

  Future<void> _verifyRecipient() async {
    if (_verificationId == null || !RegExp(r'^\d{6}$').hasMatch(_otp.text.trim())) {
      _error(StateError('Enter the 6-digit OTP received on the new admin phone.'));
      return;
    }
    setState(() => _busy = true);
    try {
      await _recipient.auth.signInWithCredential(PhoneAuthProvider.credential(
        verificationId: _verificationId!, smsCode: _otp.text.trim()));
      if (_recipient.auth.currentUser?.phoneNumber != '+91$_recipientMobile') {
        throw StateError('The verified number does not match B’s phone.');
      }
      if (mounted) setState(() { _verified = true; _transferError = null; });
    } catch (error) { _error(error); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _transfer() async {
    if (!_form.currentState!.validate() || !_verified) return;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirm transfer'),
      content: Text('Transfer ${widget.masjid.name} to ${_name.text.trim()} ($_recipientMobile)? Your admin access to this masjid will end. Followers, timings and all masjid data will remain unchanged.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm transfer'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() { _busy = true; _transferError = null; });
    try {
      // Capture ownership when opening this screen, not after a competing transfer.
      await _recipient.submit(masjidId: widget.masjid.id, name: _name.text,
        mobile: _recipientMobile!, email: _email.text, operationId: _operationId,
        expectedAdminMobile: widget.masjid.adminMobile, expectedAdminUid: _expectedAdminUid);
      _complete = true;
      try { final prefs = await SharedPreferences.getInstance(); await prefs.remove('admin_mobile'); } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(
        'Administration transferred. All masjid data and followers are preserved.')));
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
    } catch (error) {
      if (mounted) setState(() {
        _transferError = _friendlyError(error);
        if (error is FirebaseFunctionsException && error.details is Map &&
            (error.details as Map)['reason'] == 'recipient-session-invalid') {
          _verified = false;
          _verificationId = null;
          _otp.clear();
        }
      });
    } finally { if (mounted) setState(() => _busy = false); }
  }

  String? _expectedAdminUid;
  bool _ownershipLoaded = false;

  Future<void> _loadOwnership() async {
    // A raw ownership snapshot is loaded by a repository helper.
    try {
      final uid = await MasjidRepository.getAdminUid(widget.masjid.id);
      if (mounted) setState(() { _expectedAdminUid = uid; _ownershipLoaded = true; });
    } catch (error) { _error(error); }
  }

  @override
  void dispose() {
    unawaited(_recipient.dispose());
    _name.dispose(); _mobile.dispose(); _email.dispose(); _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(appBar: AppBar(title: const Text('Transfer administration')),
      body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
        Text(widget.masjid.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text('Complete this on the current admin’s phone with the new admin present. With their consent, enter the OTP received on their phone. No new masjid registration is needed.'),
        const SizedBox(height: 20),
        if (_initializationError != null) Text(_initializationError!),
        if (_transferError != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(child: Text(_transferError!, style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer))),
            ]),
          ),
        ],
        TextFormField(controller: _name, enabled: !_busy,
          decoration: const InputDecoration(labelText: 'New admin name'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null),
        TextFormField(controller: _mobile, enabled: !_busy && _recipientMobile == null,
          keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'New admin mobile (+91)'),
          validator: (v) => !RegExp(r'^[6-9]\d{9}$').hasMatch((v ?? '').trim())
              ? 'Enter a valid 10-digit mobile' : v!.trim() == widget.masjid.adminMobile.trim()
              ? 'Enter a different mobile number' : null),
        TextFormField(controller: _email, enabled: !_busy,
          keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'New admin email (optional)')),
        const SizedBox(height: 16),
        if (!_verified) ElevatedButton(onPressed: !_ready || _busy ? null : _sendOtp,
          child: Text(_verificationId == null ? 'Send OTP to new admin' : 'Resend OTP')),
        if (_verificationId != null && !_verified) ...[
          TextFormField(controller: _otp, enabled: !_busy, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'OTP received on new admin’s phone')),
          ElevatedButton(onPressed: _busy ? null : _verifyRecipient, child: const Text('Verify new admin')),
        ],
        if (_verified) ...[
          Text('New admin phone verified: $_recipientMobile'),
          TextButton.icon(
            onPressed: _busy ? null : _sendOtp,
            icon: const Icon(Icons.refresh),
            label: const Text('Verify phone again'),
          ),
          ElevatedButton(onPressed: _busy || !_ownershipLoaded ? null : _transfer, child: const Text('Transfer administration')),
        ],
        if (_busy) const Center(child: CircularProgressIndicator()),
      ])),
    ),
  );
}
