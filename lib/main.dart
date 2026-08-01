import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

const allowedAdminEmail = 'ajaybhatnagar1712@gmail.com';

const firebaseOptions = FirebaseOptions(
  apiKey: String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBDnC1IE0BImeYue5vaOicS4_Miw0Vd2xE',
  ),
  appId: String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:540841544767:web:guruvandan-flutter',
  ),
  messagingSenderId: '540841544767',
  projectId: 'guru-vandan',
  authDomain: 'guru-vandan.firebaseapp.com',
  databaseURL:
      'https://guru-vandan-default-rtdb.asia-southeast1.firebasedatabase.app/',
  storageBucket: 'guru-vandan.firebasestorage.app',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureLongFormAudio();
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

Future<void> _configureLongFormAudio() async {
  try {
    await AudioPlayer.global.setAudioContext(_longFormAudioContext());
  } catch (_) {
    // Web and some test platforms do not expose native audio-session controls.
  }
}

AudioContext _longFormAudioContext() {
  return AudioContextConfig(
    focus: AudioContextConfigFocus.gain,
    respectSilence: false,
    stayAwake: true,
  ).build();
}

class GuruvandanApp extends StatelessWidget {
  const GuruvandanApp({
    required this.firebaseReady,
    this.showOpening = true,
    super.key,
  });

  final bool firebaseReady;
  final bool showOpening;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme();

    return MaterialApp(
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
          titleTextStyle: GoogleFonts.lora(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(56, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(56, 54),
            side: const BorderSide(color: AppColors.borderStrong),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        textTheme: textTheme.copyWith(
          displayLarge: GoogleFonts.lora(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.04,
          ),
          headlineMedium: GoogleFonts.lora(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.12,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 18,
            height: 1.42,
            color: AppColors.taupe,
          ),
        ),
      ),
      home: showOpening
          ? SpiritualOpening(firebaseReady: firebaseReady)
          : AuthGate(firebaseReady: firebaseReady),
      routes: {
        '/admin': (_) => _AdminRoute(firebaseReady: firebaseReady),
      },
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
        if (decoded is Map) {
          return fromParts(
            firstName: decoded['firstName']?.toString() ?? '',
            middleName: decoded['middleName']?.toString() ?? '',
            lastName: decoded['lastName']?.toString() ?? '',
          );
        }
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
    this.author = 'Sadguru Maharaj',
    this.active = true,
    this.createdAt,
  });

  final String id;
  final String text;
  final String author;
  final bool active;
  final int? createdAt;

