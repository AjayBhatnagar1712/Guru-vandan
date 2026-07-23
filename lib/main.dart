import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  var firebaseReady = false;

  try {
    await Firebase.initializeApp(options: firebaseOptions);
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(GuruvandanApp(firebaseReady: firebaseReady));
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

enum SatsangSession { morning, evening }

enum RoutineTask { morningSatsang, eveningSatsang, meditation }

class SatsangTrack {
  const SatsangTrack({
    required this.id,
    required this.session,
    required this.title,
    required this.description,
    required this.durationLabel,
    this.audioUrl,
    this.active = true,
    this.createdAt,
  });

  final String id;
  final SatsangSession session;
  final String title;
  final String description;
  final String durationLabel;
  final String? audioUrl;
  final bool active;
  final int? createdAt;

  factory SatsangTrack.fromEntry(String id, Map<dynamic, dynamic> value) {
    return SatsangTrack(
      id: id,
      session: value['session'] == 'evening'
          ? SatsangSession.evening
          : SatsangSession.morning,
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
    title: 'Morning Aarti',
    description: 'Begin the day with a graceful devotional satsang.',
    durationLabel: '05:00',
  ),
  SatsangTrack(
    id: 'local-evening',
    session: SatsangSession.evening,
    title: 'Evening Aarti',
    description: 'Close the day with remembrance, gratitude, and peace.',
    durationLabel: '05:00',
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

class AuthGate extends StatelessWidget {
  const AuthGate({required this.firebaseReady, super.key});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return const DevoteeShell(firebaseReady: false);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            user == null) {
          return const Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: _SacredBackground()),
                SafeArea(child: _ProfileLoadingScreen()),
              ],
            ),
          );
        }

        if (user == null) {
          return const _SignInScreen();
        }

        return DevoteeShell(
          key: ValueKey('devotee-shell-${user.uid}'),
          firebaseReady: firebaseReady,
          user: user,
        );
      },
    );
  }
}

