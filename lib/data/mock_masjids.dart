import '../models/masjid.dart';

/// Phase 1-3 uses an in-memory list so the app is fully testable before
/// Firebase is wired up. Replace this with a Firestore query later:
/// FirebaseFirestore.instance.collection('masjids').snapshots()
///
/// NOTE: This list resets every time the app restarts, since there is no
/// backend yet. Anything an admin adds/edits here will NOT be visible to
/// other users until Firebase (Phase 2) is connected.
final List<Masjid> mockMasjids = [
  Masjid(
    id: 'm1',
    name: 'Masjid Noor',
    city: 'Mumbai',
    address: 'Mohammed Ali Road, Mumbai, Maharashtra',
    latitude: 18.9548,
    longitude: 72.8258,
    verificationStatus: 'Verified',
    adminName: 'Imam Yusuf',
    adminMobile: '9876543210',
    adminEmail: 'imam.noor@example.com',
    prayerTimes: PrayerTimes(
      fajr: '5:15 AM',
      dhuhr: '1:15 PM',
      asr: '4:45 PM',
      maghrib: '7:02 PM',
      isha: '8:30 PM',
      juma: '1:30 PM',
    ),
  ),
  Masjid(
    id: 'm2',
    name: 'Jama Masjid',
    city: 'Mumbai',
    address: 'Fort, Mumbai, Maharashtra',
    latitude: 18.9367,
    longitude: 72.8352,
    verificationStatus: 'Verified',
    adminName: 'Trustee Ahmed',
    adminMobile: '9876500000',
    adminEmail: 'ahmed@example.com',
    prayerTimes: PrayerTimes(
      fajr: '5:12 AM',
      dhuhr: '1:10 PM',
      asr: '4:40 PM',
      maghrib: '7:00 PM',
      isha: '8:25 PM',
      juma: '1:15 PM',
    ),
  ),
  Masjid(
    id: 'm3',
    name: 'Masjid Al-Falah',
    city: 'Pune',
    address: 'Camp Area, Pune, Maharashtra',
    latitude: 18.5204,
    longitude: 73.8567,
    verificationStatus: 'Pending',
    adminName: 'Imam Bilal',
    adminMobile: '9812345678',
    adminEmail: 'bilal@example.com',
    prayerTimes: PrayerTimes(
      fajr: '5:18 AM',
      dhuhr: '1:20 PM',
      asr: '4:50 PM',
      maghrib: '7:05 PM',
      isha: '8:35 PM',
      juma: '1:30 PM',
    ),
  ),
];
