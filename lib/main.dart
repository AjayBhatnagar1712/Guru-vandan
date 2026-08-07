import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

const allowedAdminEmail = 'ajaybhatnagar1712@gmail.com';

const _firebaseApiKey = String.fromEnvironment(
  'FIREBASE_API_KEY',
  defaultValue: 'AIzaSyBDnC1IE0BImeYue5vaOicS4_Miw0Vd2xE',
);

const _firebaseWebOptions = FirebaseOptions(
  apiKey: String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBDnC1IE0BImeYue5vaOicS4_Miw0Vd2xE',
  ),
  appId: String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:540841544767:web:guruvandan-flutter',
  ),
  messagingSenderId: '540841544767',
  projectId: 'guru-vandan',
  authDomain: 'guru-vandan.firebaseapp.com',
  databaseURL:
      'https://guru-vandan-default-rtdb.asia-southeast1.firebasedatabase.app/',
  storageBucket: 'guru-vandan.firebasestorage.app',
);

const _firebaseAndroidOptions = FirebaseOptions(
  apiKey: _firebaseApiKey,
  appId: String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:540841544767:android:6f5d1b40aba4f0c3cebc8a',
  ),
  messagingSenderId: '540841544767',
  projectId: 'guru-vandan',
  databaseURL:
      'https://guru-vandan-default-rtdb.asia-southeast1.firebasedatabase.app/',
  storageBucket: 'guru-vandan.firebasestorage.app',
);

FirebaseOptions get firebaseOptions {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return _firebaseAndroidOptions;
  }
  return _firebaseWebOptions;
}

ja.AudioPlayer? _backgroundAudioPlayer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureBackgroundAudio();
  var firebaseReady = false;

  try {
    await Firebase.initializeApp(options: firebaseOptions);
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(GuruvandanApp(firebaseReady: firebaseReady));
}

Future<void> _configureBackgroundAudio() async {
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ivar.guruvandan.audio',
      androidNotificationChannelName: 'Guruvandan playback',
      androidNotificationChannelDescription:
          'Satsang, meditation, and Om mantra playback controls',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
    );

    _backgroundAudioPlayer = ja.AudioPlayer(
      handleInterruptions: true,
      handleAudioSessionActivation: true,
    );

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  } catch (_) {
    _backgroundAudioPlayer ??= ja.AudioPlayer();
  }
}

class GuruvandanApp extends StatefulWidget {
  const GuruvandanApp({
    required this.firebaseReady,
    this.showOpening = true,
    super.key,
  });

  final bool firebaseReady;
  final bool showOpening;

  static const languageKey = 'guruvandan_flutter:language';

  @override
  State<GuruvandanApp> createState() => _GuruvandanAppState();
}

class _GuruvandanAppState extends State<GuruvandanApp> {
  AppLanguage? language;
  bool languageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(GuruvandanApp.languageKey);
    final saved =
        savedValue == null ? null : AppLanguagePreference.fromValue(savedValue);
    if (mounted) {
      setState(() {
        language = saved;
        languageLoaded = true;
      });
    }
  }

  Future<void> _setLanguage(AppLanguage value) async {
    if (language != value) setState(() => language = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GuruvandanApp.languageKey, value.name);
  }

  @override
  Widget build(BuildContext context) {
    final activeLanguage = language ?? AppLanguage.english;
    final textTheme = activeLanguage == AppLanguage.hindi
        ? GoogleFonts.notoSansDevanagariTextTheme()
        : GoogleFonts.interTextTheme();

    return LanguageScope(
      language: activeLanguage,
      onChanged: _setLanguage,
      child: MaterialApp(
        title: 'Guruvandan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.maroon,
            primary: AppColors.maroon,
            secondary: AppColors.gold,
            surface: AppColors.surface,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.cream,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.ink,
            centerTitle: false,
            elevation: 0,
            titleTextStyle: _headingStyle(
              activeLanguage,
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(56, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: _bodyStyle(
                activeLanguage,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(56, 54),
              side: const BorderSide(color: AppColors.borderStrong),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: _bodyStyle(
                activeLanguage,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          textTheme: textTheme.copyWith(
            displayLarge: _headingStyle(
              activeLanguage,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.04,
            ),
            headlineMedium: _headingStyle(
              activeLanguage,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.12,
            ),
            titleLarge: _bodyStyle(
              activeLanguage,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
            bodyLarge: _bodyStyle(
              activeLanguage,
              fontSize: 18,
              height: 1.42,
              color: AppColors.taupe,
            ),
          ),
        ),
        home: !languageLoaded
            ? const _LanguageLoadingScreen()
            : language == null
                ? _FirstLaunchLanguageScreen(onSelected: _setLanguage)
                : widget.showOpening
                    ? SpiritualOpening(firebaseReady: widget.firebaseReady)
                    : AuthGate(firebaseReady: widget.firebaseReady),
        routes: {
          '/admin': (_) => _AdminRoute(firebaseReady: widget.firebaseReady),
        },
      ),
    );
  }
}

class AppColors {
  static const maroon = Color(0xFF7B171D);
  static const crimson = Color(0xFFA42A30);
  static const deepCrimson = Color(0xFF4E1014);
  static const cream = Color(0xFFFBF6EC);
  static const offWhite = Color(0xFFFFFCF7);
  static const parchment = Color(0xFFF6E8D6);
  static const rose = Color(0xFFF4E1DF);
  static const gold = Color(0xFFC9963E);
  static const softGold = Color(0xFFF2D193);
  static const sage = Color(0xFF55745B);
  static const river = Color(0xFF5E8290);
  static const copper = Color(0xFFB96B3D);
  static const ink = Color(0xFF2B211F);
  static const taupe = Color(0xFF675A55);
  static const muted = Color(0xFF91857E);
  static const border = Color(0xFFE6D9CC);
  static const borderStrong = Color(0xFFD2BDA7);
  static const surface = Color(0xFFFFFFFF);
}

enum PracticeTab { home, satsang, meditate, wisdom, more }

enum SatsangSession { morning, evening, aarti }

enum RoutineTask { morningSatsang, eveningSatsang, meditation }

enum MeditationChantPhase { closing }

enum AppLanguage { english, hindi }

enum BackgroundPlaybackKind { none, satsang, mantra, meditation, closingChant }

class AppLanguagePreference {
  static AppLanguage fromValue(String? value) {
    return value == AppLanguage.hindi.name
        ? AppLanguage.hindi
        : AppLanguage.english;
  }
}

class _LanguageLoadingScreen extends StatelessWidget {
  const _LanguageLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _SacredBackground()),
          Center(
            child: CircularProgressIndicator(
              color: AppColors.maroon,
              backgroundColor: AppColors.rose,
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstLaunchLanguageScreen extends StatelessWidget {
  const _FirstLaunchLanguageScreen({required this.onSelected});

  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _SacredBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 126,
                          height: 126,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderStrong),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.deepCrimson
                                    .withValues(alpha: 0.12),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Choose your language',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lora(
                          color: AppColors.ink,
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'अपनी भाषा चुनें',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSerifDevanagari(
                          color: AppColors.maroon,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You can change this later from More.\nआप इसे बाद में More से बदल सकते हैं।',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansDevanagari(
                          color: AppColors.taupe,
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _LanguageChoiceButton(
                        iconText: 'A',
                        title: 'Continue in English',
                        subtitle: 'English',
                        onTap: () => onSelected(AppLanguage.english),
                      ),
                      const SizedBox(height: 14),
                      _LanguageChoiceButton(
                        iconText: 'अ',
                        title: 'हिंदी में आगे बढ़ें',
                        subtitle: 'Hindi',
                        hindi: true,
                        onTap: () => onSelected(AppLanguage.hindi),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChoiceButton extends StatelessWidget {
  const _LanguageChoiceButton({
    required this.iconText,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.hindi = false,
  });

  final String iconText;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool hindi;

  @override
  Widget build(BuildContext context) {
    final titleStyle = hindi
        ? GoogleFonts.notoSansDevanagari(
            color: AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          )
        : GoogleFonts.inter(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          );

    return Material(
      color: AppColors.offWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 78),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.rose,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    iconText,
                    style: hindi
                        ? GoogleFonts.notoSerifDevanagari(
                            color: AppColors.maroon,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          )
                        : GoogleFonts.lora(
                            color: AppColors.maroon,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: AppColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.maroon,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageScope extends InheritedWidget {
  const LanguageScope({
    required this.language,
    required this.onChanged,
    required super.child,
    super.key,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  static LanguageScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'LanguageScope was not found in the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(LanguageScope oldWidget) {
    return language != oldWidget.language || onChanged != oldWidget.onChanged;
  }
}

String appText(BuildContext context, String english, String hindi) {
  return LanguageScope.of(context).language == AppLanguage.hindi
      ? hindi
      : english;
}

TextStyle _headingStyle(
  AppLanguage language, {
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
}) {
  if (language == AppLanguage.hindi) {
    return GoogleFonts.notoSerifDevanagari(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }
  return GoogleFonts.lora(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
  );
}

TextStyle _bodyStyle(
  AppLanguage language, {
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
}) {
  if (language == AppLanguage.hindi) {
    return GoogleFonts.notoSansDevanagari(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }
  return GoogleFonts.inter(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
  );
}

class DevoteeProfile {
  const DevoteeProfile({
    required this.firstName,
    this.middleName = '',
    this.lastName = '',
  });

  final String firstName;
  final String middleName;
  final String lastName;

  String get displayName => firstName;

  String get fullName => [
        firstName,
        middleName,
        lastName,
      ].where((part) => part.trim().isNotEmpty).join(' ');

  Map<String, String> toJson() => {
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
      };

  static DevoteeProfile? fromMap(Object? value) {
    if (value is! Map) return null;
    return fromParts(
      firstName: value['firstName']?.toString() ?? '',
      middleName: value['middleName']?.toString() ?? '',
      lastName: value['lastName']?.toString() ?? '',
    );
  }

  static DevoteeProfile? fromParts({
    required String firstName,
    required String middleName,
    required String lastName,
  }) {
    final first = _cleanNamePart(firstName);
    if (first.isEmpty) return null;

    return DevoteeProfile(
      firstName: first,
      middleName: _cleanNamePart(middleName),
      lastName: _cleanNamePart(lastName),
    );
  }

  static DevoteeProfile? fromStoredValue(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;

    if (clean.startsWith('{')) {
      try {
        final decoded = jsonDecode(clean);
        final profile = fromMap(decoded);
        if (profile != null) return profile;
      } catch (_) {
        return null;
      }
    }

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;
    if (parts.length == 1) {
      return fromParts(firstName: parts.first, middleName: '', lastName: '');
    }
    if (parts.length == 2) {
      return fromParts(
          firstName: parts.first, middleName: '', lastName: parts.last);
    }

    return fromParts(
      firstName: parts.first,
      middleName: parts.sublist(1, parts.length - 1).join(' '),
      lastName: parts.last,
    );
  }
}

class SatsangTrack {
  const SatsangTrack({
    required this.id,
    required this.session,
    required this.title,
    required this.description,
    required this.durationLabel,
    this.audioUrl,
    this.assetPath,
    this.active = true,
    this.createdAt,
  });

  final String id;
  final SatsangSession session;
  final String title;
  final String description;
  final String durationLabel;
  final String? audioUrl;
  final String? assetPath;
  final bool active;
  final int? createdAt;

  factory SatsangTrack.fromEntry(String id, Map<dynamic, dynamic> value) {
    return SatsangTrack(
      id: id,
      session: _satsangSessionFromValue(value['session']),
      title: (value['title'] ?? 'Satsang').toString(),
      description: (value['description'] ?? 'Sacred audio for daily practice.')
          .toString(),
      durationLabel: (value['durationLabel'] ?? '00:00').toString(),
      audioUrl: value['audioUrl']?.toString(),
      active: value['active'] != false,
      createdAt: value['createdAt'] is int ? value['createdAt'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session': session.name,
      'title': title,
      'description': description,
      'durationLabel': durationLabel,
      'audioUrl': audioUrl,
      'active': active,
      'createdAt': createdAt,
    };
  }
}

class WisdomQuote {
  const WisdomQuote({
    required this.id,
    required this.text,
    this.textHindi = '',
    this.author = 'Sadguru Maharaj',
    this.authorHindi = 'सद्गुरु महाराज',
    this.active = true,
    this.createdAt,
  });

  final String id;
  final String text;
  final String textHindi;
  final String author;
  final String authorHindi;
  final bool active;
  final int? createdAt;

  factory WisdomQuote.fromEntry(String id, Map<dynamic, dynamic> value) {
    return WisdomQuote(
      id: id,
      text: (value['textEnglish'] ?? value['text'] ?? '').toString(),
      textHindi: (value['textHindi'] ?? '').toString(),
      author: (value['authorEnglish'] ?? value['author'] ?? 'Sadguru Maharaj')
          .toString(),
      authorHindi: (value['authorHindi'] ?? 'सद्गुरु महाराज').toString(),
      active: value['active'] != false,
      createdAt: value['createdAt'] is int ? value['createdAt'] as int : null,
    );
  }
}

class RoutineStats {
  const RoutineStats({
    required this.current,
    required this.best,
    required this.total,
    required this.daysToMilestone,
  });

  final int current;
  final int best;
  final int total;
  final int daysToMilestone;
}

const fallbackSatsangs = [
  SatsangTrack(
    id: 'local-morning',
    session: SatsangSession.morning,
    title: 'Morning Satsang',
    description: 'Begin the day with Astuti from Rishikesh.',
    durationLabel: '57:10',
    assetPath: 'audio/morning_satsang_astuti_rishikesh.mp3',
  ),
  SatsangTrack(
    id: 'local-evening',
    session: SatsangSession.evening,
    title: 'Shaam Satsang',
    description: 'Close the day with the full evening satsang.',
    durationLabel: '24:11',
    assetPath: 'audio/shaam_satsang_full.mp3',
  ),
  SatsangTrack(
    id: 'local-aarti',
    session: SatsangSession.aarti,
    title: 'Shaam Aarti',
    description: 'Evening aarti for devotion and gratitude.',
    durationLabel: '08:46',
    assetPath: 'audio/shaam_aarti.mp3',
  ),
];

const fallbackQuotes = [
  WisdomQuote(
    id: 'quote-1',
    text:
        'Remember the Guru with a simple heart, and every step becomes worship.',
  ),
  WisdomQuote(
    id: 'quote-2',
    text: 'The mind becomes gentle when the day begins and ends in satsang.',
  ),
  WisdomQuote(
    id: 'quote-3',
    text:
        'Meditation is not distance from life. It is returning to the light within life.',
  ),
];

SatsangTrack localizedSatsangTrack(
  BuildContext context,
  SatsangTrack track,
) {
  if (LanguageScope.of(context).language != AppLanguage.hindi) return track;

  switch (track.id) {
    case 'local-morning':
      return SatsangTrack(
        id: track.id,
        session: track.session,
        title: 'प्रातः सत्संग',
        description: 'ऋषिकेश की स्तुति के साथ दिन की शुरुआत करें।',
        durationLabel: track.durationLabel,
        assetPath: track.assetPath,
        audioUrl: track.audioUrl,
        active: track.active,
        createdAt: track.createdAt,
      );
    case 'local-evening':
      return SatsangTrack(
        id: track.id,
        session: track.session,
        title: 'शाम सत्संग',
        description: 'पूर्ण संध्या सत्संग के साथ दिन को शांत करें।',
        durationLabel: track.durationLabel,
        assetPath: track.assetPath,
        audioUrl: track.audioUrl,
        active: track.active,
        createdAt: track.createdAt,
      );
    case 'local-aarti':
      return SatsangTrack(
        id: track.id,
        session: track.session,
        title: 'शाम आरती',
        description: 'भक्ति और कृतज्ञता के लिए संध्या आरती।',
        durationLabel: track.durationLabel,
        assetPath: track.assetPath,
        audioUrl: track.audioUrl,
        active: track.active,
        createdAt: track.createdAt,
      );
    default:
      return track;
  }
}

WisdomQuote localizedWisdomQuote(
  BuildContext context,
  WisdomQuote quote,
) {
  if (LanguageScope.of(context).language != AppLanguage.hindi) return quote;

  if (quote.textHindi.trim().isNotEmpty) {
    return WisdomQuote(
      id: quote.id,
      text: quote.textHindi,
      textHindi: quote.textHindi,
      author: quote.authorHindi.trim().isEmpty
          ? 'सद्गुरु महाराज'
          : quote.authorHindi,
      authorHindi: quote.authorHindi,
      active: quote.active,
      createdAt: quote.createdAt,
    );
  }

  switch (quote.id) {
    case 'quote-1':
      return WisdomQuote(
        id: quote.id,
        text: 'सरल हृदय से गुरु का स्मरण करें, और हर कदम पूजा बन जाता है।',
        author: 'सद्गुरु महाराज',
        active: quote.active,
        createdAt: quote.createdAt,
      );
    case 'quote-2':
      return WisdomQuote(
        id: quote.id,
        text: 'दिन की शुरुआत और अंत सत्संग से हो तो मन कोमल हो जाता है।',
        author: 'सद्गुरु महाराज',
        active: quote.active,
        createdAt: quote.createdAt,
      );
    case 'quote-3':
      return WisdomQuote(
        id: quote.id,
        text:
            'ध्यान जीवन से दूरी नहीं है। यह जीवन के भीतर प्रकाश की ओर लौटना है।',
        author: 'सद्गुरु महाराज',
        active: quote.active,
        createdAt: quote.createdAt,
      );
    default:
      if (quote.author == 'Sadguru Maharaj') {
        return WisdomQuote(
          id: quote.id,
          text: quote.text,
          author: 'सद्गुरु महाराज',
          active: quote.active,
          createdAt: quote.createdAt,
        );
      }
      return quote;
  }
}

class FirebaseContentService {
  FirebaseContentService(this.ready);

  final bool ready;

  Stream<List<SatsangTrack>> satsangs() {
    if (!ready) return Stream.value(fallbackSatsangs);

    return FirebaseDatabase.instance.ref('satsangs').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return fallbackSatsangs;

      final items = value.entries
          .map((entry) {
            if (entry.value is! Map) return null;
            return SatsangTrack.fromEntry(entry.key.toString(),
                Map<dynamic, dynamic>.from(entry.value as Map));
          })
          .whereType<SatsangTrack>()
          .where((item) => item.active)
          .toList()
        ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

      return items.isEmpty ? fallbackSatsangs : items;
    }).handleError((_) => fallbackSatsangs);
  }

  Stream<List<WisdomQuote>> quotes() {
    if (!ready) return Stream.value(fallbackQuotes);

    return FirebaseDatabase.instance.ref('quotes').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return fallbackQuotes;

      final items = value.entries
          .map((entry) {
            if (entry.value is! Map) return null;
            return WisdomQuote.fromEntry(entry.key.toString(),
                Map<dynamic, dynamic>.from(entry.value as Map));
          })
          .whereType<WisdomQuote>()
          .where((item) => item.active && item.text.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

      return items.isEmpty ? fallbackQuotes : items;
    }).handleError((_) => fallbackQuotes);
  }

  Stream<List<WisdomQuote>> adminQuotes() {
    if (!ready) return Stream.value(const []);

    return FirebaseDatabase.instance.ref('quotes').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <WisdomQuote>[];

      final items = value.entries
          .map((entry) {
            if (entry.value is! Map) return null;
            return WisdomQuote.fromEntry(entry.key.toString(),
                Map<dynamic, dynamic>.from(entry.value as Map));
          })
          .whereType<WisdomQuote>()
          .where((item) =>
              item.text.trim().isNotEmpty || item.textHindi.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

      return items;
    });
  }

  Future<void> uploadSatsang({
    required PlatformFile file,
    required SatsangSession session,
    required String title,
    required String description,
    required String durationLabel,
  }) async {
    if (!ready) throw StateError('Firebase is not configured.');
    if (file.bytes == null) {
      throw StateError('Could not read the selected file.');
    }

    final safeName =
        file.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]+'), '-');
    final path =
        'satsang/${session.name}/${DateTime.now().millisecondsSinceEpoch}-$safeName';
    final storageRef = FirebaseStorage.instance.ref(path);
    await storageRef.putData(file.bytes!,
        SettableMetadata(contentType: _audioContentType(file.name)));
    final url = await storageRef.getDownloadURL();
    final key = FirebaseDatabase.instance.ref('satsangs').push().key;
    if (key == null) throw StateError('Could not create a satsang record.');

    await FirebaseDatabase.instance.ref('satsangs/$key').set({
      'session': session.name,
      'title': title,
      'description': description,
      'durationLabel': durationLabel,
      'audioUrl': url,
      'storagePath': path,
      'active': true,
      'createdAt': ServerValue.timestamp,
      'createdBy': FirebaseAuth.instance.currentUser?.email,
    });
  }

  Future<void> publishQuote({
    required String textEnglish,
    required String textHindi,
    required String authorEnglish,
    required String authorHindi,
  }) async {
    if (!ready) throw StateError('Firebase is not configured.');
    final key = FirebaseDatabase.instance.ref('quotes').push().key;
    if (key == null) throw StateError('Could not create a quote record.');
    await FirebaseDatabase.instance.ref('quotes/$key').set({
      'text': textEnglish,
      'textEnglish': textEnglish,
      'textHindi': textHindi,
      'author': authorEnglish,
      'authorEnglish': authorEnglish,
      'authorHindi': authorHindi,
      'active': true,
      'createdAt': ServerValue.timestamp,
      'createdBy': FirebaseAuth.instance.currentUser?.email,
    });
  }

  Future<void> updateQuote({
    required String id,
    required String textEnglish,
    required String textHindi,
    required String authorEnglish,
    required String authorHindi,
  }) async {
    if (!ready) throw StateError('Firebase is not configured.');
    await FirebaseDatabase.instance.ref('quotes/$id').update({
      'text': textEnglish,
      'textEnglish': textEnglish,
      'textHindi': textHindi,
      'author': authorEnglish,
      'authorEnglish': authorEnglish,
      'authorHindi': authorHindi,
      'updatedAt': ServerValue.timestamp,
      'updatedBy': FirebaseAuth.instance.currentUser?.email,
    });
  }

  Future<bool> isAdmin(User? user) async {
    if (!ready || user == null) return false;
    if (user.email == allowedAdminEmail) return true;

    final snapshot =
        await FirebaseDatabase.instance.ref('admins/${user.uid}').get();
    return snapshot.value == true;
  }
}

class SpiritualOpening extends StatefulWidget {
  const SpiritualOpening({required this.firebaseReady, super.key});

  final bool firebaseReady;

  @override
  State<SpiritualOpening> createState() => _SpiritualOpeningState();
}

class _SpiritualOpeningState extends State<SpiritualOpening>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  bool showApp = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _openApp();
  }

  Future<void> _openApp() async {
    await Future<void>.delayed(const Duration(milliseconds: 2850));
    if (mounted) setState(() => showApp = true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: showApp
          ? AuthGate(
              key: const ValueKey('devotee-shell'),
              firebaseReady: widget.firebaseReady)
          : _OpeningScreen(
              key: const ValueKey('opening'), progress: controller),
    );
  }
}

class _OpeningScreen extends StatelessWidget {
  const _OpeningScreen({required this.progress, super.key});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final eased = Curves.easeOutCubic.transform(progress.value);
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _OpeningScenePainter(eased)),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - eased)),
                        child: Opacity(
                          opacity: eased,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 132,
                                height: 132,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: AppColors.offWhite
                                      .withValues(alpha: 0.92),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.softGold, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.deepCrimson
                                          .withValues(alpha: 0.18),
                                      blurRadius: 30,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                      'assets/images/app_icon.png',
                                      fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'Guruvandan',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lora(
                                  color: AppColors.deepCrimson,
                                  fontSize: 42,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                appText(
                                  context,
                                  'Smaran. Satsang. Dhyan.',
                                  'स्मरण. सत्संग. ध्यान.',
                                ),
                                textAlign: TextAlign.center,
                                style: _bodyStyle(
                                  LanguageScope.of(context).language,
                                  color: AppColors.taupe,
                                  fontSize: 18,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: 180,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: progress.value,
                                    minHeight: 7,
                                    color: AppColors.maroon,
                                    backgroundColor: AppColors.rose,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OpeningScenePainter extends CustomPainter {
  _OpeningScenePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFBF4),
          Color(0xFFF6E1C6),
          Color(0xFFEAB78C),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    final sunY = size.height * (0.78 - 0.26 * progress);
    final sunPaint = Paint()
      ..color = AppColors.softGold.withValues(alpha: 0.46 + 0.28 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(
        Offset(size.width * 0.5, sunY), size.width * 0.23, sunPaint);

    final horizon = Paint()..color = AppColors.maroon.withValues(alpha: 0.08);
    final hill = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.61,
          size.width * 0.5, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.78, size.height * 0.79, size.width, size.height * 0.64)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, horizon);

    final foreground = Paint()
      ..color = AppColors.deepCrimson.withValues(alpha: 0.9);
    final baseY = size.height * 0.82;
    final templeWidth = min(size.width * 0.48, 230.0);
    final templeLeft = (size.width - templeWidth) / 2;
    final templeRight = templeLeft + templeWidth;
    final pillarWidth = templeWidth * 0.1;

    final roof = Path()
      ..moveTo(templeLeft + templeWidth * 0.08, baseY - 74)
      ..lineTo(size.width / 2, baseY - 132 - 18 * progress)
      ..lineTo(templeRight - templeWidth * 0.08, baseY - 74)
      ..close();
    canvas.drawPath(roof, foreground);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(templeLeft + templeWidth * 0.18, baseY - 72,
            templeWidth * 0.64, 10),
        const Radius.circular(3),
      ),
      foreground,
    );
    for (final x in [
      templeLeft + templeWidth * 0.25,
      templeLeft + templeWidth * 0.43,
      templeLeft + templeWidth * 0.57,
      templeLeft + templeWidth * 0.75,
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - pillarWidth / 2, baseY - 66, pillarWidth, 66),
          const Radius.circular(4),
        ),
        foreground,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            templeLeft + templeWidth * 0.14, baseY, templeWidth * 0.72, 12),
        const Radius.circular(4),
      ),
      foreground,
    );

    final diyaCenter = Offset(size.width * 0.5, size.height * 0.9);
    final flame = Path()
      ..moveTo(diyaCenter.dx, diyaCenter.dy - 70 * progress)
      ..cubicTo(diyaCenter.dx - 25, diyaCenter.dy - 38, diyaCenter.dx - 8,
          diyaCenter.dy - 18, diyaCenter.dx, diyaCenter.dy - 28)
      ..cubicTo(diyaCenter.dx + 18, diyaCenter.dy - 49, diyaCenter.dx + 11,
          diyaCenter.dy - 59, diyaCenter.dx, diyaCenter.dy - 70 * progress)
      ..close();
    canvas.drawPath(
        flame, Paint()..color = AppColors.gold.withValues(alpha: progress));
    canvas.drawOval(
      Rect.fromCenter(center: diyaCenter, width: 150, height: 34),
      Paint()..color = AppColors.maroon.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _OpeningScenePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({required this.firebaseReady, super.key});

  final bool firebaseReady;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<String?> startup = _prepareAuthStartup();

  Future<String?> _prepareAuthStartup() async {
    if (!widget.firebaseReady || !kIsWeb) return null;

    final googleCouldNotComplete = appText(
      context,
      'Google sign-in could not be completed. Please try again.',
      'Google साइन-इन पूरा नहीं हो सका। कृपया फिर कोशिश करें।',
    );

    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      await FirebaseAuth.instance.getRedirectResult();
    } on FirebaseAuthException catch (error) {
      return _friendlyAuthMessage(error, 'Google sign-in failed.');
    } catch (_) {
      return googleCouldNotComplete;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseReady) {
      return const DevoteeShell(firebaseReady: false);
    }

    return FutureBuilder<String?>(
      future: startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            FirebaseAuth.instance.currentUser == null) {
          return const _AuthLoadingScaffold();
        }

        final startupError = snapshot.data;

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.idTokenChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            if (authSnapshot.connectionState == ConnectionState.waiting &&
                user == null) {
              return const _AuthLoadingScaffold();
            }

            if (user == null) {
              return _SignInScreen(
                initialStatus: startupError,
                initialStatusIsError: startupError != null,
              );
            }

            return DevoteeShell(
              key: ValueKey('devotee-shell-${user.uid}'),
              firebaseReady: widget.firebaseReady,
              user: user,
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingScaffold extends StatelessWidget {
  const _AuthLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _SacredBackground()),
          SafeArea(child: _ProfileLoadingScreen()),
        ],
      ),
    );
  }
}

