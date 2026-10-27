import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masjid_alarm_app/services/app_language.dart';
import 'package:masjid_alarm_app/services/ask_roman_text.dart';
import 'package:masjid_alarm_app/models/masjid.dart';
import 'package:masjid_alarm_app/models/prophet_story.dart';
import 'package:masjid_alarm_app/screens/ask_islam_connect_screen.dart';
import 'package:masjid_alarm_app/theme/app_theme.dart';
import 'package:masjid_alarm_app/theme/app_theme_controller.dart';
import 'package:masjid_alarm_app/widgets/timing_review_status.dart';
import 'package:masjid_alarm_app/widgets/prophet_places_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (_) async => 1);
    await AppLanguageController.instance.setLanguage(AppLanguage.english);
    await AppThemeController.instance.setTheme('green_light');
  });
  test('Hindi voice is Roman by default; English and explicit scripts survive',
      () {
    expect(askVoiceTranscript('फज्र में कितनी रकात है', 'auto'),
        'fajr mein kitni rakat hai');
    expect(askVoiceTranscript('How many rakats are in Fajr?', 'auto'),
        'How many rakats are in Fajr?');
    expect(askVoiceTranscript('फज्र में कितनी रकात है', 'hi'),
        'फज्र में कितनी रकात है');
    expect(askReplyLanguage('फज्र में कितनी रकात है', 'auto'), 'roman');
    expect(askReplyLanguage('How many rakats are in Fajr?', 'auto'), 'auto');
    expect(askReplyLanguage('How many rakats are in Fajr?', 'ur'), 'ur');
  });
  test('Every palette has honest brightness and readable secondary text',
      () async {
    for (final id in [
      'green_light',
      'green_dark',
      'black_gold',
      'blue',
      'amber',
      'purple'
    ]) {
      await AppThemeController.instance.setTheme(id);
      final theme = AppTheme.light();
      expect(
          theme.brightness,
          ['green_dark', 'black_gold'].contains(id)
              ? Brightness.dark
              : Brightness.light);
      for (final background in [AppColors.ivory, AppColors.white]) {
        final a = AppColors.textMid.computeLuminance(),
            b = background.computeLuminance();
        expect(((a > b ? a : b) + .05) / ((a > b ? b : a) + .05),
            greaterThanOrEqualTo(4.5),
            reason: id);
      }
      expect(theme.textTheme.bodyMedium!.fontSize, 13);
    }
  });
  test(
      'All referenced story scenes decode and every chapter has an English title',
      () async {
    final data = jsonDecode(
            await rootBundle.loadString('assets/prophet_stories/stories.json'))
        as Map;
    final scenes = <String>{};
    for (final b in data['books'] as List) {
      for (final p in b['pages'] as List) {
        expect((p['titleEnglish'] as String).trim(), isNotEmpty);
        scenes.add(p['scene'] as String);
      }
    }
    for (final scene in scenes) {
      final data =
          await rootBundle.load('assets/prophet_stories/scenes/$scene.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
          targetWidth: 64);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0));
      frame.image.dispose();
      codec.dispose();
    }
  });
  testWidgets('English AI chrome is compact and legible in both themes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final id in ['green_light', 'black_gold']) {
      await AppThemeController.instance.setTheme(id);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light(),
          home:
              RepaintBoundary(key: key, child: const AskIslamConnectScreen())));
      await tester.pumpAndSettle();
      expect(find.text('A little clarity, every day.'), findsOneWidget);
      expect(find.text('Apna sawal poochhein'), findsNothing);
      expect(find.text('Ask a question…'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final out = Platform.environment['POLISH_PREVIEW_DIR'];
      if (out != null) {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(out).create(recursive: true);
        await File('$out/ai_$id.png').writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'Unknown confirmation date stays honest without an ugly placeholder',
      (tester) async {
    final m = Masjid(
        id: 'm',
        name: 'Test',
        city: 'City',
        address: 'Street',
        latitude: 0,
        longitude: 0,
        verificationStatus: 'Verified',
        prayerTimes: PrayerTimes(
            fajr: '05:00',
            dhuhr: '12:00',
            asr: '16:00',
            maghrib: '18:00',
            isha: '20:00',
            juma: '13:00'));
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: TimingReviewStatus(masjid: m))));
    expect(find.textContaining('Date available'), findsNothing);
    expect(find.textContaining('Confirmed:'), findsNothing);
    expect(
        find.text('Confirm the current timings to start a new review cycle.'),
        findsOneWidget);
    m.timesConfirmedAt = DateTime(2026, 10, 27);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: TimingReviewStatus(masjid: m))));
    expect(find.text('Confirmed: 27 Oct 2026'), findsOneWidget);
  });
  testWidgets('Geographic map opens its cited stories without layout overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final j = jsonDecode(
            await rootBundle.loadString('assets/prophet_stories/stories.json'))
        as Map;
    final stories = (j['books'] as List)
        .map((b) => ProphetStory.fromJson(Map<String, dynamic>.from(b as Map)))
        .toList();
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
            body: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: RepaintBoundary(
                        key: key,
                        child: ProphetPlacesMap(
                            stories: stories, onOpen: (_) {})))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final out = Platform.environment['POLISH_PREVIEW_DIR'];
    if (out != null) {
      final image = await (key.currentContext!.findRenderObject()!
              as RenderRepaintBoundary)
          .toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/story_map.png').writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    }
    await tester.tap(find.text('Misr'));
    await tester.pumpAndSettle();
    expect(find.text('Musa Alaihis Salam'), findsOneWidget);
    expect(find.textContaining('Quran 12:21'), findsOneWidget);
  });
}
