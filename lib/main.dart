import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase_config.dart';
import 'services/session_prefs.dart';
import 'services/app_theme_state.dart';
import 'services/auth_service.dart';
import 'services/category_repository.dart';
import 'services/location_repository.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'services/story_timeline_service.dart';
import 'screens/home/onboarding/welcome_screen.dart';
import 'screens/main/main_shell.dart';
import 'screens/editor/editor_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  await AppThemeState.instance.loadTheme();

  // Draw the first screen right away; reference data loads in the background
  // (screens that need it await the same shared request).
  runApp(const ProviderScope(child: NewsApp()));

  unawaited(StoryTimelineService.instance.load());
  unawaited(LocationRepository.instance.init().catchError((Object e) => debugPrint('Locations not loaded: $e')));
  unawaited(CategoryRepository.instance.init().catchError((Object e) => debugPrint('Categories not loaded: $e')));
}

final supabase = Supabase.instance.client;

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeState.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Samayam News',
          themeMode: AppThemeState.instance.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F8F6),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF111111),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.interTextTheme(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF111216),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE5A93B),
              brightness: Brightness.dark,
              surface: const Color(0xFF1A1C23),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

// Decides where the app opens: straight into MainShell if the user
// is already logged in AND has completed onboarding before, or the
// normal WelcomeScreen flow otherwise.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> _startScreen;

  @override
  void initState() {
    super.initState();
    _startScreen = _resolveStartScreen();
  }

 Future<Widget> _resolveStartScreen() async {
    final session = supabase.auth.currentSession;
    final selections = await SessionPrefs.loadSelections();

    if (session == null) {
      // Guests who already chose language/state/district go straight to the news.
      if (selections != null) {
        return MainShell(
          selectedLanguage: selections['language']!,
          selectedState: selections['state']!,
          selectedDistrict: selections['district']!,
        );
      }
      return const WelcomeScreen();
    }

    // Role comes from the API (app.profiles), never from editable user metadata.
    // The last known role is used straight away (no waiting on the network at launch)
    // and refreshed in the background; the API still enforces permissions.
    String? role = await SessionPrefs.cachedRole(session.user.id);
    final fresh = AuthService.instance.getCurrentUserRole().then((r) async {
      await SessionPrefs.cacheRole(session.user.id, r);
      return r;
    });
    if (role == null) {
      try {
        role = await fresh.timeout(const Duration(seconds: 12));
      } catch (_) {
        role = null; // offline or API down: fall through to the reader flow
      }
    } else {
      unawaited(fresh.catchError((_) => null));
    }

    if (role == 'admin') {
      return const AdminDashboardScreen();
    }
    if (role == 'editor') {
      return const EditorDashboardScreen();
    }

    // Otherwise, normal reader flow
    if (selections == null) {
      return const WelcomeScreen();
    }

    return MainShell(
      selectedLanguage: selections['language']!,
      selectedState: selections['state']!,
      selectedDistrict: selections['district']!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startScreen,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Brief loading state while we check the session — shows
          // for a split second on app launch.
          return const AppSplash();
        }
        return snapshot.data!;
      },
    );
  }
}

/// First screen: app logo and name only.
class AppSplash extends StatelessWidget {
  const AppSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/public/images/app_logo.png', width: 150, height: 150),
            const SizedBox(height: 18),
            const Text(
              'సమయం న్యూస్',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 4),
            const Text(
              'SAMAYAM NEWS',
              style: TextStyle(fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700, color: Color(0xFFC62828)),
            ),
          ],
        ),
      ),
    );
  }
}