class _SignInScreen extends StatefulWidget {
  const _SignInScreen({
    this.initialStatus,
    this.initialStatusIsError = false,
  });

  final String? initialStatus;
  final bool initialStatusIsError;

  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  ConfirmationResult? confirmationResult;
  String? verificationId;
  bool otpSent = false;
  bool busy = false;
  String? status;
  bool statusIsError = false;

  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;
    statusIsError = widget.initialStatusIsError;
  }

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final googleCouldNotComplete = appText(
      context,
      'Google sign-in could not be completed.',
      'Google साइन-इन पूरा नहीं हो सका।',
    );

    setState(() {
      busy = true;
      status = null;
      statusIsError = false;
    });

    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      if (kIsWeb) {
        try {
          await FirebaseAuth.instance.signInWithPopup(provider);
        } on FirebaseAuthException catch (error) {
          if (!_shouldFallbackToRedirect(error.code)) rethrow;
          await FirebaseAuth.instance.signInWithRedirect(provider);
        }
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (error) {
      _setError(_friendlyAuthMessage(error, 'Google sign-in failed.'));
    } catch (_) {
      _setError(googleCouldNotComplete);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sendOtp() async {
    final couldNotSendOtp = appText(
      context,
      'Could not send OTP. Try again.',
      'OTP नहीं भेजा जा सका। कृपया फिर कोशिश करें।',
    );
    final phoneNumber = _normalizedPhone(phone.text);
    if (phoneNumber == null) {
      _setError(appText(
        context,
        'Enter a valid phone number with country code.',
        'देश कोड के साथ सही फोन नंबर दर्ज करें।',
      ));
      return;
    }

    setState(() {
      busy = true;
      status = null;
      statusIsError = false;
    });

    try {
      if (kIsWeb) {
        confirmationResult =
            await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);
        if (mounted) {
          setState(() {
            otpSent = true;
            status = appText(
              context,
              'OTP sent to $phoneNumber.',
              '$phoneNumber पर OTP भेजा गया।',
            );
            statusIsError = false;
          });
        }
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (credential) async {
            await FirebaseAuth.instance.signInWithCredential(credential);
          },
          verificationFailed: (error) {
            if (mounted) {
              _setError(error.message ??
                  appText(
                    context,
                    'Phone verification failed.',
                    'फोन सत्यापन असफल रहा।',
                  ));
            }
          },
          codeSent: (id, _) {
            if (mounted) {
              setState(() {
                verificationId = id;
                otpSent = true;
                status = appText(
                  context,
                  'OTP sent to $phoneNumber.',
                  '$phoneNumber पर OTP भेजा गया।',
                );
                statusIsError = false;
              });
            }
          },
          codeAutoRetrievalTimeout: (id) {
            verificationId = id;
          },
        );
      }
    } on FirebaseAuthException catch (error) {
      _setError(_friendlyAuthMessage(error, 'Could not send OTP.'));
    } catch (_) {
      _setError(couldNotSendOtp);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otpCouldNotComplete = appText(
      context,
      'OTP verification could not be completed.',
      'OTP सत्यापन पूरा नहीं हो सका।',
    );
    final code = otp.text.trim();
    if (code.length < 4) {
      _setError(appText(
        context,
        'Enter the OTP received on your phone.',
        'फोन पर प्राप्त OTP दर्ज करें।',
      ));
      return;
    }

    setState(() {
      busy = true;
      status = null;
      statusIsError = false;
    });

    try {
      if (kIsWeb) {
        final result = confirmationResult;
        if (result == null) {
          _setError(appText(
            context,
            'Please request OTP again.',
            'कृपया फिर से OTP मंगाएं।',
          ));
          return;
        }
        await result.confirm(code);
      } else {
        final id = verificationId;
        if (id == null) {
          _setError(appText(
            context,
            'Please request OTP again.',
            'कृपया फिर से OTP मंगाएं।',
          ));
          return;
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: id,
          smsCode: code,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (error) {
      _setError(_friendlyAuthMessage(error, 'OTP verification failed.'));
    } catch (_) {
      _setError(otpCouldNotComplete);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      status = message;
      statusIsError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _SacredBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                    decoration:
                        _cardDecoration(color: AppColors.offWhite).copyWith(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepCrimson.withValues(alpha: 0.11),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 116,
                            height: 116,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderStrong),
                            ),
                            child: Image.asset('assets/images/app_icon.png',
                                fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          appText(
                            context,
                            'Sign in to Guruvandan',
                            'गुरुवंदन में साइन इन करें',
                          ),
                          textAlign: TextAlign.center,
                          style: _headingStyle(
                            LanguageScope.of(context).language,
                            color: AppColors.ink,
                            fontSize: 31,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          appText(
                            context,
                            'Use Google or phone number to begin your spiritual routine.',
                            'अपनी आध्यात्मिक दिनचर्या शुरू करने के लिए Google या फोन नंबर का उपयोग करें।',
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: busy ? null : _signInWithGoogle,
                          icon:
                              const Icon(Icons.g_mobiledata_rounded, size: 31),
                          label: Text(appText(
                            context,
                            'Continue with Google',
                            'Google से जारी रखें',
                          )),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(58),
                            backgroundColor: AppColors.maroon,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                appText(context, 'or phone', 'या फोन'),
                                style: TextStyle(
                                  color: AppColors.taupe,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: phone,
                          enabled: !busy && !otpSent,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(appText(
                            context,
                            'Phone number',
                            'फोन नंबर',
                          )).copyWith(
                            hintText: '+91 98765 43210',
                            prefixIcon: const Icon(Icons.phone_rounded),
                          ),
                        ),
                        if (otpSent) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: otp,
                            enabled: !busy,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _verifyOtp(),
                            decoration: _inputDecoration(appText(
                              context,
                              'OTP code',
                              'OTP कोड',
                            )).copyWith(
                              prefixIcon: const Icon(Icons.sms_rounded),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed:
                              busy ? null : (otpSent ? _verifyOtp : _sendOtp),
                          icon: Icon(otpSent
                              ? Icons.verified_user_rounded
                              : Icons.sms_rounded),
                          label: Text(otpSent
                              ? appText(
                                  context, 'Verify OTP', 'OTP सत्यापित करें')
                              : appText(context, 'Send OTP', 'OTP भेजें')),
                        ),
                        if (otpSent) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () {
                                    setState(() {
                                      otp.clear();
                                      confirmationResult = null;
                                      verificationId = null;
                                      otpSent = false;
                                      status = null;
                                    });
                                  },
                            child: Text(appText(
                              context,
                              'Use another phone number',
                              'दूसरा फोन नंबर उपयोग करें',
                            )),
                          ),
                        ],
                        if (status != null) ...[
                          const SizedBox(height: 14),
                          _StatusText(
                            status!,
                            isError: statusIsError,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DevoteeShell extends StatefulWidget {
  const DevoteeShell({required this.firebaseReady, this.user, super.key});

  final bool firebaseReady;
  final User? user;

  @override
  State<DevoteeShell> createState() => _DevoteeShellState();
}

class _DevoteeShellState extends State<DevoteeShell>
    with WidgetsBindingObserver {
  static const routineKey = 'guruvandan_flutter:routine';
  static const nameKey = 'guruvandan_flutter:name';

  late final FirebaseContentService content;
  final List<StreamSubscription<dynamic>> audioSubscriptions = [];

  PracticeTab tab = PracticeTab.home;
  SatsangSession selectedSession = _defaultSession();
  DevoteeProfile? devoteeProfile;
  bool localStateLoaded = false;
  bool needsProfileName = false;
  Map<String, Map<String, bool>> records = {};
  String? activeTrackId;
  RoutineTask? activeTrackTask;
  Duration audioPosition = Duration.zero;
  Duration audioDuration = Duration.zero;

  int selectedDurationSeconds = 10 * 60;
  int remainingSeconds = 10 * 60;
  bool customMeditationDurationSelected = false;
  bool meditationRunning = false;
  bool meditationComplete = false;
  bool meditationSessionStarted = false;
  bool mantraLoopEnabled = false;
  bool mantraLoopPlaying = false;
  bool meditationUsesMantra = false;
  bool backgroundAudioPlaying = false;
  bool audioMutationInProgress = false;
  bool audioCompletionHandled = false;
  bool silentPromptOpen = false;
  BackgroundPlaybackKind playbackKind = BackgroundPlaybackKind.none;
  int meditationRunToken = 0;
  MeditationChantPhase? meditationChantPhase;
  DateTime? meditationEndsAt;
  bool welcomeDialogShown = false;
  Timer? meditationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    content = FirebaseContentService(widget.firebaseReady);
    _loadLocalState();
    _wireAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    meditationTimer?.cancel();
    for (final subscription in audioSubscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncMeditationTimerWithClock();
    }
  }

  void _wireAudio() {
    final player = _backgroundAudioPlayer;
    if (player == null) return;

    audioSubscriptions.add(player.positionStream.listen((position) {
      if (mounted && playbackKind == BackgroundPlaybackKind.satsang) {
        setState(() => audioPosition = position);
      }
    }));
    audioSubscriptions.add(player.durationStream.listen((duration) {
      if (mounted &&
          playbackKind == BackgroundPlaybackKind.satsang &&
          duration != null) {
        setState(() => audioDuration = duration);
      }
    }));
    audioSubscriptions.add(
      player.playerStateStream.listen(_handleBackgroundPlayerState),
    );
  }

  void _handleBackgroundPlayerState(ja.PlayerState state) {
    final kind = playbackKind;

    if (mounted) {
      setState(() {
        backgroundAudioPlaying = state.playing;
        mantraLoopPlaying = state.playing &&
            (kind == BackgroundPlaybackKind.mantra ||
                (kind == BackgroundPlaybackKind.meditation &&
                    meditationUsesMantra));
      });
    }

    if (audioMutationInProgress) return;

    if (state.processingState == ja.ProcessingState.completed &&
        !audioCompletionHandled) {
      audioCompletionHandled = true;
      unawaited(_handleBackgroundCompletion(kind));
      return;
    }

    if (kind == BackgroundPlaybackKind.meditation &&
        meditationSessionStarted &&
        meditationChantPhase == null) {
      if (!state.playing &&
          meditationRunning &&
          state.processingState == ja.ProcessingState.ready) {
        _pauseMeditationClock();
      } else if (state.playing && !meditationRunning && remainingSeconds > 0) {
        _startMeditationTimer(meditationRunToken);
      }
    }

    if (state.processingState == ja.ProcessingState.idle &&
        kind != BackgroundPlaybackKind.none) {
      unawaited(_handleBackgroundStop(kind));
    }
  }

  String get _nameStorageKey =>
      widget.user == null ? nameKey : '$nameKey:${widget.user!.uid}';

  String get _routineStorageKey =>
      widget.user == null ? routineKey : '$routineKey:${widget.user!.uid}';

  DatabaseReference? get _cloudProfileReference {
    final user = widget.user;
    if (!widget.firebaseReady || user == null) return null;
    return FirebaseDatabase.instance.ref('users/${user.uid}/profile');
  }

  Future<DevoteeProfile?> _loadCloudProfile() async {
    final reference = _cloudProfileReference;
    if (reference == null) return null;

    try {
      final snapshot =
          await reference.get().timeout(const Duration(seconds: 6));
      return DevoteeProfile.fromMap(snapshot.value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCloudProfile(DevoteeProfile profile) async {
    final reference = _cloudProfileReference;
    if (reference == null) return;

    try {
      await reference.set({
        ...profile.toJson(),
        'profileCompleted': true,
        'updatedAt': ServerValue.timestamp,
      }).timeout(const Duration(seconds: 8));
    } catch (_) {
      // The local account copy remains available while Firebase is offline.
    }
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserName = prefs.getString(_nameStorageKey);
    final savedRecords = prefs.getString(_routineStorageKey) ??
        (widget.user == null ? null : prefs.getString(routineKey));
    var savedProfile = DevoteeProfile.fromStoredValue(savedUserName);

    if (savedProfile == null && widget.user == null) {
      savedProfile = DevoteeProfile.fromStoredValue(prefs.getString(nameKey));
    }
    savedProfile ??= await _loadCloudProfile();

    if (savedProfile != null) {
      devoteeProfile = savedProfile;
      await prefs.setString(_nameStorageKey, jsonEncode(savedProfile.toJson()));
      if (widget.user != null) unawaited(_saveCloudProfile(savedProfile));
    } else {
      needsProfileName = true;
    }

    if (savedRecords != null) {
      try {
        final decoded = jsonDecode(savedRecords);
        if (decoded is Map) {
          records = decoded.map((date, value) {
            if (value is! Map) {
              return MapEntry(date.toString(), <String, bool>{});
            }
            final item = Map<String, dynamic>.from(value);
            return MapEntry(
              date.toString(),
              item.map((key, done) => MapEntry(key, done == true)),
            );
          });
        }
      } catch (_) {
        records = {};
      }
    }

    localStateLoaded = true;
    if (mounted) setState(() {});
    _scheduleWelcomeDialog();
  }

  Future<void> _saveProfile(DevoteeProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameStorageKey, jsonEncode(profile.toJson()));
    if (widget.user != null) unawaited(_saveCloudProfile(profile));
    if (mounted) {
      setState(() {
        devoteeProfile = profile;
        needsProfileName = false;
      });
    }
    _scheduleWelcomeDialog();
  }

  void _scheduleWelcomeDialog() {
    if (welcomeDialogShown || needsProfileName || devoteeProfile == null) {
      return;
    }

    welcomeDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || needsProfileName || devoteeProfile == null) return;
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Welcome',
        barrierColor: AppColors.deepCrimson.withValues(alpha: 0.34),
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _GuruWelcomeDialog(name: devoteeProfile!.displayName);
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curve),
              child: child,
            ),
          );
        },
      );
    });
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routineStorageKey, jsonEncode(records));
  }

  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Map<String, bool> get today => records[todayKey] ?? {};

  RoutineStats get stats {
    final completeKeys = records.entries
        .where((entry) => _isMeditationDay(entry.value))
        .map((entry) => entry.key)
        .toList()
      ..sort();

    var best = 0;
    var run = 0;
    DateTime? previous;

    for (final key in completeKeys) {
      final current = DateTime.parse(key);
      if (previous != null && current.difference(previous).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      best = max(best, run);
      previous = current;
    }

    var cursor = DateTime.now();
    if (!_isMeditationDay(
        records[DateFormat('yyyy-MM-dd').format(cursor)] ?? {})) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var current = 0;
    while (_isMeditationDay(
        records[DateFormat('yyyy-MM-dd').format(cursor)] ?? {})) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    const milestones = [7, 21, 40, 90, 108, 365];
    final next = milestones.firstWhere((item) => item > current,
        orElse: () => current + 108);

    return RoutineStats(
      current: current,
      best: best,
      total: completeKeys.length,
      daysToMilestone: next - current,
    );
  }

  bool _isMeditationDay(Map<String, bool> item) {
    return item[RoutineTask.meditation.name] == true;
  }

  Future<void> _markTask(RoutineTask task) async {
    setState(() {
      records[todayKey] = {
        ...today,
        task.name: true,
      };
    });
    await _saveRecords();
  }

  MediaItem _backgroundMediaItem({
    required String id,
    required String title,
    required String description,
    Duration? duration,
  }) {
    return MediaItem(
      id: id,
      album: 'Guruvandan',
      title: title,
      artist: description,
      duration: duration,
    );
  }

  ja.AudioSource _assetAudioSource(
    String assetPath,
    MediaItem mediaItem,
  ) {
    final normalized =
        assetPath.startsWith('assets/') ? assetPath : 'assets/$assetPath';
    return ja.AudioSource.asset(normalized, tag: mediaItem);
  }

  Future<void> _prepareBackgroundAudio({
    required ja.AudioSource source,
    required BackgroundPlaybackKind kind,
    required bool loop,
    required double volume,
  }) async {
    final player = _backgroundAudioPlayer;
    if (player == null) return;

    audioMutationInProgress = true;
    audioCompletionHandled = false;
    try {
      await player.stop();
      playbackKind = kind;
      await player.setLoopMode(loop ? ja.LoopMode.one : ja.LoopMode.off);
      await player.setVolume(volume);
      await player.setAudioSource(source);
    } finally {
      audioMutationInProgress = false;
    }
  }

  void _playPreparedBackgroundAudio() {
    final player = _backgroundAudioPlayer;
    if (player == null) return;
    unawaited(player.play());
  }

  Future<void> _stopBackgroundAudio() async {
    final player = _backgroundAudioPlayer;
    audioMutationInProgress = true;
    try {
      playbackKind = BackgroundPlaybackKind.none;
      if (player != null) {
        await player.stop();
        await player.setLoopMode(ja.LoopMode.off);
        await player.setVolume(1);
      }
    } finally {
      audioMutationInProgress = false;
      backgroundAudioPlaying = false;
    }
  }

  Future<void> _handleBackgroundCompletion(
      BackgroundPlaybackKind completedKind) async {
    if (completedKind == BackgroundPlaybackKind.satsang) {
      final completedTask = activeTrackTask;
      if (mounted) {
        setState(() {
          activeTrackId = null;
          activeTrackTask = null;
          audioPosition = Duration.zero;
          backgroundAudioPlaying = false;
        });
      }
      if (completedTask != null) await _markTask(completedTask);
      await _stopBackgroundAudio();
    }
  }

  Future<void> _handleBackgroundStop(BackgroundPlaybackKind stoppedKind) async {
    if (audioMutationInProgress || playbackKind != stoppedKind) return;

    playbackKind = BackgroundPlaybackKind.none;
    if (stoppedKind == BackgroundPlaybackKind.meditation) {
      _pauseMeditationClock();
    }
    if (!mounted) return;
    setState(() {
      backgroundAudioPlaying = false;
      if (stoppedKind == BackgroundPlaybackKind.satsang) {
        activeTrackId = null;
        activeTrackTask = null;
        audioPosition = Duration.zero;
      }
      if (stoppedKind == BackgroundPlaybackKind.mantra) {
        mantraLoopEnabled = false;
        mantraLoopPlaying = false;
      }
    });
  }

  void _pauseMeditationClock() {
    if (!meditationRunning) return;
    _syncMeditationTimerWithClock();
    if (!meditationRunning) return;
    meditationTimer?.cancel();
    if (mounted) {
      setState(() {
        meditationRunning = false;
        meditationEndsAt = null;
      });
    }
  }

  Future<void> _resetToday() async {
    meditationRunToken++;
    if (playbackKind == BackgroundPlaybackKind.meditation ||
        playbackKind == BackgroundPlaybackKind.closingChant) {
      await _stopBackgroundAudio();
    }
    setState(() {
      records.remove(todayKey);
      meditationComplete = false;
      meditationRunning = false;
      meditationSessionStarted = false;
      meditationChantPhase = null;
      meditationEndsAt = null;
      meditationUsesMantra = false;
      mantraLoopEnabled = false;
      mantraLoopPlaying = false;
      remainingSeconds = selectedDurationSeconds;
    });
    meditationTimer?.cancel();
    await _saveRecords();
  }

  Future<void> _signOut() async {
    meditationRunToken++;
    meditationTimer?.cancel();
    meditationEndsAt = null;
    await _stopBackgroundAudio();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _playSatsang(SatsangTrack track) async {
    final task = _routineTaskForSatsangSession(track.session);
    final player = _backgroundAudioPlayer;

    try {
      if (activeTrackId == track.id) {
        if (player?.playing == true) {
          await player?.pause();
        } else {
          final confirmed =
              await _confirmPhoneSilent('your satsang can continue peacefully');
          if (!confirmed) return;
          _playPreparedBackgroundAudio();
        }
        setState(() {});
        return;
      }

      final confirmed =
          await _confirmPhoneSilent('your satsang can continue peacefully');
      if (!confirmed) return;

      _pauseMeditationClock();
      await _stopBackgroundAudio();
      if (!mounted) return;
      audioPosition = Duration.zero;
      audioDuration = Duration.zero;

      final mediaItem = _backgroundMediaItem(
        id: 'satsang:${track.id}',
        title: track.title,
        description: track.session == SatsangSession.aarti
            ? appText(context, 'Aarti', 'आरती')
            : appText(context, 'Satsang', 'सत्संग'),
      );

      late final ja.AudioSource source;
      if (track.audioUrl != null && track.audioUrl!.isNotEmpty) {
        source = ja.AudioSource.uri(
          Uri.parse(track.audioUrl!),
          tag: mediaItem,
        );
      } else if (track.assetPath != null && track.assetPath!.isNotEmpty) {
        source = _assetAudioSource(track.assetPath!, mediaItem);
      } else {
        source = _assetAudioSource(
          'audio/morning_satsang_astuti_rishikesh.mp3',
          mediaItem,
        );
      }

      await _prepareBackgroundAudio(
        source: source,
        kind: BackgroundPlaybackKind.satsang,
        loop: false,
        volume: 1,
      );

      setState(() {
        activeTrackId = track.id;
        activeTrackTask = task;
        mantraLoopEnabled = false;
        mantraLoopPlaying = false;
        meditationUsesMantra = false;
      });
      _playPreparedBackgroundAudio();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appText(
            context,
            'This satsang audio could not be played.',
            'यह सत्संग ऑडियो चलाया नहीं जा सका।',
          )),
        ),
      );
    }
  }

  void _setMeditationPresetMinutes(int minutes) {
    _setMeditationDuration(
      Duration(minutes: minutes),
      custom: false,
    );
  }

  void _setMeditationDuration(Duration duration, {required bool custom}) {
    meditationRunToken++;
    meditationTimer?.cancel();
    if (playbackKind == BackgroundPlaybackKind.meditation ||
        playbackKind == BackgroundPlaybackKind.closingChant) {
      unawaited(_stopBackgroundAudio());
    }
    final safeSeconds = _minimumMeditationDuration(duration).inSeconds;
    setState(() {
      selectedDurationSeconds = safeSeconds;
      remainingSeconds = safeSeconds;
      customMeditationDurationSelected = custom;
      meditationRunning = false;
      meditationComplete = false;
      meditationSessionStarted = false;
      meditationChantPhase = null;
      meditationEndsAt = null;
      meditationUsesMantra = false;
      mantraLoopEnabled = false;
      mantraLoopPlaying = false;
    });
  }

  Future<void> _openCustomMeditationDuration() async {
    if (meditationRunning || meditationChantPhase != null) return;

    final picked = await showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomDurationSheet(
        initialDuration: Duration(seconds: selectedDurationSeconds),
      ),
    );

    if (picked == null) return;
    _setMeditationDuration(picked, custom: true);
  }

  void _toggleMeditation() {
    if (meditationChantPhase != null) return;

    if (meditationRunning) {
      unawaited(_pauseMeditationSession());
      return;
    }

    unawaited(_beginMeditationSession());
  }

  Future<void> _pauseMeditationSession() async {
    _pauseMeditationClock();
    if (playbackKind == BackgroundPlaybackKind.meditation) {
      await _backgroundAudioPlayer?.pause();
    }
  }

  Future<void> _beginMeditationSession() async {
    final confirmed =
        await _confirmPhoneSilent('your meditation can stay undisturbed');
    if (!confirmed) return;

    if (remainingSeconds <= 0) {
      setState(() {
        remainingSeconds = selectedDurationSeconds;
        meditationComplete = false;
      });
    }

    final token = ++meditationRunToken;
    await _prepareMeditationBackgroundAudio(
      withMantra: mantraLoopEnabled,
    );
    if (!mounted || token != meditationRunToken) return;
    setState(() {
      meditationSessionStarted = true;
      meditationUsesMantra = mantraLoopEnabled;
      activeTrackId = null;
      activeTrackTask = null;
      audioPosition = Duration.zero;
    });
    _startMeditationTimer(token);
    _playPreparedBackgroundAudio();
  }

  Future<void> _prepareMeditationBackgroundAudio({
    required bool withMantra,
  }) async {
    final duration = Duration(seconds: remainingSeconds);
    final durationLabel = _formatDurationLabel(context, duration);
    final mediaItem = _backgroundMediaItem(
      id: 'meditation',
      title: withMantra
          ? appText(context, 'Meditation with Om', 'ॐ के साथ ध्यान')
          : appText(context, 'Meditation', 'ध्यान'),
      description: appText(
        context,
        '$durationLabel session',
        '$durationLabel का सत्र',
      ),
      duration: duration,
    );

    await _prepareBackgroundAudio(
      source: _assetAudioSource(
        withMantra
            ? 'audio/om_mantra_417hz_loop.mp3'
            : 'audio/meditation_chant.mp3',
        mediaItem,
      ),
      kind: BackgroundPlaybackKind.meditation,
      loop: true,
      volume: withMantra ? 1 : 0,
    );
  }

  void _startMeditationTimer(int token) {
    meditationTimer?.cancel();
    meditationEndsAt = DateTime.now().add(Duration(seconds: remainingSeconds));
    meditationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (token != meditationRunToken) {
        timer.cancel();
        return;
      }

      _syncMeditationTimerWithClock(token: token);
    });

    setState(() => meditationRunning = true);
  }

  void _syncMeditationTimerWithClock({int? token}) {
    if (!mounted ||
        !meditationRunning ||
        meditationChantPhase != null ||
        meditationEndsAt == null) {
      return;
    }
    if (token != null && token != meditationRunToken) return;

    final millisecondsLeft =
        meditationEndsAt!.difference(DateTime.now()).inMilliseconds;
    final nextRemaining = max(0, (millisecondsLeft / 1000).ceil());

    if (nextRemaining <= 0) {
      final activeToken = token ?? meditationRunToken;
      meditationTimer?.cancel();
      setState(() {
        remainingSeconds = 0;
        meditationRunning = false;
        meditationEndsAt = null;
      });
      unawaited(_finishMeditationSession(activeToken));
      return;
    }

    if (nextRemaining != remainingSeconds) {
      setState(() => remainingSeconds = nextRemaining);
    }
  }

  Future<void> _finishMeditationSession(int token) async {
    if (!mounted || token != meditationRunToken) return;

    final completionChimeError = appText(
      context,
      'Completion chime could not be played. Meditation is marked complete.',
      'समापन चाइम नहीं चल सका। ध्यान पूर्ण मान लिया गया है।',
    );

    await _stopBackgroundAudio();

    if (!mounted || token != meditationRunToken) return;

    setState(() {
      meditationChantPhase = MeditationChantPhase.closing;
      meditationRunning = false;
      meditationEndsAt = null;
      meditationUsesMantra = false;
      mantraLoopEnabled = false;
      mantraLoopPlaying = false;
    });

    try {
      await _playMeditationChant();
    } catch (_) {
      _showMeditationAudioError(completionChimeError);
    }

    if (!mounted || token != meditationRunToken) return;

    await _markTask(RoutineTask.meditation);

    if (!mounted || token != meditationRunToken) return;

    setState(() {
      meditationChantPhase = null;
      meditationComplete = true;
      meditationSessionStarted = false;
      meditationEndsAt = null;
    });
  }

  Future<void> _playMeditationChant() async {
    final player = _backgroundAudioPlayer;
    if (player == null) return;

    final mediaItem = _backgroundMediaItem(
      id: 'meditation-closing-chant',
      title: appText(context, 'Meditation complete', 'ध्यान पूर्ण'),
      description: appText(context, 'Closing chant', 'समापन मंत्र'),
    );
    await _prepareBackgroundAudio(
      source: _assetAudioSource('audio/meditation_chant.mp3', mediaItem),
      kind: BackgroundPlaybackKind.closingChant,
      loop: false,
      volume: 1,
    );

    final completed = Completer<void>();
    void finish() {
      if (!completed.isCompleted) completed.complete();
    }

    final stateSub = player.playerStateStream.listen((state) {
      if (state.processingState == ja.ProcessingState.completed ||
          state.processingState == ja.ProcessingState.idle) {
        finish();
      }
    });

    try {
      _playPreparedBackgroundAudio();
      await completed.future.timeout(const Duration(minutes: 5));
    } finally {
      await stateSub.cancel();
      await _stopBackgroundAudio();
    }
  }

  Future<void> _setMantraLoopEnabled(bool enabled) async {
    if (enabled) {
      await _playMantraLoop();
    } else {
      await _stopMantraLoop();
    }
  }

  Future<void> _playMantraLoop() async {
    if (meditationChantPhase != null) return;

    final confirmed = await _confirmPhoneSilent(
        'the Om mantra can play without interruption');
    if (!confirmed) return;
    if (!mounted) return;

    try {
      if (meditationSessionStarted && remainingSeconds > 0) {
        final shouldKeepPlaying = meditationRunning;
        await _prepareMeditationBackgroundAudio(withMantra: true);

        if (!mounted) return;
        setState(() {
          mantraLoopEnabled = true;
          mantraLoopPlaying = shouldKeepPlaying;
          meditationUsesMantra = true;
        });
        if (shouldKeepPlaying) _playPreparedBackgroundAudio();
        return;
      }

      final mediaItem = _backgroundMediaItem(
        id: 'om-mantra-417hz',
        title: appText(context, 'Om Mantra', 'ॐ मंत्र'),
        description: appText(
          context,
          '417Hz meditation ambience',
          '417Hz ध्यान ध्वनि',
        ),
      );
      await _prepareBackgroundAudio(
        source: _assetAudioSource(
          'audio/om_mantra_417hz_loop.mp3',
          mediaItem,
        ),
        kind: BackgroundPlaybackKind.mantra,
        loop: true,
        volume: 1,
      );

      if (!mounted) return;
      setState(() {
        mantraLoopEnabled = true;
        mantraLoopPlaying = true;
        meditationUsesMantra = false;
        activeTrackId = null;
        activeTrackTask = null;
        audioPosition = Duration.zero;
      });
      _playPreparedBackgroundAudio();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        mantraLoopEnabled = false;
        mantraLoopPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appText(
            context,
            'Om mantra audio could not be played.',
            'ॐ मंत्र ऑडियो चलाया नहीं जा सका।',
          )),
        ),
      );
    }
  }

  Future<void> _stopMantraLoop() async {
    if (meditationSessionStarted &&
        remainingSeconds > 0 &&
        meditationChantPhase == null) {
      final shouldKeepPlaying = meditationRunning;
      await _prepareMeditationBackgroundAudio(withMantra: false);
      if (!mounted) return;
      setState(() {
        mantraLoopEnabled = false;
        mantraLoopPlaying = false;
        meditationUsesMantra = false;
      });
      if (shouldKeepPlaying) _playPreparedBackgroundAudio();
      return;
    }

    if (playbackKind == BackgroundPlaybackKind.mantra) {
      await _stopBackgroundAudio();
    }
    if (!mounted) return;
    setState(() {
      mantraLoopEnabled = false;
      mantraLoopPlaying = false;
      meditationUsesMantra = false;
    });
  }

  Future<bool> _confirmPhoneSilent(String reason) async {
    if (!mounted) return false;
    if (silentPromptOpen) return false;

    silentPromptOpen = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SilentPhoneDialog(reason: reason),
      );
      return confirmed == true;
    } finally {
      silentPromptOpen = false;
    }
  }

  void _resetMeditation() {
    meditationRunToken++;
    meditationTimer?.cancel();
    if (playbackKind == BackgroundPlaybackKind.meditation ||
        playbackKind == BackgroundPlaybackKind.closingChant) {
      unawaited(_stopBackgroundAudio());
    }
    setState(() {
      meditationRunning = false;
      meditationComplete = false;
      meditationSessionStarted = false;
      meditationChantPhase = null;
      meditationEndsAt = null;
      meditationUsesMantra = false;
      if (playbackKind != BackgroundPlaybackKind.mantra) {
        mantraLoopEnabled = false;
        mantraLoopPlaying = false;
      }
      remainingSeconds = selectedDurationSeconds;
    });
  }

  void _showMeditationAudioError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!localStateLoaded || needsProfileName) {
      return Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _SacredBackground()),
            SafeArea(
              child: !localStateLoaded
                  ? const _ProfileLoadingScreen()
                  : _NameOnboardingScreen(onContinue: _saveProfile),
            ),
          ],
        ),
      );
    }

    final screens = {
      PracticeTab.home: _HomeScreen(
        name: devoteeProfile?.displayName ?? appText(context, 'Bhakt', 'भक्त'),
        today: today,
        stats: stats,
        onOpenSatsang: (session) {
          setState(() {
            selectedSession = session;
            tab = PracticeTab.satsang;
          });
        },
        onOpenMeditation: () => setState(() => tab = PracticeTab.meditate),
        onResetToday: _resetToday,
        quotesStream: content.quotes(),
      ),
      PracticeTab.satsang: _SatsangScreen(
        tracksStream: content.satsangs(),
        selectedSession: selectedSession,
        activeTrackId: activeTrackId,
        audioPosition: audioPosition,
        audioDuration: audioDuration,
        isPlaying: playbackKind == BackgroundPlaybackKind.satsang &&
            backgroundAudioPlaying,
        today: today,
        onSessionChanged: (session) async {
          if (playbackKind == BackgroundPlaybackKind.satsang) {
            await _stopBackgroundAudio();
          }
          setState(() {
            selectedSession = session;
            activeTrackId = null;
            activeTrackTask = null;
          });
        },
        onPlay: _playSatsang,
        onMark: _markTask,
      ),
      PracticeTab.meditate: _MeditationScreen(
        selectedDurationSeconds: selectedDurationSeconds,
        remainingSeconds: remainingSeconds,
        meditationRunning: meditationRunning,
        meditationComplete: meditationComplete,
        meditationChantPhase: meditationChantPhase,
        mantraLoopEnabled: mantraLoopEnabled,
        mantraLoopPlaying: mantraLoopPlaying,
        customDurationSelected: customMeditationDurationSelected,
        todayDone: today[RoutineTask.meditation.name] == true,
        onPresetMinutesChanged: _setMeditationPresetMinutes,
        onCustomDuration: _openCustomMeditationDuration,
        onMantraLoopChanged: _setMantraLoopEnabled,
        onToggle: _toggleMeditation,
        onReset: _resetMeditation,
      ),
      PracticeTab.wisdom: _WisdomScreen(quotesStream: content.quotes()),
      PracticeTab.more: _MoreScreen(
        user: widget.user,
        onSignOut: _signOut,
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _SacredBackground()),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(tab),
                child: screens[tab]!,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _NavBar(
        selected: tab,
        onSelected: (value) => setState(() => tab = value),
      ),
    );
  }

  static SatsangSession _defaultSession() {
    final hour = DateTime.now().hour;
    return hour >= 3 && hour < 12
        ? SatsangSession.morning
        : SatsangSession.evening;
  }
}

