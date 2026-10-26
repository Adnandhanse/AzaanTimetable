import 'package:firebase_auth/firebase_auth.dart';
import '../models/masjid.dart';

class AdminCountry {
  final String iso, dialCode, name;
  const AdminCountry(this.iso, this.dialCode, this.name);
  static const india = AdminCountry('IN', '+91', 'India');
  bool get isIndia => iso == 'IN';
  String number(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s().-]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    final national = (iso == 'IT' || iso == 'VA')
        ? cleaned : cleaned.replaceFirst(RegExp(r'^0+'), '');
    return '$dialCode$national';
  }
  String? validate(String? raw) {
    final n = number(raw ?? '');
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(n) || !n.startsWith(dialCode)) {
      return 'Enter a valid number for $name';
    }
    if (isIndia && !RegExp(r'^\+91[6-9]\d{9}$').hasMatch(n)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }
}

class AdminContact {
  static String canonical(String n) => n.startsWith('+') ? n : '+91${n.trim()}';
  static bool matchesAccount(Masjid m, User? user) {
    if (user == null || (m.adminUid != null && m.adminUid != user.uid)) return false;
    if (m.adminVerificationMethod == 'email_password') {
      return m.adminUid == user.uid && user.email?.toLowerCase() == m.adminEmail.toLowerCase();
    }
    if (m.adminVerificationMethod == 'email') {
      return m.adminUid == user.uid && user.emailVerified &&
          user.email?.toLowerCase() == m.adminEmail.toLowerCase();
    }
    return user.phoneNumber == canonical(m.adminMobile);
  }
  static bool owns(Masjid m, User? user) => matchesAccount(m, user) &&
      (m.adminVerificationMethod != 'email_password' || m.verificationStatus == 'Verified');
}
