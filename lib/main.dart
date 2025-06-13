import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';

import 'login.dart';
import 'register.dart';
import 'forgotpass.dart';
import 'streak.dart' as streak;
import 'treatment.dart';
import 'profile.dart';
import 'change_password_page.dart';
import 'moodtracker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://ozcufbeakqzuuvfzxvsy.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im96Y3VmYmVha3F6dXV2Znp4dnN5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczMjE0OTUsImV4cCI6MjA2Mjg5NzQ5NX0.EziDZgfKIqpZsl-nfldR11APjkDaiCdC6nJlHrvFT38',
    );
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _listenToDeepLinks();
    }
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.pushNamed('/change-password');
      }
    });
  }

  void _listenToDeepLinks() async {
    // Listen for incoming deep links while app is running
    _linkSub = uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;

      debugPrint('Received deep link: $uri');

      if (uri.scheme == 'io.supabase.serenemind' && uri.host == 'login-callback') {
        final accessToken = uri.queryParameters['access_token'];
        final refreshToken = uri.queryParameters['refresh_token'];

        if (accessToken != null && refreshToken != null) {
          try {
            final auth = Supabase.instance.client.auth;
            final response = await auth.setSession(accessToken);
            final session = response.session;

            if (session != null) {
              final email = session.user.email ?? '';
              final userId = session.user.id;
              _navigatorKey.currentState?.pushNamed(
                '/home',
                arguments: {'email': email, 'userId': userId},
              );
            } else {
              _navigatorKey.currentState?.pushNamed('/login');
            }
          } catch (e) {
            debugPrint('Magic link login error: $e');
            _navigatorKey.currentState?.pushNamed('/login');
          }
        }
      }
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });

    // Handle initial deep link when app is launched via a link
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        debugPrint('App launched with initial URI: $initialUri');

        if (initialUri.scheme == 'io.supabase.serenemind' &&
            initialUri.host == 'login-callback') {
          final accessToken = initialUri.queryParameters['access_token'];
          final refreshToken = initialUri.queryParameters['refresh_token'];

          if (accessToken != null && refreshToken != null) {
            final auth = Supabase.instance.client.auth;
            final response = await auth.setSession(accessToken);
            final session = response.session;

            if (session != null) {
              final email = session.user.email ?? '';
              final userId = session.user.id;
              _navigatorKey.currentState?.pushNamed(
                '/home',
                arguments: {'email': email, 'userId': userId},
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to handle initial URI: $e');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SereneMind App',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterPage());
          case '/forgotpass':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
          case '/change-password':
            return MaterialPageRoute(builder: (_) => const ChangePasswordPage());
          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomePage(
                userEmail: args?['email'] ?? '',
                userId: args?['userId'] ?? '',
              ),
            );
          case '/treatment':
            return MaterialPageRoute(
              builder: (_) => TreatmentPage(
                userEmail: args?['email'] ?? '',
                userId: args?['userId'] ?? '',
                recommendedTreatments: args?['recommendedTreatments'] ?? [],
                mood: args?['mood'] ?? '',
                treatments: [],
                currentStreak: args?['streakCount'] ?? 0,
              ),
            );
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfilePage());
          case '/moodtracker':
            return MaterialPageRoute(
              builder: (_) => MoodTrackerPage(
                userEmail: args?['email'] ?? '',
                userId: args?['userId'] ?? '',
              ),
            );
          case '/streak':
            return MaterialPageRoute(builder: (_) => streak.StreakPopup(
                streakCount: args?['streakCount'] ?? 0
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }
}  