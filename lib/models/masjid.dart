import 'package:cloud_firestore/cloud_firestore.dart';
/// Azan times, and optionally the jamat times that follow them.
///
/// WHY JAMAT IS A SEPARATE, OPTIONAL SET
///
/// The azan is when the time enters; the jamat is when the congregation stands.
/// The gap between them is a decision each masjid makes, and it is the time
/// people actually plan around — "Isha jamat at 8:45" is what gets said, not
/// the azan time.
///
/// Optional because every masjid already registered has azan times and no jamat
/// times. A missing jamat must degrade to showing nothing rather than showing
/// "--:--" against every prayer, or every existing masjid would suddenly look
/// broken.
///
/// ALARMS STILL FIRE ON THE AZAN, not the jamat. Nothing in the notification
/// code reads these fields.
class PrayerTimes {
  String fajr;
  String dhuhr;
  String asr;
  String maghrib;
  String isha;
  String juma;

  /// Jamat times. Empty string means the masjid has not set one.
  String fajrJamat;
  String dhuhrJamat;
  String asrJamat;
  String maghribJamat;
  String ishaJamat;
  String jumaJamat;

  PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.juma,
    this.fajrJamat = '',
    this.dhuhrJamat = '',
    this.asrJamat = '',
    this.maghribJamat = '',
    this.ishaJamat = '',
    this.jumaJamat = '',
  });

  bool get hasAnyJamat => <String>[
        fajrJamat,
        dhuhrJamat,
        asrJamat,
        maghribJamat,
        ishaJamat,
        jumaJamat,
      ].any((t) => t.trim().isNotEmpty);

  Map<String, dynamic> toMap() => {
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
        'juma': juma,
        'fajrJamat': fajrJamat,
        'dhuhrJamat': dhuhrJamat,
        'asrJamat': asrJamat,
        'maghribJamat': maghribJamat,
        'ishaJamat': ishaJamat,
        'jumaJamat': jumaJamat,
      };

  factory PrayerTimes.fromMap(Map<String, dynamic> map) => PrayerTimes(
        fajr: map['fajr'] ?? '--:--',
        dhuhr: map['dhuhr'] ?? '--:--',
        asr: map['asr'] ?? '--:--',
        maghrib: map['maghrib'] ?? '--:--',
        isha: map['isha'] ?? '--:--',
        juma: map['juma'] ?? '--:--',
        // Default to EMPTY, not '--:--'. Absent means "not set", and the UI
        // shows nothing rather than a placeholder against every prayer of every
        // masjid registered before this existed.
        fajrJamat: map['fajrJamat'] ?? '',
        dhuhrJamat: map['dhuhrJamat'] ?? '',
        asrJamat: map['asrJamat'] ?? '',
        maghribJamat: map['maghribJamat'] ?? '',
        ishaJamat: map['ishaJamat'] ?? '',
        jumaJamat: map['jumaJamat'] ?? '',
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

  /// When the prayer times were last changed, from the SERVER clock.
  ///
  /// Null for every masjid registered before this existed, and for any that has
  /// never had its times edited — which is itself the useful signal.
  DateTime? timesUpdatedAt;

  /// How many devices currently follow this masjid.
  ///
  /// A COUNT, not a list. There is no record of WHO follows a masjid anywhere in
  /// this app — nothing to protect, nothing to declare, and nothing that could
  /// identify a worshipper from their prayer habits.
  ///
  /// Read-only from the app's point of view: maintained by
  /// FollowerService using atomic increments, never written by hand.
  int followerCount;

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
    this.followerCount = 0,
    this.timesUpdatedAt,
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
        // Absent on every masjid registered before this existed, so it defaults
        // rather than failing to parse.
        followerCount: (map['followerCount'] as num?)?.toInt() ?? 0,
        timesUpdatedAt: map['timesUpdatedAt'] is Timestamp
            ? (map['timesUpdatedAt'] as Timestamp).toDate()
            : null,
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
