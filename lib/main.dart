import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase_config.dart';
import 'services/session_prefs.dart';
import 'services/app_theme_state.dart';
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
  await StoryTimelineService.instance.load();

  runApp(const ProviderScope(child: NewsApp()));
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
          title: 'News App',
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

    if (session == null) {
      return const WelcomeScreen();
    }

    // Check if the logged-in user is an editor (e.g., via user_metadata or profiles table)
    final user = session.user;
    final role = user.userMetadata?['role'] ?? user.appMetadata['role'];
    
    // Alternatively, fetch from your profiles table if role is stored there:
    // final profile = await supabase.from('profiles').select('role').eq('id', user.id).maybeSingle();
    // final isEditor = profile?['role'] == 'editor';

    if (role == 'editor') {
      return const EditorDashboardScreen();
    }

    // Otherwise, normal reader flow
    final selections = await SessionPrefs.loadSelections();
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
          return const Scaffold(
            backgroundColor: Color(0xFFF8F8F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }
}