class _SignInScreen extends StatefulWidget {
  const _SignInScreen();

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
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (error) {
      _setError(error.message ?? 'Google sign-in failed.');
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
      _setError(error.message ?? 'Could not send OTP.');
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
      _setError(error.message ?? 'OTP verification failed.');
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

class _DevoteeShellState extends State<DevoteeShell> {
  static const routineKey = 'guruvandan_flutter:routine';
  static const nameKey = 'guruvandan_flutter:name';

  late final FirebaseContentService content;
  final satsangPlayer = AudioPlayer();
  final chantPlayer = AudioPlayer();

  PracticeTab tab = PracticeTab.home;
  SatsangSession selectedSession = _defaultSession();
  String devoteeName = '';
  bool localStateLoaded = false;
  bool needsFullName = false;
  Map<String, Map<String, bool>> records = {};
  String? activeTrackId;
  RoutineTask? activeTrackTask;
  Duration audioPosition = Duration.zero;
  Duration audioDuration = Duration.zero;

  int selectedMinutes = 10;
  int remainingSeconds = 600;
  bool meditationRunning = false;
  bool meditationComplete = false;
  Timer? meditationTimer;

  @override
  void initState() {
    super.initState();
    content = FirebaseContentService(widget.firebaseReady);
    _loadLocalState();
    _wireAudio();
  }

  @override
  void dispose() {
    meditationTimer?.cancel();
    satsangPlayer.dispose();
    chantPlayer.dispose();
    super.dispose();
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
  }

  String get _nameStorageKey =>
      widget.user == null ? nameKey : '$nameKey:${widget.user!.uid}';

  String get _routineStorageKey =>
      widget.user == null ? routineKey : '$routineKey:${widget.user!.uid}';

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_nameStorageKey) ??
        (widget.user == null ? null : prefs.getString(nameKey));
    final savedRecords = prefs.getString(_routineStorageKey) ??
        (widget.user == null ? null : prefs.getString(routineKey));

    if (savedName != null && savedName.trim().isNotEmpty) {
      devoteeName = savedName.trim();
    } else {
      needsFullName = true;
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
  }

  Future<void> _saveFullName(String name) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameStorageKey, clean);
    if (mounted) {
      setState(() {
        devoteeName = clean;
        needsFullName = false;
      });
    }
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
    setState(() {
      records.remove(todayKey);
      meditationComplete = false;
      meditationRunning = false;
      remainingSeconds = selectedMinutes * 60;
    });
    meditationTimer?.cancel();
    await _saveRecords();
  }

  Future<void> _signOut() async {
    meditationTimer?.cancel();
    await satsangPlayer.stop();
    await chantPlayer.stop();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _playSatsang(SatsangTrack track) async {
    final task = track.session == SatsangSession.morning
        ? RoutineTask.morningSatsang
        : RoutineTask.eveningSatsang;

    try {
      if (activeTrackId == track.id) {
        final state = satsangPlayer.state;
        if (state == PlayerState.playing) {
          await satsangPlayer.pause();
        } else {
          await satsangPlayer.resume();
        }
        setState(() {});
        return;
      }

      await satsangPlayer.stop();
      audioPosition = Duration.zero;
      audioDuration = Duration.zero;

      if (track.audioUrl != null && track.audioUrl!.isNotEmpty) {
        await satsangPlayer.play(UrlSource(track.audioUrl!));
      } else {
        await satsangPlayer.play(AssetSource('audio/satsang_sample.mp4'));
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

  void _setMeditationMinutes(int minutes) {
    meditationTimer?.cancel();
    setState(() {
      selectedMinutes = minutes;
      remainingSeconds = minutes * 60;
      meditationRunning = false;
      meditationComplete = false;
    });
  }

  void _toggleMeditation() {
    if (meditationRunning) {
      meditationTimer?.cancel();
      setState(() => meditationRunning = false);
      return;
    }

    if (remainingSeconds <= 0) {
      setState(() {
        remainingSeconds = selectedMinutes * 60;
        meditationComplete = false;
      });
    }

    meditationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds <= 1) {
        timer.cancel();
        await _markTask(RoutineTask.meditation);
        try {
          await chantPlayer.play(AssetSource('audio/satsang_sample.mp4'));
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Meditation completed. Chant audio could not be played.')),
            );
          }
        }
        if (mounted) {
          setState(() {
            remainingSeconds = 0;
            meditationRunning = false;
            meditationComplete = true;
          });
        }
        return;
      }

      if (mounted) {
        setState(() => remainingSeconds--);
      }
    });

    setState(() => meditationRunning = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!localStateLoaded || needsFullName) {
      return Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _SacredBackground()),
            SafeArea(
              child: !localStateLoaded
                  ? const _ProfileLoadingScreen()
                  : _FullNameOnboardingScreen(onContinue: _saveFullName),
            ),
          ],
        ),
      );
    }

    final screens = {
      PracticeTab.home: _HomeScreen(
        name: devoteeName,
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
        selectedMinutes: selectedMinutes,
        remainingSeconds: remainingSeconds,
        meditationRunning: meditationRunning,
        meditationComplete: meditationComplete,
        todayDone: today[RoutineTask.meditation.name] == true,
        onMinutesChanged: _setMeditationMinutes,
        onToggle: _toggleMeditation,
        onReset: () {
          meditationTimer?.cancel();
          setState(() {
            meditationRunning = false;
            meditationComplete = false;
            remainingSeconds = selectedMinutes * 60;
          });
        },
      ),
      PracticeTab.wisdom: _WisdomScreen(quotesStream: content.quotes()),
      PracticeTab.more: _MoreScreen(
        firebaseReady: widget.firebaseReady,
        user: widget.user,
        onSignOut: _signOut,
        onOpenAdmin: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminConsole(
                content: content, firebaseReady: widget.firebaseReady),
          ),
        ),
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

class _FullNameOnboardingScreen extends StatefulWidget {
  const _FullNameOnboardingScreen({required this.onContinue});

  final ValueChanged<String> onContinue;

  @override
  State<_FullNameOnboardingScreen> createState() =>
      _FullNameOnboardingScreenState();
}

