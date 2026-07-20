class PrayerTimes {
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String juma;

  const PrayerTimes({
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
  final String name;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final String verificationStatus; // "Pending", "Verified"
  final PrayerTimes prayerTimes;

  const Masjid({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.verificationStatus,
    required this.prayerTimes,
  });
}
