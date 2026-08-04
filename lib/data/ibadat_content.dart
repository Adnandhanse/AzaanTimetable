import '../models/hadith.dart';
import '../services/hadith_link.dart';

/// One step of an act of worship, with the hadith cited for it.
class IbadatStep {
  const IbadatStep({
    required this.title,
    required this.instruction,
    this.arabic,
    this.transliteration,
    this.refs = const <HadithRef>[],
    this.practiceDiffers,
  });

  final String title;
  final String instruction;

  /// What is said at this step, if anything.
  final String? arabic;
  final String? transliteration;

  final List<HadithRef> refs;

  /// Set when the schools of fiqh differ here.
  ///
  /// The app states the agreed sequence and marks the contested details rather
  /// than silently picking one school's position. Presenting one madhhab's
  /// detail as "the" method is the fastest way to mislead a user who follows
  /// another — and the sequence itself is agreed by all four, so the honest
  /// version is available.
  final String? practiceDiffers;
}

class IbadatSection {
  const IbadatSection({required this.title, required this.steps});

  final String title;
  final List<IbadatStep> steps;
}

class IbadatGuide {
  const IbadatGuide({
    required this.pillar,
    required this.sections,
    this.reviewed = false,
  });

  final String pillar;
  final List<IbadatSection> sections;

  /// FALSE until someone qualified has checked the text AND every citation.
  ///
  /// While false the screen says so, in the open, at the top. An unreviewed
  /// worship guide that looks authoritative is worse than one that admits what
  /// it is — people act on this.
  final bool reviewed;
}

/// CONTENT IS A DRAFT AND IS NOT REVIEWED.
///
/// Only steps whose citation is unambiguous are included. Every hadith here was
/// found by searching the app's own bundled text and reading it — not recalled,
/// not inferred. Even so, deciding that a hadith is the evidence for a ritual
/// step is a scholarly act, and none of this should ship as authoritative until
/// an aalim has signed it off.
///
/// Deliberately short. A long draft invites someone to publish it; a short one
/// demonstrates the mechanism and leaves the authoring where it belongs.
class IbadatContent {
  IbadatContent._();

  static const IbadatGuide namaz = IbadatGuide(
    pillar: 'Namaz',
    reviewed: false,
    sections: <IbadatSection>[
      IbadatSection(
        title: 'Beginning the prayer',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Face the qibla and stand',
            instruction:
                'Stand facing the Kaaba, feet settled, intending the prayer you are about to offer.',
            refs: <HadithRef>[
              HadithRef(
                book: HadithBook.bukhari,
                number: 757,
                note:
                    'The man told to repeat his prayer: face the qibla, then say takbir',
              ),
            ],
          ),
          IbadatStep(
            title: 'The opening takbir',
            instruction:
                'Raise both hands and say Allahu Akbar, then lower them.',
            arabic: 'اللَّهُ أَكْبَرُ',
            transliteration: 'Allahu Akbar',
            practiceDiffers:
                'How high the hands are raised, and whether they are raised again at later takbirs, differs between the schools of fiqh.',
            refs: <HadithRef>[
              HadithRef(
                book: HadithBook.bukhari,
                number: 735,
                note: 'The Prophet raised both hands on starting the prayer',
              ),
              HadithRef(
                book: HadithBook.bukhari,
                number: 736,
                note: 'Raising the hands on standing for prayer',
              ),
              HadithRef(
                book: HadithBook.bukhari,
                number: 739,
                note: 'Ibn Umar on when the hands were raised',
              ),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Prostration',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Prostrate on seven parts',
            instruction:
                'Go down into sujud so that seven parts touch the ground: the forehead, both hands, both knees and the toes of both feet.',
            refs: <HadithRef>[
              HadithRef(
                book: HadithBook.bukhari,
                number: 812,
                note: 'Ordered to prostrate on seven bones',
              ),
              HadithRef(
                book: HadithBook.bukhari,
                number: 809,
                note: 'The seven parts, and not tucking up the clothes',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