class _ProfileLoadingScreen extends StatelessWidget {
  const _ProfileLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 58,
        height: 58,
        child: CircularProgressIndicator(
          strokeWidth: 5,
          color: AppColors.maroon,
          backgroundColor: AppColors.rose,
        ),
      ),
    );
  }
}

class _NameOnboardingScreen extends StatefulWidget {
  const _NameOnboardingScreen({required this.onContinue});

  final ValueChanged<DevoteeProfile> onContinue;

  @override
  State<_NameOnboardingScreen> createState() => _NameOnboardingScreenState();
}

class _NameOnboardingScreenState extends State<_NameOnboardingScreen> {
  final firstName = TextEditingController();
  final middleName = TextEditingController();
  final lastName = TextEditingController();
  String? error;

  @override
  void dispose() {
    firstName.dispose();
    middleName.dispose();
    lastName.dispose();
    super.dispose();
  }

  void _continue() {
    final profile = DevoteeProfile.fromParts(
      firstName: firstName.text,
      middleName: middleName.text,
      lastName: lastName.text,
    );
    if (profile == null) {
      setState(() => error = appText(
            context,
            'Please enter your first name.',
            'कृपया अपना पहला नाम दर्ज करें।',
          ));
      return;
    }
    widget.onContinue(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            decoration: _cardDecoration(color: AppColors.offWhite).copyWith(
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepCrimson.withValues(alpha: 0.11),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 118,
                    height: 118,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Image.asset('assets/images/app_icon.png',
                        fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  appText(
                    context,
                    'Welcome to Guruvandan',
                    'गुरुवंदन में आपका स्वागत है',
                  ),
                  textAlign: TextAlign.center,
                  style: _headingStyle(
                    LanguageScope.of(context).language,
                    color: AppColors.ink,
                    fontSize: 31,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  appText(
                    context,
                    'Please enter your name to begin your daily spiritual routine.',
                    'अपनी दैनिक आध्यात्मिक दिनचर्या शुरू करने के लिए अपना नाम दर्ज करें।',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: firstName,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (error != null) setState(() => error = null);
                  },
                  decoration: _inputDecoration(
                    appText(context, 'First name', 'पहला नाम'),
                  ).copyWith(
                    errorText: error,
                    prefixIcon: const Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: middleName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    appText(context, 'Middle name', 'मध्य नाम'),
                  ).copyWith(
                    prefixIcon: const Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _continue(),
                  decoration: _inputDecoration(
                    appText(context, 'Last name', 'अंतिम नाम'),
                  ).copyWith(
                    prefixIcon: const Icon(Icons.family_restroom_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(appText(context, 'Begin', 'शुरू करें')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: AppColors.maroon,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuruWelcomeDialog extends StatelessWidget {
  const _GuruWelcomeDialog({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.of(context).language;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: Colors.transparent,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderStrong),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepCrimson.withValues(alpha: 0.28),
                      blurRadius: 38,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.maroon, AppColors.crimson],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.offWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.softGold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.deepCrimson
                                      .withValues(alpha: 0.32),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/guru_image.jpeg',
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Guruvandan',
                            textAlign: TextAlign.center,
                            style: _headingStyle(
                              language,
                              color: AppColors.offWhite,
                              fontSize: 24,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                      child: Column(
                        children: [
                          Text(
                            appText(
                              context,
                              'Jai Guru, $name!',
                              'जय गुरु, $name!',
                            ),
                            textAlign: TextAlign.center,
                            style: _bodyStyle(
                              language,
                              color: AppColors.maroon,
                              fontSize: 23,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.softGold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.format_quote_rounded,
                                  color: AppColors.rose, size: 30),
                              const SizedBox(width: 10),
                              Container(
                                width: 34,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.softGold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            appText(
                              context,
                              'With the sacred blessings of Sadguru Maharaj, we warmly welcome you to this spiritual journey.',
                              'सद्गुरु महाराज के पावन आशीर्वाद से, हम आपका इस आध्यात्मिक यात्रा में हार्दिक स्वागत करते हैं।',
                            ),
                            textAlign: TextAlign.center,
                            style: _bodyStyle(
                              language,
                              color: AppColors.taupe,
                              fontSize: 18,
                              height: 1.42,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(170, 56),
                              backgroundColor: AppColors.maroon,
                              foregroundColor: AppColors.offWhite,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 26),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 8,
                              shadowColor:
                                  AppColors.maroon.withValues(alpha: 0.24),
                              textStyle: _bodyStyle(
                                language,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                            child: Text(
                              appText(context, 'Enter', 'प्रवेश करें'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _GuruWelcomeDialogLegacy extends StatelessWidget {
  const _GuruWelcomeDialogLegacy({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: Colors.transparent,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderStrong),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepCrimson.withValues(alpha: 0.28),
                      blurRadius: 38,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.maroon, AppColors.crimson],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.offWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.softGold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.deepCrimson
                                      .withValues(alpha: 0.32),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/guru_image.jpeg',
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Guru Vandan',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              color: AppColors.offWhite,
                              fontSize: 24,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                      child: Column(
                        children: [
                          Text(
                            'जय गुरु, $name!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.maroon,
                              fontSize: 23,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.softGold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.format_quote_rounded,
                                  color: AppColors.rose, size: 30),
                              const SizedBox(width: 10),
                              Container(
                                width: 34,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.softGold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'सद्गुरु महाराज के\n'
                            'पावन आशीर्वाद से, हम\n'
                            'आपका इस आध्यात्मिक\n'
                            'यात्रा में हार्दिक स्वागत\n'
                            'करते हैं।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.taupe,
                              fontSize: 18,
                              height: 1.42,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(170, 56),
                              backgroundColor: AppColors.maroon,
                              foregroundColor: AppColors.offWhite,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 26),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 8,
                              shadowColor:
                                  AppColors.maroon.withValues(alpha: 0.24),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                            child: const Text(
                              'प्रवेश करें —\nEnter',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SilentPhoneDialog extends StatelessWidget {
  const _SilentPhoneDialog({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.offWhite,
        surfaceTintColor: AppColors.offWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
        icon: Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.rose,
          ),
          child: const Icon(
            Icons.notifications_paused_rounded,
            color: AppColors.maroon,
            size: 31,
          ),
        ),
        title: Text(
          appText(
            context,
            'Put phone on silent',
            'फोन को साइलेंट करें',
          ),
          textAlign: TextAlign.center,
          style: _headingStyle(
            LanguageScope.of(context).language,
            color: AppColors.ink,
            fontSize: 25,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          appText(
            context,
            'Please put your phone on silent mode so $reason.',
            'कृपया फोन को साइलेंट मोड पर रखें ताकि साधना बिना व्यवधान के चल सके।',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppColors.maroon,
              foregroundColor: AppColors.offWhite,
            ),
            child: Text(appText(context, 'OK', 'ठीक है')),
          ),
        ],
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.name,
    required this.today,
    required this.stats,
    required this.onOpenSatsang,
    required this.onOpenMeditation,
    required this.onResetToday,
    required this.quotesStream,
  });

  final String name;
  final Map<String, bool> today;
  final RoutineStats stats;
  final ValueChanged<SatsangSession> onOpenSatsang;
  final VoidCallback onOpenMeditation;
  final VoidCallback onResetToday;
  final Stream<List<WisdomQuote>> quotesStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WisdomQuote>>(
      stream: quotesStream,
      initialData: fallbackQuotes,
      builder: (context, snapshot) {
        final quotes = snapshot.data ?? fallbackQuotes;
        final quote = localizedWisdomQuote(
            context, quotes[DateTime.now().day % quotes.length]);

        return _PageScaffold(
          children: [
            _HeroPanel(
              name: name,
              onMorningSatsang: () => onOpenSatsang(SatsangSession.morning),
              onMeditation: onOpenMeditation,
              onEveningSatsang: () => onOpenSatsang(SatsangSession.evening),
            ),
            _MeditationStreakPanel(
              stats: stats,
              todayDone: today[RoutineTask.meditation.name] == true,
            ),
            _SectionHeader(
              title: appText(
                context,
                'Today\'s Routine',
                'आज की दिनचर्या',
              ),
              action: IconButton.filledTonal(
                onPressed: onResetToday,
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: appText(context, 'Reset today', 'आज रीसेट करें'),
              ),
            ),
            _RoutineTile(
              title: appText(context, 'Morning satsang', 'प्रातः सत्संग'),
              subtitle: appText(
                context,
                'Start the day with remembrance',
                'स्मरण के साथ दिन की शुरुआत करें',
              ),
              done: today[RoutineTask.morningSatsang.name] == true,
              icon: Icons.wb_sunny_rounded,
              onTap: () => onOpenSatsang(SatsangSession.morning),
            ),
            _RoutineTile(
              title: appText(context, 'Meditation', 'ध्यान'),
              subtitle: appText(
                context,
                'Sit quietly with the timer',
                'टाइमर के साथ शांत बैठें',
              ),
              done: today[RoutineTask.meditation.name] == true,
              icon: Icons.self_improvement_rounded,
              onTap: onOpenMeditation,
            ),
            _RoutineTile(
              title: appText(context, 'Evening satsang', 'शाम सत्संग'),
              subtitle: appText(
                context,
                'Close the day in satsang',
                'दिन का समापन सत्संग से करें',
              ),
              done: today[RoutineTask.eveningSatsang.name] == true,
              icon: Icons.nights_stay_rounded,
              onTap: () => onOpenSatsang(SatsangSession.evening),
            ),
            _WisdomFeature(quote: quote),
            const _AboutHomeSection(),
          ],
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.name,
    required this.onMorningSatsang,
    required this.onMeditation,
    required this.onEveningSatsang,
  });

  final String name;
  final VoidCallback onMorningSatsang;
  final VoidCallback onMeditation;
  final VoidCallback onEveningSatsang;

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.of(context).language;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? appText(context, 'Jai Guru, $name', 'जय गुरु, $name')
        : hour < 18
            ? appText(context, 'Peaceful afternoon, $name', 'शुभ दोपहर, $name')
            : appText(
                context, 'Blessed evening, $name', 'मंगलमय संध्या, $name');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Container(
          height: compact ? 420 : 372,
          clipBehavior: Clip.antiAlias,
          decoration: _cardDecoration(
            color: AppColors.deepCrimson,
            borderColor: AppColors.maroon.withValues(alpha: 0.28),
          ).copyWith(
            boxShadow: [
              BoxShadow(
                color: AppColors.maroon.withValues(alpha: 0.22),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _DawnTemplePainter()),
              Positioned(
                right: compact ? 18 : 26,
                top: compact ? 18 : 24,
                child: _GuruPortrait(size: compact ? 92 : 118),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, compact ? 126 : 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.softGold.withValues(alpha: 0.58)),
                      ),
                      child: Text(
                        'Guruvandan',
                        style: GoogleFonts.inter(
                          color: AppColors.softGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      greeting,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _headingStyle(
                        language,
                        color: AppColors.surface,
                        fontSize: compact ? 29 : 34,
                        fontWeight: FontWeight.w900,
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appText(
                        context,
                        'A gentle daily path for satsang, dhyan, wisdom, and seva of routine.',
                        'सत्संग, ध्यान, ज्ञान और दैनिक साधना का सरल मार्ग।',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyStyle(
                        language,
                        color: const Color(0xFFFFF1E2),
                        fontSize: 17,
                        height: 1.38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeroChip(
                          icon: Icons.wb_sunny_rounded,
                          label: appText(
                              context, 'Morning satsang', 'प्रातः सत्संग'),
                          onTap: onMorningSatsang,
                        ),
                        _HeroChip(
                          icon: Icons.self_improvement_rounded,
                          label: appText(context, 'Dhyan', 'ध्यान'),
                          onTap: onMeditation,
                        ),
                        _HeroChip(
                          icon: Icons.nights_stay_rounded,
                          label:
                              appText(context, 'Evening satsang', 'शाम सत्संग'),
                          onTap: onEveningSatsang,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuruPortrait extends StatelessWidget {
  const _GuruPortrait({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.softGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepCrimson.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.asset('assets/images/guru_image.jpeg',
            fit: BoxFit.cover, alignment: Alignment.topCenter),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.offWhite.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.offWhite.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AppColors.softGold),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.offWhite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DawnTemplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6E171A),
          Color(0xFF9D2B27),
          Color(0xFFD9814E),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    final glow = Paint()
      ..color = AppColors.softGold.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(
        Offset(size.width * 0.72, size.height * 0.2), size.width * 0.26, glow);

    final river = Path()
      ..moveTo(0, size.height * 0.76)
      ..cubicTo(size.width * 0.22, size.height * 0.7, size.width * 0.42,
          size.height * 0.86, size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(river,
        Paint()..color = const Color(0xFF582B34).withValues(alpha: 0.42));

    final pathPaint = Paint()
      ..color = AppColors.offWhite.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.02, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.74,
          size.width * 0.98, size.height * 0.82);
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant _DawnTemplePainter oldDelegate) => false;
}

class _MeditationStreakPanel extends StatelessWidget {
  const _MeditationStreakPanel({
    required this.stats,
    required this.todayDone,
  });

  final RoutineStats stats;
  final bool todayDone;

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.of(context).language;
    final yesterdayDone = todayDone ? stats.current > 1 : stats.current > 0;
    final milestoneDays = stats.daysToMilestone;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(color: AppColors.offWhite),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.rose,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.self_improvement_rounded,
                  color: AppColors.maroon,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appText(
                        context,
                        'Meditation streak',
                        'ध्यान की स्ट्रीक',
                      ),
                      style: _headingStyle(
                        language,
                        color: AppColors.ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appText(
                        context,
                        'Meditate once each day to keep it going.',
                        'इसे जारी रखने के लिए हर दिन एक बार ध्यान करें।',
                      ),
                      style: _bodyStyle(
                        language,
                        color: AppColors.taupe,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StreakContinuity(
            yesterdayDone: yesterdayDone,
            todayDone: todayDone,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_off_outlined,
                color: AppColors.copper,
                size: 20,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  appText(
                    context,
                    'Any meditation duration counts.',
                    'ध्यान की कोई भी अवधि मान्य है।',
                  ),
                  textAlign: TextAlign.center,
                  style: _bodyStyle(
                    language,
                    color: AppColors.copper,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: AppColors.border),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StreakMetric(
                    valueKey: const Key('meditation-streak-current'),
                    value: stats.current,
                    label: appText(
                      context,
                      'Current streak',
                      'वर्तमान स्ट्रीक',
                    ),
                    color: AppColors.maroon,
                  ),
                ),
                const VerticalDivider(color: AppColors.border),
                Expanded(
                  child: _StreakMetric(
                    valueKey: const Key('meditation-streak-best'),
                    value: stats.best,
                    label: appText(context, 'Best streak', 'सर्वश्रेष्ठ'),
                    color: AppColors.sage,
                  ),
                ),
                const VerticalDivider(color: AppColors.border),
                Expanded(
                  child: _StreakMetric(
                    valueKey: const Key('meditation-streak-total'),
                    value: stats.total,
                    label: appText(
                      context,
                      'Meditation days',
                      'ध्यान के दिन',
                    ),
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4ED),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.flag_rounded,
                  color: AppColors.sage,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appText(
                      context,
                      '$milestoneDays more ${milestoneDays == 1 ? 'day' : 'days'} to the next milestone',
                      'अगले पड़ाव तक $milestoneDays दिन और',
                    ),
                    style: _bodyStyle(
                      language,
                      color: AppColors.sage,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakContinuity extends StatelessWidget {
  const _StreakContinuity({
    required this.yesterdayDone,
    required this.todayDone,
  });

  final bool yesterdayDone;
  final bool todayDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StreakDayStep(
            label: appText(context, 'Yesterday', 'बीता दिन'),
            status: yesterdayDone
                ? appText(context, 'Meditated', 'ध्यान किया')
                : appText(context, 'No entry', 'दर्ज नहीं'),
            icon: yesterdayDone ? Icons.check_rounded : Icons.remove_rounded,
            active: yesterdayDone,
          ),
        ),
        _StreakConnector(active: yesterdayDone),
        Expanded(
          child: _StreakDayStep(
            label: appText(context, 'Today', 'आज'),
            status: todayDone
                ? appText(context, 'Complete', 'पूर्ण')
                : appText(context, 'Meditate', 'ध्यान करें'),
            icon: todayDone
                ? Icons.check_rounded
                : Icons.self_improvement_rounded,
            active: todayDone,
            highlighted: true,
          ),
        ),
        _StreakConnector(active: todayDone),
        Expanded(
          child: _StreakDayStep(
            label: appText(context, 'Tomorrow', 'अगला दिन'),
            status: appText(context, 'Continue', 'जारी रखें'),
            icon: Icons.arrow_forward_rounded,
            active: false,
          ),
        ),
      ],
    );
  }
}

class _StreakConnector extends StatelessWidget {
  const _StreakConnector({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 3,
      margin: const EdgeInsets.only(top: 20),
      color: active ? AppColors.gold : AppColors.border,
    );
  }
}

class _StreakDayStep extends StatelessWidget {
  const _StreakDayStep({
    required this.label,
    required this.status,
    required this.icon,
    required this.active,
    this.highlighted = false,
  });

  final String label;
  final String status;
  final IconData icon;
  final bool active;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.of(context).language;
    final color = active || highlighted ? AppColors.maroon : AppColors.muted;

    return Column(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: active
                ? AppColors.maroon
                : highlighted
                    ? AppColors.rose
                    : AppColors.parchment,
            shape: BoxShape.circle,
            border: highlighted && !active
                ? Border.all(color: AppColors.maroon, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            color: active ? AppColors.offWhite : color,
            size: 23,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: _bodyStyle(
            language,
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          status,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: _bodyStyle(
            language,
            color: color,
            fontSize: 12,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({
    required this.valueKey,
    required this.value,
    required this.label,
    required this.color,
  });

  final Key valueKey;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.of(context).language;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Text(
            value.toString(),
            key: valueKey,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: _bodyStyle(
              language,
              color: AppColors.taupe,
              fontSize: 12,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SatsangScreen extends StatelessWidget {
  const _SatsangScreen({
    required this.tracksStream,
    required this.selectedSession,
    required this.activeTrackId,
    required this.audioPosition,
    required this.audioDuration,
    required this.isPlaying,
    required this.today,
    required this.onSessionChanged,
    required this.onPlay,
    required this.onMark,
  });

  final Stream<List<SatsangTrack>> tracksStream;
  final SatsangSession selectedSession;
  final String? activeTrackId;
  final Duration audioPosition;
  final Duration audioDuration;
  final bool isPlaying;
  final Map<String, bool> today;
  final ValueChanged<SatsangSession> onSessionChanged;
  final ValueChanged<SatsangTrack> onPlay;
  final ValueChanged<RoutineTask> onMark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SatsangTrack>>(
      stream: tracksStream,
      initialData: fallbackSatsangs,
      builder: (context, snapshot) {
        final tracks = (snapshot.data ?? fallbackSatsangs)
            .where((track) => track.session == selectedSession)
            .toList();
        final visibleTracks = tracks.isEmpty
            ? fallbackSatsangs
                .where((track) => track.session == selectedSession)
                .toList()
            : tracks;

        return _PageScaffold(
          children: [
            _ScreenTitle(
              icon: Icons.headphones_rounded,
              title: appText(context, 'Satsang', 'सत्संग'),
              subtitle: appText(
                context,
                'Morning, evening, and aarti audio for steady daily devotion.',
                'नियमित भक्ति के लिए प्रातः, शाम और आरती का ऑडियो।',
              ),
            ),
            _SessionSwitch(
                selected: selectedSession, onChanged: onSessionChanged),
            ...visibleTracks.map((track) {
              final displayTrack = localizedSatsangTrack(context, track);
              final task = _routineTaskForSatsangSession(track.session);
              final done = task != null && today[task.name] == true;
              final active = activeTrackId == track.id;
              final progress = active && audioDuration.inMilliseconds > 0
                  ? audioPosition.inMilliseconds / audioDuration.inMilliseconds
                  : 0.0;

              return _AudioCard(
                track: displayTrack,
                done: done,
                active: active,
                playing: active && isPlaying,
                progress: progress.clamp(0, 1),
                position: active ? _formatDuration(audioPosition) : '00:00',
                duration: active && audioDuration.inSeconds > 0
                    ? _formatDuration(audioDuration)
                    : track.durationLabel,
                onPlay: () => onPlay(track),
                onMark: task == null ? null : () => onMark(task),
              );
            }),
          ],
        );
      },
    );
  }
}

class _SessionSwitch extends StatelessWidget {
  const _SessionSwitch({required this.selected, required this.onChanged});

  final SatsangSession selected;
  final ValueChanged<SatsangSession> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        children: SatsangSession.values.map((session) {
          final active = selected == session;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: () => onChanged(session),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.maroon : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _satsangSessionIcon(session),
                      size: 22,
                      color: active ? AppColors.cream : AppColors.maroon,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _satsangSessionLabel(context, session),
                      style: TextStyle(
                        color: active ? AppColors.cream : AppColors.maroon,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AudioCard extends StatelessWidget {
  const _AudioCard({
    required this.track,
    required this.done,
    required this.active,
    required this.playing,
    required this.progress,
    required this.position,
    required this.duration,
    required this.onPlay,
    this.onMark,
  });

  final SatsangTrack track;
  final bool done;
  final bool active;
  final bool playing;
  final double progress;
  final String position;
  final String duration;
  final VoidCallback onPlay;
  final VoidCallback? onMark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(
        color: active ? const Color(0xFFFFFBF2) : AppColors.surface,
        borderColor: active ? AppColors.softGold : AppColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: active ? AppColors.maroon : AppColors.rose,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _satsangSessionIcon(track.session),
                  color: active ? AppColors.cream : AppColors.maroon,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _satsangSessionEyebrow(context, track.session),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(track.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(track.description,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 11,
              value: active ? progress : 0,
              color: AppColors.gold,
              backgroundColor: AppColors.rose,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$position / $duration',
                  style: const TextStyle(
                    color: AppColors.taupe,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPlay,
                  icon: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(playing
                      ? appText(context, 'Pause', 'रोकें')
                      : appText(context, 'Play', 'चलाएं')),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.maroon),
                ),
              ),
              if (onMark != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMark,
                    icon: Icon(done
                        ? Icons.verified_rounded
                        : Icons.check_circle_outline_rounded),
                    label: Text(done
                        ? appText(context, 'Completed', 'पूर्ण')
                        : appText(context, 'Complete', 'पूर्ण करें')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: done ? AppColors.sage : AppColors.maroon,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MeditationScreen extends StatelessWidget {
  const _MeditationScreen({
    required this.selectedDurationSeconds,
    required this.remainingSeconds,
    required this.meditationRunning,
    required this.meditationComplete,
    required this.meditationChantPhase,
    required this.mantraLoopEnabled,
    required this.mantraLoopPlaying,
    required this.customDurationSelected,
    required this.todayDone,
    required this.onPresetMinutesChanged,
    required this.onCustomDuration,
    required this.onMantraLoopChanged,
    required this.onToggle,
    required this.onReset,
  });

  final int selectedDurationSeconds;
  final int remainingSeconds;
  final bool meditationRunning;
  final bool meditationComplete;
  final MeditationChantPhase? meditationChantPhase;
  final bool mantraLoopEnabled;
  final bool mantraLoopPlaying;
  final bool customDurationSelected;
  final bool todayDone;
  final ValueChanged<int> onPresetMinutesChanged;
  final VoidCallback onCustomDuration;
  final ValueChanged<bool> onMantraLoopChanged;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final progress = selectedDurationSeconds == 0
        ? 0.0
        : 1 - remainingSeconds / selectedDurationSeconds;
    final chantPlaying = meditationChantPhase != null;
    final locked = meditationRunning || chantPlaying;
    final statusLabel = meditationChantPhase == MeditationChantPhase.closing
        ? appText(context, 'Completion chime', 'समापन चाइम')
        : meditationRunning
            ? appText(context, 'Meditating', 'ध्यान जारी')
            : meditationComplete
                ? appText(context, 'Complete', 'पूर्ण')
                : appText(context, 'Ready', 'तैयार');
    final actionLabel = meditationChantPhase == MeditationChantPhase.closing
        ? appText(context, 'Completion chime', 'समापन चाइम')
        : meditationRunning
            ? appText(context, 'Pause', 'रोकें')
            : appText(context, 'Start', 'शुरू करें');

    return _PageScaffold(
      children: [
        _ScreenTitle(
          icon: Icons.self_improvement_rounded,
          title: appText(context, 'Meditation', 'ध्यान'),
          subtitle: appText(
            context,
            'Set your duration. The chime plays only when the timer ends.',
            'अपना समय चुनें। चाइम केवल टाइमर समाप्त होने पर बजेगा।',
          ),
        ),
        Container(
          padding: const EdgeInsets.all(22),
          clipBehavior: Clip.antiAlias,
          decoration: _cardDecoration(color: AppColors.offWhite),
          child: Column(
            children: [
              SizedBox(
                height: 268,
                width: 268,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(268),
                      painter: _MeditationHaloPainter(
                          active: meditationRunning || chantPlaying),
                    ),
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress.clamp(0, 1),
                        strokeWidth: 14,
                        color: AppColors.gold,
                        backgroundColor: AppColors.rose,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Container(
                      width: 198,
                      height: 198,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF8EAD7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border:
                            Border.all(color: AppColors.softGold, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.maroon.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 158,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatSeconds(remainingSeconds),
                                maxLines: 1,
                                style: GoogleFonts.inter(
                                  color: AppColors.maroon,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              color: AppColors.taupe,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ...[5, 10, 15, 20, 25, 30].map((minutes) {
                    final active = !customDurationSelected &&
                        selectedDurationSeconds == minutes * 60;
                    return ChoiceChip(
                      label: Text(_formatMinutesLabel(context, minutes)),
                      selected: active,
                      onSelected: locked
                          ? null
                          : (_) => onPresetMinutesChanged(minutes),
                      selectedColor: AppColors.maroon,
                      backgroundColor: AppColors.rose,
                      labelStyle: TextStyle(
                        color: active ? AppColors.cream : AppColors.maroon,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    );
                  }),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: customDurationSelected
                          ? AppColors.cream
                          : AppColors.maroon,
                    ),
                    label: Text(customDurationSelected
                        ? _formatDurationLabel(
                            context, Duration(seconds: selectedDurationSeconds))
                        : appText(context, 'Custom time', 'अपना समय')),
                    selected: customDurationSelected,
                    onSelected: locked ? null : (_) => onCustomDuration(),
                    selectedColor: AppColors.maroon,
                    backgroundColor: AppColors.rose,
                    labelStyle: TextStyle(
                      color: customDurationSelected
                          ? AppColors.cream
                          : AppColors.maroon,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _MantraLoopSwitch(
                enabled: mantraLoopEnabled,
                playing: mantraLoopPlaying,
                locked: chantPlaying,
                onChanged: onMantraLoopChanged,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: chantPlaying ? null : onToggle,
                      icon: Icon(chantPlaying
                          ? Icons.music_note_rounded
                          : meditationRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                      label: Text(actionLabel),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        backgroundColor: meditationRunning
                            ? AppColors.crimson
                            : AppColors.maroon,
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onReset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(appText(context, 'Reset', 'रीसेट')),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              if (todayDone) ...[
                const SizedBox(height: 18),
                _CompletionBanner(
                  text: appText(
                    context,
                    'Meditation completed today',
                    'आज का ध्यान पूर्ण हुआ',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MantraLoopSwitch extends StatelessWidget {
  const _MantraLoopSwitch({
    required this.enabled,
    required this.playing,
    required this.locked,
    required this.onChanged,
  });

  final bool enabled;
  final bool playing;
  final bool locked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final status = enabled
        ? playing
            ? appText(context, 'Playing in loop', 'लूप में चल रहा है')
            : appText(context, 'Starting', 'शुरू हो रहा है')
        : appText(context, '417Hz mantra ambience', '417Hz मंत्र वातावरण');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration(
        color: const Color(0xFFFFF8EF),
        borderColor: enabled ? AppColors.softGold : AppColors.border,
      ).copyWith(
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: enabled ? 0.16 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.gold.withValues(alpha: 0.16)
                  : AppColors.rose,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled ? AppColors.softGold : AppColors.border,
              ),
            ),
            child: Icon(
              enabled ? Icons.spatial_audio_rounded : Icons.music_note_rounded,
              color: enabled ? AppColors.gold : AppColors.maroon,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appText(context, 'Om mantra', 'ॐ मंत्र'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        height: 1.28,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: enabled,
            onChanged: locked ? null : onChanged,
            activeThumbColor: AppColors.maroon,
            activeTrackColor: AppColors.softGold,
          ),
        ],
      ),
    );
  }
}

class _CustomDurationSheet extends StatefulWidget {
  const _CustomDurationSheet({required this.initialDuration});

  final Duration initialDuration;

  @override
  State<_CustomDurationSheet> createState() => _CustomDurationSheetState();
}

class _CustomDurationSheetState extends State<_CustomDurationSheet> {
  late Duration duration = _minimumMeditationDuration(widget.initialDuration);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(22, 18, 22, 18 + bottomPadding),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: AppColors.borderStrong),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepCrimson.withValues(alpha: 0.16),
                  blurRadius: 30,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _IconBadge(
                        icon: Icons.schedule_rounded,
                        background: AppColors.rose,
                        color: AppColors.maroon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appText(
                            context,
                            'Custom meditation time',
                            'अपना ध्यान समय',
                          ),
                          style: _headingStyle(
                            LanguageScope.of(context).language,
                            color: AppColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: appText(context, 'Close', 'बंद करें'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.self_improvement_rounded,
                            color: AppColors.maroon),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatDurationLabel(context, duration),
                            style: _bodyStyle(
                              LanguageScope.of(context).language,
                              color: AppColors.maroon,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 216,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: Brightness.light,
                        primaryColor: AppColors.maroon,
                        textTheme: CupertinoTextThemeData(
                          pickerTextStyle: GoogleFonts.inter(
                            color: AppColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hm,
                        minuteInterval: 1,
                        initialTimerDuration: duration,
                        onTimerDurationChanged: (value) {
                          setState(() =>
                              duration = _minimumMeditationDuration(value));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(appText(context, 'Cancel', 'रद्द करें')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(duration),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                              appText(context, 'Set time', 'समय सेट करें')),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.maroon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeditationHaloPainter extends CustomPainter {
  const _MeditationHaloPainter({required this.active});

  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final glow = Paint()
      ..color = (active ? AppColors.gold : AppColors.maroon)
          .withValues(alpha: active ? 0.12 : 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 4; i++) {
      final inset = 14.0 + i * 18;
      canvas.drawOval(
          Rect.fromLTWH(
              inset, inset, size.width - inset * 2, size.height - inset * 2),
          glow);
    }

    final petalPaint = Paint()
      ..color = AppColors.maroon.withValues(alpha: 0.08);
    for (var i = 0; i < 8; i++) {
      final angle = (pi / 4) * i;
      final petalCenter = Offset(
        center.dx + cos(angle) * size.width * 0.35,
        center.dy + sin(angle) * size.height * 0.35,
      );
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 17, height: 42),
          petalPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MeditationHaloPainter oldDelegate) {
    return oldDelegate.active != active;
  }
}

class _WisdomScreen extends StatelessWidget {
  const _WisdomScreen({required this.quotesStream});

  final Stream<List<WisdomQuote>> quotesStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WisdomQuote>>(
      stream: quotesStream,
      initialData: fallbackQuotes,
      builder: (context, snapshot) {
        final quotes = snapshot.data ?? fallbackQuotes;
        final quote = localizedWisdomQuote(
            context, quotes[DateTime.now().day % quotes.length]);

        return _PageScaffold(
          children: [
            _ScreenTitle(
              icon: Icons.format_quote_rounded,
              title: appText(context, 'Daily Wisdom', 'दैनिक ज्ञान'),
              subtitle: appText(
                context,
                'Short reflections from Sadguru Maharaj.',
                'सद्गुरु महाराज के छोटे प्रेरक विचार।',
              ),
            ),
            _WisdomFeature(quote: quote),
            ...quotes.map(
              (item) => _WisdomQuoteCard(
                quote: localizedWisdomQuote(context, item),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WisdomQuoteCard extends StatelessWidget {
  const _WisdomQuoteCard({required this.quote});

  final WisdomQuote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(color: const Color(0xFFFFFCF8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.rose,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.spa_rounded, color: AppColors.maroon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.text,
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    color: AppColors.ink,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  quote.author,
                  style: const TextStyle(
                    color: AppColors.maroon,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen({
    required this.user,
    required this.onSignOut,
  });

  final User? user;
  final Future<void> Function() onSignOut;

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          color: AppColors.maroon,
          size: 34,
        ),
        title: Text(
          appText(context, 'Sign out?', 'साइन आउट करें?'),
          textAlign: TextAlign.center,
        ),
        content: Text(
          appText(
            context,
            'You will return to the Guruvandan sign-in page.',
            'आप गुरुवंदन के साइन-इन पेज पर वापस जाएंगे।',
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText(context, 'Cancel', 'रद्द करें')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout_rounded),
            label: Text(appText(context, 'Sign out', 'साइन आउट')),
          ),
        ],
      ),
    );

    if (confirmed == true) await onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      children: [
        _ScreenTitle(
          icon: Icons.tune_rounded,
          title: appText(context, 'More', 'अधिक'),
          subtitle: appText(
            context,
            'Upcoming modules and personal settings.',
            'आने वाले मॉड्यूल और व्यक्तिगत सेटिंग्स।',
          ),
        ),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 126,
                height: 126,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Image.asset('assets/images/app_icon.png',
                    fit: BoxFit.contain),
              ),
              const SizedBox(height: 22),
              Text(
                'Guruvandan',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                appText(
                  context,
                  'A gentle daily companion for satsang, meditation, wisdom, and routine streaks.',
                  'सत्संग, ध्यान, ज्ञान और दिनचर्या स्ट्रीक का सरल दैनिक साथी।',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const _LanguageSettingsCard(),
        const _ComingSoonModules(),
        if (user != null)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: _cardDecoration(color: AppColors.offWhite),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appText(context, 'Account', 'खाता'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _userLabel(user!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(appText(context, 'Sign out', 'साइन आउट')),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LanguageSettingsCard extends StatelessWidget {
  const _LanguageSettingsCard();

  @override
  Widget build(BuildContext context) {
    final scope = LanguageScope.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(color: AppColors.offWhite),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: Icons.translate_rounded,
                background: AppColors.rose,
                color: AppColors.maroon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appText(context, 'Language', 'भाषा'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appText(
                        context,
                        'Choose the app language.',
                        'ऐप की भाषा चुनें।',
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            height: 1.28,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppLanguage>(
              segments: [
                ButtonSegment(
                  value: AppLanguage.english,
                  icon: const Icon(Icons.language_rounded),
                  label: Text(appText(context, 'English', 'अंग्रेज़ी')),
                ),
                ButtonSegment(
                  value: AppLanguage.hindi,
                  icon: const Icon(Icons.translate_rounded),
                  label: Text(appText(context, 'Hindi', 'हिंदी')),
                ),
              ],
              selected: {scope.language},
              onSelectionChanged: (value) => scope.onChanged(value.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.comfortable,
                textStyle: WidgetStatePropertyAll(
                  _bodyStyle(
                    scope.language,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonModules extends StatelessWidget {
  const _ComingSoonModules();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: appText(context, 'Modules', 'मॉड्यूल')),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 560;
            final spacing = twoColumns ? 12.0 : 10.0;
            final cardWidth = twoColumns
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _ComingSoonModuleCard(
                  icon: Icons.shopping_bag_outlined,
                  title: appText(context, 'Shop', 'दुकान'),
                  subtitle: appText(
                    context,
                    'Devotional items and books',
                    'भक्ति सामग्री और पुस्तकें',
                  ),
                  accentColor: AppColors.gold,
                ),
                _ComingSoonModuleCard(
                  icon: Icons.event_available_rounded,
                  title: appText(context, 'Events', 'कार्यक्रम'),
                  subtitle: appText(
                    context,
                    'Satsang dates and community gatherings',
                    'सत्संग तिथियां और सामुदायिक मिलन',
                  ),
                  accentColor: AppColors.sage,
                ),
                _ComingSoonModuleCard(
                  icon: Icons.photo_library_rounded,
                  title: appText(context, 'Guru Gallery', 'गुरु गैलरी'),
                  subtitle: appText(
                    context,
                    'Sacred photos and memories',
                    'पावन चित्र और स्मृतियां',
                  ),
                  accentColor: AppColors.river,
                ),
                _ComingSoonModuleCard(
                  icon: Icons.question_answer_rounded,
                  title: appText(context, 'Jigyasa', 'जिज्ञासा'),
                  subtitle: appText(
                    context,
                    'Questions and guidance',
                    'प्रश्न और मार्गदर्शन',
                  ),
                  accentColor: AppColors.maroon,
                ),
              ].map((card) => SizedBox(width: cardWidth, child: card)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ComingSoonModuleCard extends StatelessWidget {
  const _ComingSoonModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(
        color: AppColors.offWhite,
        borderColor: AppColors.border,
      ).copyWith(
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.rose,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  appText(context, 'Coming soon', 'जल्द आ रहा है'),
                  style: TextStyle(
                    color: AppColors.maroon,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.32,
                ),
          ),
        ],
      ),
    );
  }
}

class _AdminRoute extends StatelessWidget {
  const _AdminRoute({required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return AdminConsole(
        content: FirebaseContentService(firebaseReady),
        firebaseReady: firebaseReady,
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const _AuthLoadingScaffold();
        }

        if (snapshot.data == null) {
          return _SignInScreen(
            initialStatus: appText(
              context,
              'Admin access: sign in with the authorized Guruvandan admin account.',
              'एडमिन प्रवेश: अधिकृत गुरुवंदन एडमिन खाते से साइन इन करें।',
            ),
          );
        }

        return AdminConsole(
          content: FirebaseContentService(firebaseReady),
          firebaseReady: firebaseReady,
        );
      },
    );
  }
}

class AdminConsole extends StatefulWidget {
  const AdminConsole(
      {required this.content, required this.firebaseReady, super.key});

  final FirebaseContentService content;
  final bool firebaseReady;

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  final email = TextEditingController();
  final password = TextEditingController();
  final title = TextEditingController();
  final description = TextEditingController();
  final duration = TextEditingController(text: '05:00');
  final quoteEnglish = TextEditingController();
  final quoteHindi = TextEditingController();
  final authorEnglish = TextEditingController(text: 'Sadguru Maharaj');
  final authorHindi = TextEditingController(text: 'सद्गुरु महाराज');

  SatsangSession session = SatsangSession.morning;
  PlatformFile? pickedFile;
  bool busy = false;
  String status = '';

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    title.dispose();
    description.dispose();
    duration.dispose();
    quoteEnglish.dispose();
    quoteHindi.dispose();
    authorEnglish.dispose();
    authorHindi.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!widget.firebaseReady) {
      setState(() => status = appText(
            context,
            'Firebase is not configured yet.',
            'Firebase अभी कॉन्फ़िगर नहीं है।',
          ));
      return;
    }

    setState(() => busy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      setState(() => status = appText(
            context,
            'Signed in.',
            'साइन इन हो गया।',
          ));
    } on FirebaseAuthException catch (error) {
      setState(() => status = error.message ?? 'Sign in failed.');
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'mp4'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => pickedFile = result.files.first);
    }
  }

  Future<void> _uploadAudio() async {
    if (pickedFile == null || title.text.trim().isEmpty) {
      setState(() => status = appText(
            context,
            'Choose audio and enter a title.',
            'ऑडियो चुनें और शीर्षक दर्ज करें।',
          ));
      return;
    }

    setState(() => busy = true);
    try {
      await widget.content.uploadSatsang(
        file: pickedFile!,
        session: session,
        title: title.text.trim(),
        description: description.text.trim(),
        durationLabel:
            duration.text.trim().isEmpty ? '00:00' : duration.text.trim(),
      );
      title.clear();
      description.clear();
      setState(() {
        pickedFile = null;
        status = appText(
          context,
          'Satsang uploaded.',
          'सत्संग अपलोड हो गया।',
        );
      });
    } catch (error) {
      setState(() => status = error.toString());
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _publishQuote() async {
    if (quoteEnglish.text.trim().isEmpty || quoteHindi.text.trim().isEmpty) {
      setState(() => status = appText(
            context,
            'Write the quote in both English and Hindi.',
            'वचन अंग्रेजी और हिंदी दोनों में लिखें।',
          ));
      return;
    }

    setState(() => busy = true);
    try {
      await widget.content.publishQuote(
        textEnglish: quoteEnglish.text.trim(),
        textHindi: quoteHindi.text.trim(),
        authorEnglish: authorEnglish.text.trim().isEmpty
            ? 'Sadguru Maharaj'
            : authorEnglish.text.trim(),
        authorHindi: authorHindi.text.trim().isEmpty
            ? 'सद्गुरु महाराज'
            : authorHindi.text.trim(),
      );
      quoteEnglish.clear();
      quoteHindi.clear();
      setState(() => status = appText(
            context,
            'Quote published.',
            'वचन प्रकाशित हो गया।',
          ));
    } catch (error) {
      setState(() => status = error.toString());
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _editQuote(WisdomQuote item) async {
    final englishText = TextEditingController(text: item.text);
    final hindiText = TextEditingController(text: item.textHindi);
    final englishAuthor = TextEditingController(text: item.author);
    final hindiAuthor = TextEditingController(text: item.authorHindi);
    final formKey = GlobalKey<FormState>();

    final draft = await showDialog<_QuoteDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.maroon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(appText(
                context,
                'Edit quote',
                'वचन संपादित करें',
              )),
            ),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: englishText,
                    minLines: 4,
                    maxLines: 7,
                    decoration: _inputDecoration('Quote in English'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'English quote is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: hindiText,
                    minLines: 4,
                    maxLines: 7,
                    decoration: _inputDecoration('हिंदी में वचन'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'हिंदी वचन आवश्यक है।'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: englishAuthor,
                    decoration: _inputDecoration('Attribution in English'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: hindiAuthor,
                    decoration: _inputDecoration('हिंदी में श्रेय'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appText(context, 'Cancel', 'रद्द करें')),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(
                dialogContext,
                _QuoteDraft(
                  textEnglish: englishText.text.trim(),
                  textHindi: hindiText.text.trim(),
                  authorEnglish: englishAuthor.text.trim().isEmpty
                      ? 'Sadguru Maharaj'
                      : englishAuthor.text.trim(),
                  authorHindi: hindiAuthor.text.trim().isEmpty
                      ? 'सद्गुरु महाराज'
                      : hindiAuthor.text.trim(),
                ),
              );
            },
            icon: const Icon(Icons.save_rounded),
            label: Text(appText(context, 'Save changes', 'बदलाव सहेजें')),
          ),
        ],
      ),
    );

    englishText.dispose();
    hindiText.dispose();
    englishAuthor.dispose();
    hindiAuthor.dispose();
    if (draft == null || !mounted) return;

    setState(() => busy = true);
    try {
      await widget.content.updateQuote(
        id: item.id,
        textEnglish: draft.textEnglish,
        textHindi: draft.textHindi,
        authorEnglish: draft.authorEnglish,
        authorHindi: draft.authorHindi,
      );
      if (mounted) {
        setState(() => status = appText(
              context,
              'Quote updated.',
              'वचन अपडेट हो गया।',
            ));
      }
    } catch (error) {
      if (mounted) setState(() => status = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(appText(
          context,
          'Guruvandan Admin',
          'गुरुवंदन एडमिन',
        )),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: appText(context, 'Sign out', 'साइन आउट'),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: widget.firebaseReady
              ? FirebaseAuth.instance.authStateChanges()
              : Stream<User?>.value(null),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;

            if (user == null) {
              return _PageScaffold(
                maxWidth: 560,
                children: [
                  _ScreenTitle(
                    icon: Icons.admin_panel_settings_rounded,
                    title: appText(context, 'Admin Sign In', 'एडमिन साइन इन'),
                    subtitle: appText(
                      context,
                      'Upload satsang audio and publish Sadguru quotes.',
                      'सत्संग ऑडियो अपलोड करें और सद्गुरु वचन प्रकाशित करें।',
                    ),
                  ),
                  _AdminCard(
                    children: [
                      TextField(
                          controller: email,
                          decoration: _inputDecoration(
                            appText(context, 'Admin email', 'एडमिन ईमेल'),
                          )),
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: _inputDecoration(
                          appText(context, 'Password', 'पासवर्ड'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: busy ? null : _signIn,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: Text(appText(
                          context,
                          'Open console',
                          'कंसोल खोलें',
                        )),
                      ),
                      if (status.isNotEmpty) _StatusText(status),
                    ],
                  ),
                ],
              );
            }

            return FutureBuilder<bool>(
              future: widget.content.isAdmin(user),
              builder: (context, adminSnapshot) {
                final admin = adminSnapshot.data == true;
                if (!admin) {
                  return _PageScaffold(
                    maxWidth: 680,
                    children: [
                      _ScreenTitle(
                        icon: Icons.block_rounded,
                        title: appText(
                          context,
                          'Access not enabled',
                          'प्रवेश सक्षम नहीं है',
                        ),
                        subtitle: appText(
                          context,
                          'This account signed in but is not listed as an admin.',
                          'यह खाता साइन इन है लेकिन एडमिन सूची में नहीं है।',
                        ),
                      ),
                      _AdminCard(
                        children: [
                          Text(
                            'Add this UID under admins/${user.uid}: true in Firebase Realtime Database, or use $allowedAdminEmail.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return _PageScaffold(
                  maxWidth: 1100,
                  children: [
                    _ScreenTitle(
                      icon: Icons.dashboard_customize_rounded,
                      title: appText(context, 'Admin Console', 'एडमिन कंसोल'),
                      subtitle: appText(
                        context,
                        'Signed in as ${user.email}',
                        '${user.email} से साइन इन',
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 760;
                        final panels = [
                          _AdminCard(children: _audioForm()),
                          _AdminCard(children: _quoteForm()),
                        ];
                        return narrow
                            ? Column(
                                children: panels
                                    .map((item) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: item))
                                    .toList())
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: panels[0]),
                                  const SizedBox(width: 16),
                                  Expanded(child: panels[1]),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 2),
                    _quoteManager(),
                    if (status.isNotEmpty) _StatusText(status),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _audioForm() {
    return [
      Text(
        appText(context, 'Upload satsang', 'सत्संग अपलोड करें'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 14),
      SegmentedButton<SatsangSession>(
        segments: [
          ButtonSegment(
              value: SatsangSession.morning,
              label: Text(appText(context, 'Morning', 'प्रातः')),
              icon: const Icon(Icons.wb_sunny_rounded)),
          ButtonSegment(
              value: SatsangSession.evening,
              label: Text(appText(context, 'Evening', 'शाम')),
              icon: const Icon(Icons.nights_stay_rounded)),
          ButtonSegment(
              value: SatsangSession.aarti,
              label: Text(appText(context, 'Aarti', 'आरती')),
              icon: const Icon(Icons.local_fire_department_rounded)),
        ],
        selected: {session},
        onSelectionChanged: (value) => setState(() => session = value.first),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: title,
        decoration: _inputDecoration(appText(context, 'Title', 'शीर्षक')),
      ),
      const SizedBox(height: 12),
      TextField(
          controller: description,
          decoration:
              _inputDecoration(appText(context, 'Description', 'विवरण')),
          minLines: 3,
          maxLines: 5),
      const SizedBox(height: 12),
      TextField(
          controller: duration,
          decoration: _inputDecoration(appText(
            context,
            'Duration label, e.g. 12:30',
            'समय लेबल, जैसे 12:30',
          ))),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: busy ? null : _pickAudio,
        icon: const Icon(Icons.audio_file_rounded),
        label: Text(pickedFile == null
            ? appText(context, 'Choose audio', 'ऑडियो चुनें')
            : pickedFile!.name),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: busy ? null : _uploadAudio,
        icon: const Icon(Icons.cloud_upload_rounded),
        label: Text(appText(context, 'Upload satsang', 'सत्संग अपलोड करें')),
      ),
    ];
  }

  List<Widget> _quoteForm() {
    return [
      Text(
        appText(
            context, 'Publish bilingual quote', 'द्विभाषी वचन प्रकाशित करें'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      Text(
        appText(
          context,
          'Both versions are required so every devotee sees the quote in their chosen language.',
          'दोनों भाषाएं आवश्यक हैं, ताकि हर भक्त को चुनी हुई भाषा में वचन दिखे।',
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: quoteEnglish,
        decoration: _inputDecoration('Quote in English'),
        minLines: 4,
        maxLines: 7,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: quoteHindi,
        decoration: _inputDecoration('हिंदी में वचन'),
        minLines: 4,
        maxLines: 7,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: authorEnglish,
        decoration: _inputDecoration('Attribution in English'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: authorHindi,
        decoration: _inputDecoration('हिंदी में श्रेय'),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: busy ? null : _publishQuote,
        icon: const Icon(Icons.format_quote_rounded),
        label: Text(appText(context, 'Publish quote', 'वचन प्रकाशित करें')),
      ),
    ];
  }

  Widget _quoteManager() {
    return StreamBuilder<List<WisdomQuote>>(
      stream: widget.content.adminQuotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _AdminCard(
            children: [
              Center(child: CircularProgressIndicator()),
            ],
          );
        }

        if (snapshot.hasError) {
          return _AdminCard(
            children: [
              Text(
                appText(
                  context,
                  'Quotes could not be loaded. Check the Firebase database rules.',
                  'वचन लोड नहीं हो सके। Firebase डेटाबेस नियम जांचें।',
                ),
                style: const TextStyle(color: AppColors.crimson),
              ),
            ],
          );
        }

        final quotes = snapshot.data ?? const <WisdomQuote>[];
        return _AdminCard(
          children: [
            Row(
              children: [
                const _IconBadge(
                  icon: Icons.library_books_rounded,
                  background: AppColors.rose,
                  color: AppColors.maroon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appText(context, 'Manage quotes', 'वचन प्रबंधित करें'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        appText(
                          context,
                          'Newest quotes are shown first.',
                          'नवीनतम वचन सबसे पहले दिखाए गए हैं।',
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${quotes.length}',
                    style: const TextStyle(
                      color: AppColors.maroon,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (quotes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  appText(
                    context,
                    'No Firebase quotes yet. Publish the first one above.',
                    'अभी Firebase में कोई वचन नहीं है। ऊपर पहला वचन प्रकाशित करें।',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else
              for (var index = 0; index < quotes.length; index++) ...[
                _AdminQuoteListItem(
                  quote: quotes[index],
                  newest: index == 0,
                  onEdit: busy ? null : () => _editQuote(quotes[index]),
                ),
                if (index != quotes.length - 1) const Divider(height: 28),
              ],
          ],
        );
      },
    );
  }
}

class _QuoteDraft {
  const _QuoteDraft({
    required this.textEnglish,
    required this.textHindi,
    required this.authorEnglish,
    required this.authorHindi,
  });

  final String textEnglish;
  final String textHindi;
  final String authorEnglish;
  final String authorHindi;
}

class _AdminQuoteListItem extends StatelessWidget {
  const _AdminQuoteListItem({
    required this.quote,
    required this.newest,
    required this.onEdit,
  });

  final WisdomQuote quote;
  final bool newest;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final timestamp = quote.createdAt == null
        ? appText(context, 'Date unavailable', 'तिथि उपलब्ध नहीं')
        : DateFormat('dd MMM yyyy, hh:mm a').format(
            DateTime.fromMillisecondsSinceEpoch(quote.createdAt!).toLocal(),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      timestamp,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (newest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appText(context, 'Newest', 'नवीनतम'),
                          style: const TextStyle(
                            color: AppColors.maroon,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  quote.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '- ${quote.author}',
                  style: const TextStyle(color: AppColors.taupe),
                ),
                const SizedBox(height: 10),
                Text(
                  quote.textHindi.trim().isEmpty
                      ? 'हिंदी अनुवाद अभी दर्ज नहीं है।'
                      : quote.textHindi,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: quote.textHindi.trim().isEmpty
                            ? AppColors.crimson
                            : AppColors.ink,
                      ),
                ),
                if (quote.textHindi.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '- ${quote.authorHindi}',
                    style: const TextStyle(color: AppColors.taupe),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            tooltip: appText(context, 'Edit quote', 'वचन संपादित करें'),
          ),
        ],
      ),
    );
  }
}

class _SacredBackground extends StatelessWidget {
  const _SacredBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFCF7),
            Color(0xFFFBF3E7),
            Color(0xFFF5E7D7),
          ],
        ),
      ),
      child: CustomPaint(painter: _QuietTexturePainter()),
    );
  }
}

class _QuietTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.maroon.withValues(alpha: 0.035)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (var y = size.height * 0.08; y < size.height; y += 92) {
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.22, y + 24, size.width * 0.48, y + 4)
        ..quadraticBezierTo(size.width * 0.72, y - 16, size.width, y + 18);
      canvas.drawPath(path, line);
    }

    final band = Paint()..color = AppColors.gold.withValues(alpha: 0.08);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.84, size.width, size.height * 0.16),
        band);
  }

  @override
  bool shouldRepaint(covariant _QuietTexturePainter oldDelegate) => false;
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.children,
    this.maxWidth = 720,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: ValueKey(children.first.runtimeType),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children
                      .map((child) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: child,
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.rose,
          ),
          child: Icon(icon, color: AppColors.maroon, size: 31),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 27),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null) action!,
      ],
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool done;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: _cardDecoration(
          color: done ? const Color(0xFFFFFBF4) : AppColors.surface,
          borderColor: done ? const Color(0xFFD8C39E) : AppColors.border,
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: done ? AppColors.maroon : AppColors.rose,
              ),
              child: Icon(done ? Icons.check_rounded : icon,
                  color: done ? AppColors.cream : AppColors.maroon, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 19)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: done ? const Color(0xFFEDF4ED) : AppColors.cream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: done ? const Color(0xFFD6E3D6) : AppColors.border),
              ),
              child: Icon(
                done ? Icons.verified_rounded : Icons.chevron_right_rounded,
                color: done ? AppColors.sage : AppColors.maroon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WisdomFeature extends StatelessWidget {
  const _WisdomFeature({required this.quote});

  final WisdomQuote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(
        color: const Color(0xFFFFF8EF),
        borderColor: const Color(0xFFECD9BC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              color: AppColors.gold, size: 36),
          const SizedBox(height: 12),
          Text(
            quote.text,
            style: GoogleFonts.lora(
              color: AppColors.ink,
              fontSize: 24,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            quote.author,
            style: const TextStyle(
              color: AppColors.maroon,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutHomeSection extends StatelessWidget {
  const _AboutHomeSection();

  static const guruMaharajText =
      'Sadguru Maharshi Mehi Paramhans was one of the most respected saints '
      'and spiritual masters of the Sant Mat tradition in India. Born in '
      'Bihar, he dedicated his life to spreading the message of inner '
      'meditation, self-realization, universal love, and peace. He emphasized '
      'the practice of Surat Shabd Yoga and taught that true spirituality lies '
      'beyond caste, religion, and social divisions.\n\n'
      'Through his profound writings, discourses, and compassionate guidance, '
      'he inspired millions of devotees to walk the path of devotion, '
      'simplicity, morality, and spiritual awakening. His teachings continue '
      'to guide seekers toward inner harmony and realization of the Divine '
      'within every soul.';

  static const guruVandanText =
      'A sacred space for daily spiritual practice - satsang, meditation, '
      'Sadguru\'s wisdom and community of devotees, all in one place. Jai Guru.';

  static const guruMaharajTextHindi =
      'सद्गुरु महर्षि मेंही परमहंस भारत की संतमत परंपरा के अत्यंत सम्मानित '
      'संतों और आध्यात्मिक आचार्यों में से एक थे। बिहार में जन्मे, उन्होंने '
      'अपना जीवन आंतरिक ध्यान, आत्म-साक्षात्कार, सार्वभौमिक प्रेम और शांति '
      'का संदेश फैलाने में समर्पित किया। उन्होंने सुरत शब्द योग के अभ्यास '
      'पर बल दिया और सिखाया कि सच्ची आध्यात्मिकता जाति, धर्म और सामाजिक '
      'भेदों से परे है।\n\n'
      'अपने गहन लेखन, प्रवचनों और करुणामय मार्गदर्शन से उन्होंने लाखों '
      'भक्तों को भक्ति, सरलता, नैतिकता और आध्यात्मिक जागरण के मार्ग पर '
      'चलने की प्रेरणा दी। उनकी शिक्षाएं आज भी साधकों को आंतरिक शांति और '
      'हर आत्मा में स्थित दिव्य चेतना की अनुभूति की ओर ले जाती हैं।';

  static const guruVandanTextHindi =
      'दैनिक आध्यात्मिक साधना के लिए एक पावन स्थान - सत्संग, ध्यान, '
      'सद्गुरु की वाणी और भक्तों का समुदाय, सब एक जगह। जय गुरु।';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AboutAccordionCard(
          title:
              appText(context, 'ABOUT GURU MAHARAJ', 'गुरु महाराज के बारे में'),
          summary: appText(
            context,
            'Life, teachings, and the Sant Mat path',
            'जीवन, शिक्षाएं और संतमत मार्ग',
          ),
          body: appText(context, guruMaharajText, guruMaharajTextHindi),
          accentColor: AppColors.maroon,
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 14),
        _AboutAccordionCard(
          title: appText(context, 'ABOUT GURU VANDAN', 'गुरु वंदन के बारे में'),
          summary: appText(
            context,
            'A sacred space for daily practice',
            'दैनिक साधना का पावन स्थान',
          ),
          body: appText(context, guruVandanText, guruVandanTextHindi),
          accentColor: AppColors.gold,
          icon: Icons.volunteer_activism_rounded,
        ),
      ],
    );
  }
}

class _AboutAccordionCard extends StatelessWidget {
  const _AboutAccordionCard({
    required this.title,
    required this.summary,
    required this.body,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String summary;
  final String body;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(
        color: AppColors.offWhite,
        borderColor: AppColors.border,
      ).copyWith(
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 5, color: accentColor),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: accentColor.withValues(alpha: 0.08),
              highlightColor: accentColor.withValues(alpha: 0.05),
            ),
            child: ExpansionTile(
              maintainState: true,
              tilePadding: const EdgeInsets.fromLTRB(22, 10, 16, 10),
              childrenPadding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: accentColor,
              collapsedIconColor: AppColors.taupe,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 23),
              ),
              title: Text(
                title,
                style: GoogleFonts.inter(
                  color: accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.taupe,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              children: [
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: AppColors.ink,
                    fontSize: 18,
                    height: 1.56,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6E3D6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.sage),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
                color: AppColors.sage, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? AppColors.crimson : AppColors.sage,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.selected, required this.onSelected});

  final PracticeTab selected;
  final ValueChanged<PracticeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.of(context).language;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selected.index,
        onDestinationSelected: (index) => onSelected(PracticeTab.values[index]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.rose,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            label: appText(context, 'Home', 'होम'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.headphones_rounded),
            label: appText(context, 'Satsang', 'सत्संग'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.timer_rounded),
            label: appText(context, 'Meditate', 'ध्यान'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.format_quote_rounded),
            label: appText(context, 'Wisdom', 'ज्ञान'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_rounded),
            label: appText(context, 'More', 'अधिक'),
          ),
        ],
        labelTextStyle: WidgetStatePropertyAll(
          _bodyStyle(language, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(
    {Color color = AppColors.surface, Color borderColor = AppColors.border}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: AppColors.deepCrimson.withValues(alpha: 0.07),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.cream,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.maroon, width: 1.5),
    ),
  );
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatSeconds(int total) {
  final safe = max(0, total);
  final hours = safe ~/ 3600;
  final minutes = ((safe % 3600) ~/ 60).toString().padLeft(2, '0');
  final seconds = (safe % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

Duration _minimumMeditationDuration(Duration duration) {
  if (duration.inSeconds < 60) return const Duration(minutes: 1);
  return Duration(minutes: duration.inMinutes);
}

String _formatDurationLabel(BuildContext context, Duration duration) {
  final safe = _minimumMeditationDuration(duration);
  final totalMinutes = safe.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours == 0) return _formatMinutesLabel(context, minutes);
  if (minutes == 0) {
    return appText(
      context,
      hours == 1 ? '1 hr' : '$hours hr',
      '$hours घंटा',
    );
  }
  return appText(
    context,
    '$hours hr $minutes min',
    '$hours घंटा $minutes मिनट',
  );
}

String _formatMinutesLabel(BuildContext context, int minutes) {
  return appText(context, '$minutes min', '$minutes मिनट');
}

SatsangSession _satsangSessionFromValue(Object? value) {
  switch (value?.toString()) {
    case 'evening':
      return SatsangSession.evening;
    case 'aarti':
      return SatsangSession.aarti;
    case 'morning':
    default:
      return SatsangSession.morning;
  }
}

RoutineTask? _routineTaskForSatsangSession(SatsangSession session) {
  switch (session) {
    case SatsangSession.morning:
      return RoutineTask.morningSatsang;
    case SatsangSession.evening:
      return RoutineTask.eveningSatsang;
    case SatsangSession.aarti:
      return null;
  }
}

IconData _satsangSessionIcon(SatsangSession session) {
  switch (session) {
    case SatsangSession.morning:
      return Icons.wb_sunny_rounded;
    case SatsangSession.evening:
      return Icons.nights_stay_rounded;
    case SatsangSession.aarti:
      return Icons.local_fire_department_rounded;
  }
}

String _satsangSessionLabel(BuildContext context, SatsangSession session) {
  switch (session) {
    case SatsangSession.morning:
      return appText(context, 'Morning', 'प्रातः');
    case SatsangSession.evening:
      return appText(context, 'Evening', 'शाम');
    case SatsangSession.aarti:
      return appText(context, 'Aarti', 'आरती');
  }
}

String _satsangSessionEyebrow(BuildContext context, SatsangSession session) {
  switch (session) {
    case SatsangSession.morning:
      return appText(context, 'Morning satsang', 'प्रातः सत्संग');
    case SatsangSession.evening:
      return appText(context, 'Evening satsang', 'शाम सत्संग');
    case SatsangSession.aarti:
      return appText(context, 'Aarti', 'आरती');
  }
}

String _cleanNamePart(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String? _normalizedPhone(String value) {
  var clean = value.trim().replaceAll(RegExp(r'[\s()\-]'), '');
  if (clean.isEmpty) return null;
  if (!clean.startsWith('+') && RegExp(r'^\d{10}$').hasMatch(clean)) {
    clean = '+91$clean';
  }
  if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(clean)) return null;
  return clean;
}

String _userLabel(User user) {
  if ((user.email ?? '').trim().isNotEmpty) return user.email!.trim();
  if ((user.phoneNumber ?? '').trim().isNotEmpty) {
    return user.phoneNumber!.trim();
  }
  return 'Signed in';
}

String _friendlyAuthMessage(FirebaseAuthException error, String fallback) {
  final detail = error.message?.trim();
  final suffix = detail == null || detail.isEmpty ? '' : ' ($detail)';

  switch (error.code) {
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled in Firebase. Enable Google and Phone under Authentication -> Sign-in method.$suffix';
    case 'unauthorized-domain':
      return 'This website is not authorized in Firebase. Add ajaybhatnagar1712.github.io under Authentication -> Settings -> Authorized domains.$suffix';
    case 'popup-closed-by-user':
    case 'cancelled-popup-request':
      return 'Google sign-in was closed before completion. Please try again.$suffix';
    case 'network-request-failed':
      return 'Network problem during sign-in. Check internet and try again.$suffix';
    case 'invalid-phone-number':
      return 'The phone number format is not valid. Use country code, for example +91 98765 43210.$suffix';
    case 'invalid-verification-code':
      return 'The OTP is incorrect. Please check the code and try again.$suffix';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a while and try again.$suffix';
    default:
      return '$fallback [${error.code}]$suffix';
  }
}

bool _shouldFallbackToRedirect(String code) {
  return code == 'popup-blocked' ||
      code == 'popup-closed-by-user' ||
      code == 'cancelled-popup-request' ||
      code == 'web-context-cancelled' ||
      code == 'internal-error';
}

String _audioContentType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.m4a')) return 'audio/mp4';
  if (lower.endsWith('.aac')) return 'audio/aac';
  if (lower.endsWith('.wav')) return 'audio/wav';
  if (lower.endsWith('.mp4')) return 'audio/mp4';
  return 'audio/mpeg';
}
