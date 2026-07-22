class PrayerTimes {
  String fajr;
  String dhuhr;
  String asr;
  String maghrib;
  String isha;
  String juma;

  PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.juma,
  });
}

class Masjid {
  final String id;
  String name;
  String city;
  String address;
  double latitude;
  double longitude;
  String verificationStatus; // "Pending", "Verified"
  PrayerTimes prayerTimes;

  // Admin-only fields (set during registration)
  String registrationNo;
  String adminName;
  String adminMobile;
  String adminEmail;

  // Verification document (Phase 3: local path only; needs cloud storage to persist)
  String? verificationDocName;

  // Custom Azan audio (Phase 3: local path only; needs Firebase Storage
  // so it actually plays on followers' phones instead of just the admin's)
  String? customAzanAudioName;
  String? customAzanAudioPath;

  Masjid({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.verificationStatus,
    required this.prayerTimes,
    this.registrationNo = '',
    this.adminName = '',
    this.adminMobile = '',
    this.adminEmail = '',
    this.verificationDocName,
    this.customAzanAudioName,
    this.customAzanAudioPath,
  });
}
