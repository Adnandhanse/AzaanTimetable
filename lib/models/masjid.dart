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

  Map<String, dynamic> toMap() => {
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
        'juma': juma,
      };

  factory PrayerTimes.fromMap(Map<String, dynamic> map) => PrayerTimes(
        fajr: map['fajr'] ?? '--:--',
        dhuhr: map['dhuhr'] ?? '--:--',
        asr: map['asr'] ?? '--:--',
        maghrib: map['maghrib'] ?? '--:--',
        isha: map['isha'] ?? '--:--',
        juma: map['juma'] ?? '--:--',
      );
}

class Masjid {
  final String id;
  String name;
  String city;
  String address;
  double latitude;
  double longitude;
  String verificationStatus; // "Pending Verification", "Verified", "Rejected"
  PrayerTimes prayerTimes;

  // Admin-only fields (set during registration)
  String registrationNo;
  String adminName;
  String adminMobile;
  String adminEmail;

  // Verification document (not currently used - registration number based instead)
  String? verificationDocName;

  // Custom Azan audio - stores the Firebase Storage download URL once uploaded,
  // so it plays for everyone following this masjid, not just the admin's phone.
  String? customAzanAudioName;
  String? customAzanAudioUrl;

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
    this.customAzanAudioUrl,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'city': city,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'verificationStatus': verificationStatus,
        'prayerTimes': prayerTimes.toMap(),
        'registrationNo': registrationNo,
        'adminName': adminName,
        'adminMobile': adminMobile,
        'adminEmail': adminEmail,
        'verificationDocName': verificationDocName,
        'customAzanAudioName': customAzanAudioName,
        'customAzanAudioUrl': customAzanAudioUrl,
      };

  factory Masjid.fromMap(String id, Map<String, dynamic> map) => Masjid(
        id: id,
        name: map['name'] ?? '',
        city: map['city'] ?? '',
        address: map['address'] ?? '',
        latitude: (map['latitude'] ?? 0.0).toDouble(),
        longitude: (map['longitude'] ?? 0.0).toDouble(),
        verificationStatus: map['verificationStatus'] ?? 'Pending Verification',
        prayerTimes: PrayerTimes.fromMap(map['prayerTimes'] ?? {}),
        registrationNo: map['registrationNo'] ?? '',
        adminName: map['adminName'] ?? '',
        adminMobile: map['adminMobile'] ?? '',
        adminEmail: map['adminEmail'] ?? '',
        verificationDocName: map['verificationDocName'],
        customAzanAudioName: map['customAzanAudioName'],
        customAzanAudioUrl: map['customAzanAudioUrl'],
      );
}