  factory WisdomQuote.fromEntry(String id, Map<dynamic, dynamic> value) {
    return WisdomQuote(
      id: id,
      text: (value['text'] ?? '').toString(),
      author: (value['author'] ?? 'Sadguru Maharaj').toString(),
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

  Future<void> publishQuote(String text, String author) async {
    if (!ready) throw StateError('Firebase is not configured.');
    final key = FirebaseDatabase.instance.ref('quotes').push().key;
    if (key == null) throw StateError('Could not create a quote record.');
    await FirebaseDatabase.instance.ref('quotes/$key').set({
      'text': text,
      'author': author,
      'active': true,
      'createdAt': ServerValue.timestamp,
      'createdBy': FirebaseAuth.instance.currentUser?.email,
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
                                'Smaran. Satsang. Dhyan.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
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

    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      await FirebaseAuth.instance.getRedirectResult();
    } on FirebaseAuthException catch (error) {
      return _friendlyAuthMessage(error, 'Google sign-in failed.');
    } catch (_) {
      return 'Google sign-in could not be completed. Please try again.';
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
      _setError('Google sign-in could not be completed.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sendOtp() async {
    final phoneNumber = _normalizedPhone(phone.text);
    if (phoneNumber == null) {
      _setError('Enter a valid phone number with country code.');
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
            status = 'OTP sent to $phoneNumber.';
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
              _setError(error.message ?? 'Phone verification failed.');
            }
          },
          codeSent: (id, _) {
            if (mounted) {
              setState(() {
                verificationId = id;
                otpSent = true;
                status = 'OTP sent to $phoneNumber.';
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
      _setError('Could not send OTP. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = otp.text.trim();
    if (code.length < 4) {
      _setError('Enter the OTP received on your phone.');
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
          _setError('Please request OTP again.');
          return;
        }
        await result.confirm(code);
      } else {
        final id = verificationId;
        if (id == null) {
          _setError('Please request OTP again.');
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
      _setError('OTP verification could not be completed.');
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
                          'Sign in to Guruvandan',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lora(
                            color: AppColors.ink,
                            fontSize: 31,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Use Google or phone number to begin your spiritual routine.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: busy ? null : _signInWithGoogle,
                          icon:
                              const Icon(Icons.g_mobiledata_rounded, size: 31),
                          label: const Text('Continue with Google'),
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
                                'or phone',
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
                          decoration: _inputDecoration('Phone number').copyWith(
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
                            decoration: _inputDecoration('OTP code').copyWith(
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
                          label: Text(otpSent ? 'Verify OTP' : 'Send OTP'),
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
                            child: const Text('Use another phone number'),
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
  final satsangPlayer = AudioPlayer();
  final chantPlayer = AudioPlayer();
  final mantraLoopPlayer = AudioPlayer();

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
  bool mantraLoopEnabled = false;
  bool mantraLoopPlaying = false;
  bool silentPromptOpen = false;
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
    _configureAudioPlayers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    meditationTimer?.cancel();
    satsangPlayer.dispose();
    chantPlayer.dispose();
    mantraLoopPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncMeditationTimerWithClock();
    }
  }

  void _wireAudio() {
    satsangPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => audioPosition = position);
    });
    satsangPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => audioDuration = duration);
    });
    satsangPlayer.onPlayerComplete.listen((_) {
      if (activeTrackTask != null) _markTask(activeTrackTask!);
      if (mounted) {
        setState(() {
          activeTrackId = null;
          activeTrackTask = null;
          audioPosition = Duration.zero;
        });
      }
    });
    mantraLoopPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => mantraLoopPlaying = state == PlayerState.playing);
      }
    });
  }

  void _configureAudioPlayers() {
    final context = _longFormAudioContext();
    unawaited(satsangPlayer.setAudioContext(context).catchError((_) {}));
    unawaited(chantPlayer.setAudioContext(context).catchError((_) {}));
    unawaited(mantraLoopPlayer.setAudioContext(context).catchError((_) {}));
  }

  String get _nameStorageKey =>
      widget.user == null ? nameKey : '$nameKey:${widget.user!.uid}';

  String get _routineStorageKey =>
      widget.user == null ? routineKey : '$routineKey:${widget.user!.uid}';

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserName = prefs.getString(_nameStorageKey);
    final savedName = savedUserName ??
        (widget.user == null ? null : prefs.getString(nameKey));
    final savedRecords = prefs.getString(_routineStorageKey) ??
        (widget.user == null ? null : prefs.getString(routineKey));
    final savedProfile = DevoteeProfile.fromStoredValue(savedName);

    if (savedProfile != null) {
      devoteeProfile = savedProfile;
      if (savedUserName == null && widget.user != null) {
        await prefs.setString(
            _nameStorageKey, jsonEncode(savedProfile.toJson()));
      }
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
        .where((entry) => _isComplete(entry.value))
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
    if (!_isComplete(records[DateFormat('yyyy-MM-dd').format(cursor)] ?? {})) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var current = 0;
    while (
        _isComplete(records[DateFormat('yyyy-MM-dd').format(cursor)] ?? {})) {
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

  bool _isComplete(Map<String, bool> item) {
    return item[RoutineTask.morningSatsang.name] == true &&
        item[RoutineTask.eveningSatsang.name] == true &&
        item[RoutineTask.meditation.name] == true;
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

  Future<void> _resetToday() async {
    meditationRunToken++;
    await chantPlayer.stop();
    setState(() {
      records.remove(todayKey);
      meditationComplete = false;
      meditationRunning = false;
      meditationChantPhase = null;
      meditationEndsAt = null;
      remainingSeconds = selectedDurationSeconds;
    });
    meditationTimer?.cancel();
    await _saveRecords();
  }

  Future<void> _signOut() async {
    meditationRunToken++;
    meditationTimer?.cancel();
    meditationEndsAt = null;
    await satsangPlayer.stop();
    await chantPlayer.stop();
    await mantraLoopPlayer.stop();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _playSatsang(SatsangTrack track) async {
    final task = _routineTaskForSatsangSession(track.session);

    try {
      if (activeTrackId == track.id) {
        final state = satsangPlayer.state;
        if (state == PlayerState.playing) {
          await satsangPlayer.pause();
        } else {
          final confirmed =
              await _confirmPhoneSilent('your satsang can continue peacefully');
          if (!confirmed) return;
          await satsangPlayer.resume();
        }
        setState(() {});
        return;
      }

      final confirmed =
          await _confirmPhoneSilent('your satsang can continue peacefully');
      if (!confirmed) return;

      await _stopMantraLoop();
      await satsangPlayer.stop();
      audioPosition = Duration.zero;
      audioDuration = Duration.zero;

      if (track.audioUrl != null && track.audioUrl!.isNotEmpty) {
        await satsangPlayer.play(UrlSource(track.audioUrl!));
      } else if (track.assetPath != null && track.assetPath!.isNotEmpty) {
        await satsangPlayer.play(AssetSource(track.assetPath!));
      } else {
        await satsangPlayer
            .play(AssetSource('audio/morning_satsang_astuti_rishikesh.mp3'));
      }

      setState(() {
        activeTrackId = track.id;
        activeTrackTask = task;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This satsang audio could not be played.')),
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
    unawaited(chantPlayer.stop());
    final safeSeconds = _minimumMeditationDuration(duration).inSeconds;
    setState(() {
      selectedDurationSeconds = safeSeconds;
      remainingSeconds = safeSeconds;
      customMeditationDurationSelected = custom;
      meditationRunning = false;
      meditationComplete = false;
      meditationChantPhase = null;
      meditationEndsAt = null;
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
      _syncMeditationTimerWithClock();
      meditationTimer?.cancel();
      setState(() {
        meditationRunning = false;
        meditationEndsAt = null;
      });
      return;
    }

    unawaited(_beginMeditationSession());
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
    _startMeditationTimer(token);
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

    await _stopMantraLoop();

    if (!mounted || token != meditationRunToken) return;

    setState(() {
      meditationChantPhase = MeditationChantPhase.closing;
      meditationRunning = false;
      meditationEndsAt = null;
    });

    try {
      await _playMeditationChant();
    } catch (_) {
      _showMeditationAudioError(
          'Completion chime could not be played. Meditation is marked complete.');
    }

    if (!mounted || token != meditationRunToken) return;

    await _markTask(RoutineTask.meditation);

    if (!mounted || token != meditationRunToken) return;

    setState(() {
      meditationChantPhase = null;
      meditationComplete = true;
      meditationEndsAt = null;
    });
  }

  Future<void> _playMeditationChant() async {
    await chantPlayer.stop();

    final completed = Completer<void>();
    void finish() {
      if (!completed.isCompleted) completed.complete();
    }

    final completeSub = chantPlayer.onPlayerComplete.listen((_) => finish());
    final stateSub = chantPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped) finish();
    });

    try {
      await chantPlayer.play(AssetSource('audio/meditation_chant.mp3'));
      await completed.future.timeout(const Duration(minutes: 5));
    } finally {
      await completeSub.cancel();
      await stateSub.cancel();
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

    try {
      await satsangPlayer.stop();
      await mantraLoopPlayer.stop();
      await mantraLoopPlayer.setReleaseMode(ReleaseMode.loop);
      await mantraLoopPlayer
          .play(AssetSource('audio/om_mantra_417hz_loop.mp3'));

      if (!mounted) return;
      setState(() {
        mantraLoopEnabled = true;
        mantraLoopPlaying = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        mantraLoopEnabled = false;
        mantraLoopPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Om mantra audio could not be played.')),
      );
    }
  }

  Future<void> _stopMantraLoop() async {
    await mantraLoopPlayer.stop();
    if (!mounted) return;
    setState(() {
      mantraLoopEnabled = false;
      mantraLoopPlaying = false;
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
    unawaited(chantPlayer.stop());
    setState(() {
      meditationRunning = false;
      meditationComplete = false;
      meditationChantPhase = null;
      meditationEndsAt = null;
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
        name: devoteeProfile?.displayName ?? 'Bhakt',
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
        isPlaying: satsangPlayer.state == PlayerState.playing,
        today: today,
        onSessionChanged: (session) async {
          await satsangPlayer.stop();
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
      setState(() => error = 'Please enter your first name.');
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
                  'Welcome to Guruvandan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    color: AppColors.ink,
                    fontSize: 31,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please enter your name to begin your daily spiritual routine.',
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
                  decoration: _inputDecoration('First name').copyWith(
                    errorText: error,
                    prefixIcon: const Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: middleName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Middle name').copyWith(
                    prefixIcon: const Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _continue(),
                  decoration: _inputDecoration('Last name').copyWith(
                    prefixIcon: const Icon(Icons.family_restroom_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Begin'),
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
          'Put phone on silent',
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            color: AppColors.ink,
            fontSize: 25,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'Please put your phone on silent mode so $reason.',
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
            child: const Text('OK'),
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
        final quote = quotes[DateTime.now().day % quotes.length];

        return _PageScaffold(
          children: [
            _HeroPanel(
              name: name,
              onMorningSatsang: () => onOpenSatsang(SatsangSession.morning),
              onMeditation: onOpenMeditation,
              onEveningSatsang: () => onOpenSatsang(SatsangSession.evening),
            ),
            _StatsRibbon(stats: stats),
            _SectionHeader(
              title: 'Today\'s Routine',
              action: IconButton.filledTonal(
                onPressed: onResetToday,
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'Reset today',
              ),
            ),
            _RoutineTile(
              title: 'Morning satsang',
              subtitle: 'Start the day with remembrance',
              done: today[RoutineTask.morningSatsang.name] == true,
              icon: Icons.wb_sunny_rounded,
              onTap: () => onOpenSatsang(SatsangSession.morning),
            ),
            _RoutineTile(
              title: 'Meditation',
              subtitle: 'Sit quietly with the timer',
              done: today[RoutineTask.meditation.name] == true,
              icon: Icons.self_improvement_rounded,
              onTap: onOpenMeditation,
            ),
            _RoutineTile(
              title: 'Evening satsang',
              subtitle: 'Close the day in satsang',
              done: today[RoutineTask.eveningSatsang.name] == true,
              icon: Icons.nights_stay_rounded,
              onTap: () => onOpenSatsang(SatsangSession.evening),
            ),
            _WisdomFeature(quote: quote),
            const _AboutHomeSection(),
            _MilestonePanel(stats: stats),
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
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Jai Guru, $name'
        : hour < 18
            ? 'Peaceful afternoon, $name'
            : 'Blessed evening, $name';

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
                      style: GoogleFonts.lora(
                        color: AppColors.surface,
                        fontSize: compact ? 29 : 34,
                        fontWeight: FontWeight.w900,
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A gentle daily path for satsang, dhyan, wisdom, and seva of routine.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
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
                          label: 'Morning satsang',
                          onTap: onMorningSatsang,
                        ),
                        _HeroChip(
                          icon: Icons.self_improvement_rounded,
                          label: 'Dhyan',
                          onTap: onMeditation,
                        ),
                        _HeroChip(
                          icon: Icons.nights_stay_rounded,
                          label: 'Evening satsang',
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

class _StatsRibbon extends StatelessWidget {
  const _StatsRibbon({required this.stats});

  final RoutineStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 380 ? 8.0 : 12.0;
        return Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Current',
                    value: stats.current,
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.gold)),
            SizedBox(width: gap),
            Expanded(
                child: _StatCard(
                    label: 'Best',
                    value: stats.best,
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.sage)),
            SizedBox(width: gap),
            Expanded(
                child: _StatCard(
                    label: 'Total',
                    value: stats.total,
                    icon: Icons.calendar_month_rounded,
                    color: AppColors.maroon)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.inter(
              color: AppColors.ink,
              fontSize: 31,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.taupe,
              fontWeight: FontWeight.w900,
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
            const _ScreenTitle(
              icon: Icons.headphones_rounded,
              title: 'Satsang',
              subtitle:
                  'Morning, evening, and aarti audio for steady daily devotion.',
            ),
            _SessionSwitch(
                selected: selectedSession, onChanged: onSessionChanged),
            ...visibleTracks.map((track) {
              final task = _routineTaskForSatsangSession(track.session);
              final done = task != null && today[task.name] == true;
              final active = activeTrackId == track.id;
              final progress = active && audioDuration.inMilliseconds > 0
                  ? audioPosition.inMilliseconds / audioDuration.inMilliseconds
                  : 0.0;

              return _AudioCard(
                track: track,
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
                      _satsangSessionLabel(session),
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
                      _satsangSessionEyebrow(track.session),
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
                  label: Text(playing ? 'Pause' : 'Play'),
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
                    label: Text(done ? 'Completed' : 'Complete'),
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
        ? 'Completion chime'
        : meditationRunning
            ? 'Meditating'
            : meditationComplete
                ? 'Complete'
                : 'Ready';
    final actionLabel = meditationChantPhase == MeditationChantPhase.closing
        ? 'Completion chime'
        : meditationRunning
            ? 'Pause'
            : 'Start';

    return _PageScaffold(
      children: [
        const _ScreenTitle(
          icon: Icons.self_improvement_rounded,
          title: 'Meditation',
          subtitle:
              'Set your duration. The chime plays only when the timer ends.',
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
                      label: Text('$minutes min'),
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
                            Duration(seconds: selectedDurationSeconds))
                        : 'Custom time'),
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
                      label: const Text('Reset'),
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
                const _CompletionBanner(text: 'Meditation completed today'),
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
            ? 'Playing in loop'
            : 'Starting'
        : '417Hz mantra ambience';

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
                  'Om mantra',
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
                          'Custom meditation time',
                          style: GoogleFonts.lora(
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
                        tooltip: 'Close',
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
                            _formatDurationLabel(duration),
                            style: GoogleFonts.inter(
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
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(duration),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Set time'),
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
        final quote = quotes[DateTime.now().day % quotes.length];

        return _PageScaffold(
          children: [
            const _ScreenTitle(
              icon: Icons.format_quote_rounded,
              title: 'Daily Wisdom',
              subtitle: 'Short reflections from Sadguru Maharaj.',
            ),
            _WisdomFeature(quote: quote),
            ...quotes.map(
              (item) => _WisdomQuoteCard(quote: item),
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
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      children: [
        const _ScreenTitle(
          icon: Icons.tune_rounded,
          title: 'More',
          subtitle: 'Upcoming modules and personal settings.',
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
                'A gentle daily companion for satsang, meditation, wisdom, and routine streaks.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const _ComingSoonModules(),
        if (user != null)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: _cardDecoration(color: AppColors.offWhite),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  _userLabel(user!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
      ],
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
        _SectionHeader(title: 'Modules'),
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
              children: const [
                _ComingSoonModuleCard(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Shop',
                  subtitle: 'Devotional items and books',
                  accentColor: AppColors.gold,
                ),
                _ComingSoonModuleCard(
                  icon: Icons.event_available_rounded,
                  title: 'Events',
                  subtitle: 'Satsang dates and community gatherings',
                  accentColor: AppColors.sage,
                ),
                _ComingSoonModuleCard(
                  icon: Icons.photo_library_rounded,
                  title: 'Guru Gallery',
                  subtitle: 'Sacred photos and memories',
                  accentColor: AppColors.river,
                ),
                _ComingSoonModuleCard(
                  icon: Icons.question_answer_rounded,
                  title: 'Jigyasa',
                  subtitle: 'Questions and guidance',
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
                child: const Text(
                  'Coming soon',
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
          return const _SignInScreen(
            initialStatus:
                'Admin access: sign in with the authorized Guruvandan admin account.',
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
  final quote = TextEditingController();
  final author = TextEditingController(text: 'Sadguru Maharaj');

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
    quote.dispose();
    author.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!widget.firebaseReady) {
      setState(() => status = 'Firebase is not configured yet.');
      return;
    }

    setState(() => busy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      setState(() => status = 'Signed in.');
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
      setState(() => status = 'Choose audio and enter a title.');
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
        status = 'Satsang uploaded.';
      });
    } catch (error) {
      setState(() => status = error.toString());
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _publishQuote() async {
    if (quote.text.trim().isEmpty) {
      setState(() => status = 'Write a quote first.');
      return;
    }

    setState(() => busy = true);
    try {
      await widget.content.publishQuote(
        quote.text.trim(),
        author.text.trim().isEmpty ? 'Sadguru Maharaj' : author.text.trim(),
      );
      quote.clear();
      setState(() => status = 'Quote published.');
    } catch (error) {
      setState(() => status = error.toString());
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Guruvandan Admin'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
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
                  const _ScreenTitle(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin Sign In',
                    subtitle:
                        'Upload satsang audio and publish Sadguru quotes.',
                  ),
                  _AdminCard(
                    children: [
                      TextField(
                          controller: email,
                          decoration: _inputDecoration('Admin email')),
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: _inputDecoration('Password'),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: busy ? null : _signIn,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('Open console'),
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
                      const _ScreenTitle(
                        icon: Icons.block_rounded,
                        title: 'Access not enabled',
                        subtitle:
                            'This account signed in but is not listed as an admin.',
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
                      title: 'Admin Console',
                      subtitle: 'Signed in as ${user.email}',
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
      Text('Upload satsang', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      SegmentedButton<SatsangSession>(
        segments: const [
          ButtonSegment(
              value: SatsangSession.morning,
              label: Text('Morning'),
              icon: Icon(Icons.wb_sunny_rounded)),
          ButtonSegment(
              value: SatsangSession.evening,
              label: Text('Evening'),
              icon: Icon(Icons.nights_stay_rounded)),
          ButtonSegment(
              value: SatsangSession.aarti,
              label: Text('Aarti'),
              icon: Icon(Icons.local_fire_department_rounded)),
        ],
        selected: {session},
        onSelectionChanged: (value) => setState(() => session = value.first),
      ),
      const SizedBox(height: 12),
      TextField(controller: title, decoration: _inputDecoration('Title')),
      const SizedBox(height: 12),
      TextField(
          controller: description,
          decoration: _inputDecoration('Description'),
          minLines: 3,
          maxLines: 5),
      const SizedBox(height: 12),
      TextField(
          controller: duration,
          decoration: _inputDecoration('Duration label, e.g. 12:30')),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: busy ? null : _pickAudio,
        icon: const Icon(Icons.audio_file_rounded),
        label: Text(pickedFile == null ? 'Choose audio' : pickedFile!.name),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: busy ? null : _uploadAudio,
        icon: const Icon(Icons.cloud_upload_rounded),
        label: const Text('Upload satsang'),
      ),
    ];
  }

  List<Widget> _quoteForm() {
    return [
      Text('Publish quote', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      TextField(
          controller: quote,
          decoration: _inputDecoration('Sadguru quote'),
          minLines: 7,
          maxLines: 10),
      const SizedBox(height: 12),
      TextField(
          controller: author, decoration: _inputDecoration('Attribution')),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: busy ? null : _publishQuote,
        icon: const Icon(Icons.format_quote_rounded),
        label: const Text('Publish quote'),
      ),
    ];
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

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _AboutAccordionCard(
          title: 'ABOUT GURU MAHARAJ',
          summary: 'Life, teachings, and the Sant Mat path',
          body: guruMaharajText,
          accentColor: AppColors.maroon,
          icon: Icons.auto_awesome_rounded,
        ),
        SizedBox(height: 14),
        _AboutAccordionCard(
          title: 'ABOUT GURU VANDAN',
          summary: 'A sacred space for daily practice',
          body: guruVandanText,
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

class _MilestonePanel extends StatelessWidget {
  const _MilestonePanel({required this.stats});

  final RoutineStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(
        color: const Color(0xFFEDF4ED),
        borderColor: const Color(0xFFD6E3D6),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: AppColors.sage, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.daysToMilestone} days to next milestone',
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text('Complete all three practices to grow your streak.',
                    style: Theme.of(context).textTheme.bodyLarge),
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.headphones_rounded), label: 'Satsang'),
          NavigationDestination(
              icon: Icon(Icons.timer_rounded), label: 'Meditate'),
          NavigationDestination(
              icon: Icon(Icons.format_quote_rounded), label: 'Wisdom'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded), label: 'More'),
        ],
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

String _formatDurationLabel(Duration duration) {
  final safe = _minimumMeditationDuration(duration);
  final totalMinutes = safe.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours == 0) return '$minutes min';
  if (minutes == 0) return hours == 1 ? '1 hr' : '$hours hr';
  return '$hours hr $minutes min';
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

String _satsangSessionLabel(SatsangSession session) {
  switch (session) {
    case SatsangSession.morning:
      return 'Morning';
    case SatsangSession.evening:
      return 'Evening';
    case SatsangSession.aarti:
      return 'Aarti';
  }
}

String _satsangSessionEyebrow(SatsangSession session) {
  switch (session) {
    case SatsangSession.morning:
      return 'Morning satsang';
    case SatsangSession.evening:
      return 'Evening satsang';
    case SatsangSession.aarti:
      return 'Aarti';
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
