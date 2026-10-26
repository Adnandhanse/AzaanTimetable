import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/masjid.dart';
import '../services/admin_contact.dart';
import '../services/direct_ownership_transfer.dart';
import '../services/email_admin_verification.dart';
import '../services/masjid_repository.dart';
import '../services/timing_reminder_service.dart';
import '../widgets/admin_country_picker.dart';
import '../widgets/international_account_dialog.dart';
import 'home_screen.dart';

class TransferAdministrationScreen extends StatefulWidget {
  final Masjid masjid;
  const TransferAdministrationScreen({super.key, required this.masjid});
  @override
  State<TransferAdministrationScreen> createState() => _TransferAdministrationScreenState();
}
class _TransferAdministrationScreenState extends State<TransferAdministrationScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), mobile = TextEditingController(), email = TextEditingController(), code = TextEditingController();
  final recipient = DirectOwnershipTransfer();
  final operationId = 'transfer-${DateTime.now().microsecondsSinceEpoch}';
  AdminCountry country = AdminCountry.india;
  bool busy = false, ready = false, verified = false;
  String? error, verificationId, expectedUid, verifiedKey;
  int attempt = 0;
  String get identityKey => '${country.iso}:${country.number(mobile.text)}:${email.text.trim().toLowerCase()}';
  @override
  void initState() { super.initState(); initialize(); }
  Future<void> initialize() async {
    try {
      await recipient.initialize();
      expectedUid = await MasjidRepository.getAdminUid(widget.masjid.id);
      if (mounted) setState(() => ready = true);
    } catch (_) { if (mounted) setState(() => error = 'Unable to prepare transfer. Reopen this page.'); }
  }
  void reset() { attempt++; verified = false; verifiedKey = null; verificationId = null; code.clear(); error = null; }
  String friendly(Object e) {
    if (e is FirebaseFunctionsException && e.code == 'failed-precondition') return e.message ?? 'Verification expired. Verify the new admin again.';
    if (e is FirebaseFunctionsException && e.code == 'permission-denied') return 'Only the current masjid admin can transfer administration.';
    if (e is FirebaseAuthException) return 'The code is incorrect or expired. Please request a new code.';
    if (e is StateError) return '${e.message}';
    return EmailAdminVerification.friendly(e);
  }
  Future<void> requestCode() async {
    if (!form.currentState!.validate()) return;
    if (!AdminContact.owns(widget.masjid, FirebaseAuth.instance.currentUser)) {
      setState(() => error = 'Sign in again as the current admin, then reopen this transfer.'); return;
    }
    setState(() { reset(); busy = true; });
    final generation = attempt, key = identityKey, number = country.number(mobile.text);
    try {
      await recipient.auth.signOut();
      if (!country.isIndia) {
        if (!mounted) return;
        final ok = await openInternationalAccount(context, auth: recipient.auth, email: email.text);
        if (mounted && generation == attempt && key == identityKey) setState(() { verified = ok; verifiedKey = ok ? key : null; });
      } else {
        await recipient.auth.verifyPhoneNumber(phoneNumber: number,
          verificationCompleted: (credential) async {
            if (!mounted || generation != attempt) return;
            try {
              await recipient.auth.signInWithCredential(credential);
              if (mounted && generation == attempt && key == identityKey && recipient.auth.currentUser?.phoneNumber == number) {
                setState(() { verified = true; verifiedKey = key; busy = false; });
              }
            } catch (e) { if (mounted) setState(() { busy = false; error = friendly(e); }); }
          },
          verificationFailed: (e) { if (mounted && generation == attempt) setState(() { busy = false; error = friendly(e); }); },
          codeSent: (id, _) { if (mounted && generation == attempt) setState(() { verificationId = id; busy = false; }); },
          codeAutoRetrievalTimeout: (_) {});
      }
    } catch (e) { if (mounted) setState(() { error = friendly(e); busy = false; }); }
    finally { if (mounted && !country.isIndia) setState(() => busy = false); }
  }
  Future<void> verifySms() async {
    if (verificationId == null || !RegExp(r'^\d{6}$').hasMatch(code.text.trim())) { setState(() => error = 'Enter the 6-digit SMS code.'); return; }
    setState(() { busy = true; error = null; });
    final key = identityKey;
    try {
      await recipient.auth.signInWithCredential(PhoneAuthProvider.credential(verificationId: verificationId!, smsCode: code.text.trim()));
      if (recipient.auth.currentUser?.phoneNumber != country.number(mobile.text)) throw StateError('The verified number does not match.');
      if (mounted && key == identityKey) setState(() { verified = true; verifiedKey = key; });
    } catch (e) { if (mounted) setState(() => error = friendly(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> transfer() async {
    if (!form.currentState!.validate() || !verified || verifiedKey != identityKey) return;
    final pending = !country.isIndia || widget.masjid.adminCountryIso != 'IN';
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(pending ? 'Request Transfer Approval' : 'Confirm Transfer'),
      content: Text(pending
        ? 'Send a transfer request for ${widget.masjid.name} to Platform Admin? Current ownership stays unchanged until approval.'
        : 'Transfer ${widget.masjid.name} to ${name.text.trim()}? Your admin access will end. All timings, followers and masjid data will be preserved.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Transfer'))]));
    if (yes != true || !mounted) return;
    setState(() { busy = true; error = null; });
    try {
      await recipient.submit(masjidId: widget.masjid.id, name: name.text,
        mobile: mobile.text.trim(), email: email.text, countryIso: country.iso,
        operationId: operationId, expectedAdminMobile: widget.masjid.adminMobile, expectedAdminUid: expectedUid, requireApproval: pending);
      if (pending) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(
          'Transfer request sent. Current admin keeps access until Platform Admin approves.')));
        Navigator.of(context).pop(); return;
      }
      await TimingReminderService.disable();
      final prefs = await SharedPreferences.getInstance(); await prefs.remove('admin_mobile');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administration transferred. All masjid data is preserved.')));
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) { if (mounted) setState(() => error = friendly(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { attempt++; unawaited(recipient.dispose()); name.dispose(); mobile.dispose(); email.dispose(); code.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !busy, child: Scaffold(
    appBar: AppBar(title: Text(!country.isIndia || widget.masjid.adminCountryIso != 'IN' ? 'Request Transfer Approval' : 'Transfer Administration')),
    body: Form(key: form, child: ListView(padding: const EdgeInsets.all(20), children: [
      Text(widget.masjid.name, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      const Text('Complete this on the current admin’s phone with the new admin present. Indian admins verify by SMS. International admins use an email/password account and Platform Admin approval. No new masjid registration is needed.'),
      const SizedBox(height: 20),
      AdminCountryPicker(value: country, enabled: !busy, onChanged: (v) => setState(() { country = v; mobile.clear(); reset(); })),
      TextFormField(controller: name, enabled: !busy, decoration: const InputDecoration(labelText: 'New Admin Name'),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null),
      TextFormField(controller: mobile, enabled: !busy, keyboardType: TextInputType.phone,
        onChanged: (_) => setState(reset), validator: country.validate,
        decoration: InputDecoration(labelText: 'New Admin Mobile', prefixText: '${country.dialCode} ')),
      TextFormField(controller: email, enabled: !busy, keyboardType: TextInputType.emailAddress,
        onChanged: (_) => setState(reset),
        decoration: InputDecoration(labelText: country.isIndia ? 'New Admin Email (Optional)' : 'New Admin Email'),
        validator: (v) => (!country.isIndia || (v ?? '').trim().isNotEmpty) && !RegExp(r'^\S+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim()) ? 'Enter a valid email address' : null),
      if (!country.isIndia) const Padding(padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No OTP required. Email and mobile are contact details; Platform Admin must approve the transfer.')),
      const SizedBox(height: 16),
      if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      if (!verified) FilledButton(onPressed: !ready || busy ? null : requestCode,
        child: Text(country.isIndia ? 'Send SMS Code' : 'Continue With New Admin Account')),
      if (verificationId != null && !verified) ...[
        TextFormField(controller: code, enabled: !busy, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '6-digit SMS code'), maxLength: 6),
        FilledButton(onPressed: busy ? null : verifySms, child: const Text('Verify Phone')),
      ],
      if (verified) ...[
        Text(country.isIndia ? 'New admin phone verified' : 'New admin account ready — approval required'),
        TextButton(onPressed: busy ? null : requestCode, child: const Text('Verify Again')),
        FilledButton(onPressed: busy ? null : transfer, child: Text(!country.isIndia || widget.masjid.adminCountryIso != 'IN' ? 'Request Transfer Approval' : 'Transfer Administration')),
      ],
      if (busy) const Center(child: CircularProgressIndicator()),
    ])),
  ));
}