class _FullNameOnboardingScreenState extends State<_FullNameOnboardingScreen> {
  final controller = TextEditingController();
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _continue() {
    final clean = controller.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 2) {
      setState(() => error = 'Please enter your full name.');
      return;
    }
    widget.onContinue(clean);
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
                  'Please enter your full name to begin your daily spiritual routine.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _continue(),
                  decoration: _inputDecoration('Full name').copyWith(
                    errorText: error,
                    prefixIcon: const Icon(Icons.person_rounded),
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
            _HeroPanel(name: name),
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
            _MilestonePanel(stats: stats),
          ],
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.name});

  final String name;

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
                    const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeroChip(
                            icon: Icons.wb_sunny_rounded,
                            label: 'Morning satsang'),
                        _HeroChip(
                            icon: Icons.self_improvement_rounded,
                            label: 'Dhyan'),
                        _HeroChip(
                            icon: Icons.nights_stay_rounded,
                            label: 'Evening satsang'),
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
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.offWhite.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.offWhite.withValues(alpha: 0.22)),
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

        return _PageScaffold(
          children: [
            const _ScreenTitle(
              icon: Icons.headphones_rounded,
              title: 'Satsang',
              subtitle: 'Morning and evening audio for steady daily devotion.',
            ),
            _SessionSwitch(
                selected: selectedSession, onChanged: onSessionChanged),
            ...tracks.map((track) {
              final task = track.session == SatsangSession.morning
                  ? RoutineTask.morningSatsang
                  : RoutineTask.eveningSatsang;
              final done = today[task.name] == true;
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
                onMark: () => onMark(task),
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
                      session == SatsangSession.morning
                          ? Icons.wb_sunny_rounded
                          : Icons.nights_stay_rounded,
                      size: 22,
                      color: active ? AppColors.cream : AppColors.maroon,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session == SatsangSession.morning ? 'Morning' : 'Evening',
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
    required this.onMark,
  });

  final SatsangTrack track;
  final bool done;
  final bool active;
  final bool playing;
  final double progress;
  final String position;
  final String duration;
  final VoidCallback onPlay;
  final VoidCallback onMark;

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
                  track.session == SatsangSession.morning
                      ? Icons.wb_sunny_rounded
                      : Icons.nights_stay_rounded,
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
                      track.session == SatsangSession.morning
                          ? 'Morning satsang'
                          : 'Evening satsang',
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
          ),
        ],
      ),
    );
  }
}

class _MeditationScreen extends StatelessWidget {
  const _MeditationScreen({
    required this.selectedMinutes,
    required this.remainingSeconds,
    required this.meditationRunning,
    required this.meditationComplete,
    required this.todayDone,
    required this.onMinutesChanged,
    required this.onToggle,
    required this.onReset,
  });

  final int selectedMinutes;
  final int remainingSeconds;
  final bool meditationRunning;
  final bool meditationComplete;
  final bool todayDone;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final progress = selectedMinutes == 0
        ? 0.0
        : 1 - remainingSeconds / (selectedMinutes * 60);

    return _PageScaffold(
      children: [
        const _ScreenTitle(
          icon: Icons.self_improvement_rounded,
          title: 'Meditation',
          subtitle: 'Settle into stillness. The session closes with a chant.',
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
                      painter:
                          _MeditationHaloPainter(active: meditationRunning),
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
                          Text(
                            _formatSeconds(remainingSeconds),
                            style: GoogleFonts.inter(
                              color: AppColors.maroon,
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            meditationRunning
                                ? 'Meditating'
                                : meditationComplete
                                    ? 'Complete'
                                    : 'Ready',
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
                children: [5, 10, 15, 20, 25, 30].map((minutes) {
                  final active = selectedMinutes == minutes;
                  return ChoiceChip(
                    label: Text('$minutes min'),
                    selected: active,
                    onSelected: (_) => onMinutesChanged(minutes),
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
                }).toList(),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onToggle,
                      icon: Icon(meditationRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded),
                      label: Text(meditationRunning ? 'Pause' : 'Start'),
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
    required this.firebaseReady,
    required this.user,
    required this.onSignOut,
    required this.onOpenAdmin,
  });

  final bool firebaseReady;
  final User? user;
  final VoidCallback onSignOut;
  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      children: [
        const _ScreenTitle(
          icon: Icons.tune_rounded,
          title: 'More',
          subtitle: 'Personal settings and admin tools.',
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
        Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(color: const Color(0xFFFFF8EF)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin content',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                firebaseReady
                    ? 'Firebase is connected. Admin can upload satsang audio and publish quotes.'
                    : 'Firebase is not connected yet. The app is using bundled fallback content.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onOpenAdmin,
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: const Text('Open admin console'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
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
  final minutes = (safe ~/ 60).toString().padLeft(2, '0');
  final seconds = (safe % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
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

String _audioContentType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.m4a')) return 'audio/mp4';
  if (lower.endsWith('.aac')) return 'audio/aac';
  if (lower.endsWith('.wav')) return 'audio/wav';
  if (lower.endsWith('.mp4')) return 'audio/mp4';
  return 'audio/mpeg';
}
