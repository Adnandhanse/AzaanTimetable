import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_language.dart';
import '../services/app_strings.dart';

class HelpGuidesScreen extends StatefulWidget {
  const HelpGuidesScreen({super.key});
  @override
  State<HelpGuidesScreen> createState() => _HelpGuidesScreenState();
}

class _HelpGuidesScreenState extends State<HelpGuidesScreen> {
  late Future<List<_Guide>> _guides;

  @override
  void initState() {
    super.initState();
    _guides = _load();
  }

  Future<List<_Guide>> _load() async {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/guides/manifest.json'),
    ) as Map<String, dynamic>;
    return (raw['guides'] as List)
        .map((g) => _Guide.fromJson(Map<String, dynamic>.from(g as Map)))
        .toList();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppLanguageController.instance,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(S.tr('Help & Guides', 'مدد اور رہنمائی'))),
      body: FutureBuilder<List<_Guide>>(
        future: _guides,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      S.tr(
                        'Guides could not be opened. Please try again.',
                        'گائیڈ نہیں کھل سکی۔ دوبارہ کوشش کریں۔',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _guides = _load()),
                      child: Text(S.tr('Try Again', 'دوبارہ کوشش کریں')),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final guides = snapshot.data!
              .where((g) => g.language == (S.isUrdu ? 'ur' : 'en'))
              .toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                S.tr(
                  'Choose a Guide',
                  'گائیڈ منتخب کریں',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                S.tr(
                  'Read offline or watch the video.',
                  'آف لائن پڑھیں یا ویڈیو دیکھیں۔',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              for (final guide in guides)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: Icon(
                        guide.id == 'registration'
                            ? Icons.mosque_outlined
                            : Icons.swap_horiz_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        guide.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          guide.id == 'registration'
                              ? S.tr(
                                  'Registration steps',
                                  'رجسٹریشن کے مراحل',
                                )
                              : S.tr(
                                  'Transfer steps',
                                  'منتقلی کے مراحل',
                                ),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _GuideReader(guide: guide),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                S.tr(
                  '',
                  '',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Guide {
  const _Guide({
    required this.id,
    required this.language,
    required this.title,
    required this.pdf,
    required this.pages,
    required this.summaries,
    required this.videoUrl,
  });
  final String id, language, title, pdf, videoUrl;
  final List<String> pages, summaries;
  factory _Guide.fromJson(Map<String, dynamic> j) => _Guide(
    id: j['id'] as String,
    language: j['language'] as String,
    title: j['title'] as String,
    pdf: j['pdf'] as String,
    videoUrl: j['videoUrl'] as String,
    pages: List<String>.from(j['pages'] as List),
    summaries: List<String>.from(j['summaries'] as List),
  );
}

class _GuideReader extends StatefulWidget {
  const _GuideReader({required this.guide});
  final _Guide guide;
  @override
  State<_GuideReader> createState() => _GuideReaderState();
}

class _GuideReaderState extends State<_GuideReader> {
  final _controller = PageController();
  int _page = 0;
  bool _busy = false;
  bool get _urdu => widget.guide.language == 'ur';
  String _t(String en, String ur) => _urdu ? ur : en;

  Future<void> _export({required bool share}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final guide = widget.guide;
      final data = await rootBundle.load(guide.pdf);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final name = 'IslamConnect_${guide.id}_${guide.language}.pdf';
      if (share) {
        // Fixed names bound the temporary cache to four files. No phone
        // numbers, verification tokens or masjid account data are exported.
        final directory = Directory(
          '${(await getTemporaryDirectory()).path}/islam_connect_guides',
        );
        await directory.create(recursive: true);
        final file = File('${directory.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          subject: guide.title,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        );
      } else {
        final saved = await FilePicker.platform.saveFile(
          dialogTitle: _t('Save Guide', 'گائیڈ محفوظ کریں'),
          fileName: name,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: bytes,
        );
        // Cancelling the system picker is not a success or an error.
        if (saved != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_t('PDF saved.', 'پی ڈی ایف محفوظ ہو گئی۔')),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Could not save or share the guide. Please try again.',
                'گائیڈ محفوظ یا شیئر نہیں ہو سکی۔ دوبارہ کوشش کریں۔',
              ),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _watchVideo() async {
    final uri = Uri.tryParse(widget.guide.videoUrl);
    try {
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'www.youtube.com' ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Video could not be opened');
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Could not open the video. Check your internet connection and try again.',
                'ویڈیو نہیں کھل سکی۔ انٹرنیٹ دیکھیں اور دوبارہ کوشش کریں۔',
              ),
            ),
          ),
        );
    }
  }

  void _move(int delta) {
    final page = _page + delta;
    if (page < 0 || page >= widget.guide.pages.length) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: _urdu ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.guide.title),
        actions: [
          IconButton(
            tooltip: _t('Save PDF', 'پی ڈی ایف محفوظ کریں'),
            onPressed: _busy ? null : () => _export(share: false),
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: _t('Share PDF', 'پی ڈی ایف شیئر کریں'),
            onPressed: _busy ? null : () => _export(share: true),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.guide.pages.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(12),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Semantics(
                      label: widget.guide.summaries[index],
                      image: true,
                      child: ExcludeSemantics(
                        child: Image.asset(
                          widget.guide.pages[index],
                          fit: BoxFit.contain,
                          cacheWidth: 924,
                          errorBuilder: (_, __, ___) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(widget.guide.summaries[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                children: [
                  TextButton.icon(
                    onPressed: _watchVideo,
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(_t('Watch Video', 'ویڈیو دیکھیں')),
                  ),

                  Text(
                    _t(
                      'Swipe to turn pages. Pinch to zoom.',
                      'صفحہ بدلنے کے لیے سوائپ کریں۔ بڑا کرنے کے لیے دو انگلیاں استعمال کریں۔',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _page == 0 ? null : () => _move(-1),
                        child: Text(_t('Previous', 'پچھلا')),
                      ),
                      Text('${_page + 1} / ${widget.guide.pages.length}'),
                      TextButton(
                        onPressed: _page == widget.guide.pages.length - 1
                            ? null
                            : () => _move(1),
                        child: Text(_t('Next', 'اگلا')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
