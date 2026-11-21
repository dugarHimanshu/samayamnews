import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW: needed to check login state for Fill Form

import '../../widgets/home/glass_header.dart';
import '../../widgets/home/news_bottom_navigation.dart';
import '../../services/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/session_prefs.dart';

import '../home/news_home_screen.dart';
import '../category/category_screen.dart';
import '../search/search_screen.dart';
import '../home/onboarding/welcome_screen.dart';
import '../location/location_screen.dart';
import '../saved/saved_screen.dart';
import '../contributor/contributor_gate.dart'; // decides form vs. registration
import '../contributor/reporter_registration_screen.dart';
import '../magazine/magazine_list_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/app_theme_state.dart';
import '../../utils/display_formatters.dart';

class MainShell extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;

  const MainShell({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
    required this.selectedDistrict,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final PageController _pageController;

  late String _currentLanguage;
  late String _currentState;
  late String _currentDistrict;

  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _chromeVisible = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.selectedLanguage;
    _currentState = widget.selectedState;
    _currentDistrict = widget.selectedDistrict;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    _chromeVisible.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // CHROME VISIBILITY
  // ------------------------------------------------------------

  void _setChromeVisible(bool visible) {
    if (_chromeVisible.value == visible) return;
    _chromeVisible.value = visible; // Updates without rebuilding MainShell
  }

  // ------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ------------------------------------------------------------

  void _onNavigationChanged(int index) {
    if (index == _currentIndex.value) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(
        milliseconds: 350,
      ), // Slightly longer for smoother feel
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (_currentIndex.value == index) return;

    _currentIndex.value = index; // Updates Nav bar without rebuilding MainShell
    _chromeVisible.value = true;
  }

  // ------------------------------------------------------------
  // MENU & PROFILE
  // ------------------------------------------------------------

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x2E000000), // Black 0.18
      elevation: 0,
      isScrollControlled: true,
      builder: (context) {
        return _MenuSheet(
          selectedLanguage: _currentLanguage,
          selectedState: _currentState,
          selectedDistrict: _currentDistrict,
          onLanguageChanged: (newLang) {
            setState(() => _currentLanguage = newLang);
          },
          onLocationChanged: (newState, newDistrict) {
            setState(() {
              _currentState = newState;
              _currentDistrict = newDistrict;
            });
          },
        );
      },
    );
  }

  void _openProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x2E000000), // Black 0.18
      elevation: 0,
      isScrollControlled: true,
      builder: (context) {
        return _ProfileSheet(language: _currentLanguage);
      },
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Because we removed setState, this Scaffold only builds ONCE.
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ------------------------------------------------------
          // MAIN PAGES
          // ------------------------------------------------------
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              RepaintBoundary(
                child: NewsHomeScreen(
                  key: ValueKey('home_${_currentLanguage}_${_currentState}_$_currentDistrict'),
                  selectedLanguage: _currentLanguage,
                  selectedState: _currentState,
                  selectedDistrict: _currentDistrict,
                  onChromeVisibilityChanged: _setChromeVisible,
                ),
              ),
              RepaintBoundary(
                child: CategoryScreen(
                  key: ValueKey('category_$_currentLanguage'),
                  selectedLanguage: _currentLanguage,
                  selectedState: _currentState,
                  selectedDistrict: _currentDistrict,
                ),
              ),
              RepaintBoundary(
                child: LocationScreen(
                  key: ValueKey('loc_${_currentState}_$_currentDistrict'),
                  selectedLanguage: _currentLanguage,
                  selectedState: _currentState,
                  selectedDistrict: _currentDistrict,
                ),
              ),
              RepaintBoundary(
                child: SearchScreen(
                  key: ValueKey('search_$_currentLanguage'),
                  selectedLanguage: _currentLanguage,
                  selectedState: _currentState,
                  selectedDistrict: _currentDistrict,
                ),
              ),
              RepaintBoundary(
                child: SavedScreen(
                  key: ValueKey('saved_$_currentLanguage'),
                  selectedLanguage: _currentLanguage,
                  selectedState: _currentState,
                  selectedDistrict: _currentDistrict,
                ),
              ),
            ],
          ),

          // ------------------------------------------------------
          // SHARED GLASS HEADER
          // ------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _chromeVisible,
              builder: (context, isVisible, child) {
                return IgnorePointer(
                  ignoring: !isVisible,
                  child: AnimatedSlide(
                    offset: isVisible ? Offset.zero : const Offset(0, -1.15),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: child,
                    ),
                  ),
                );
              },
              // 3. CACHE THE BLUR
              child: RepaintBoundary(
                child: GlassHeader(
                  visible: true,
                  onMenuTap: _openMenu,
                  onProfileTap: _openProfile,
                ),
              ),
            ),
          ),

          // ------------------------------------------------------
          // SHARED BOTTOM NAVIGATION
          // ------------------------------------------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _chromeVisible,
              builder: (context, isVisible, childNav) {
                return IgnorePointer(
                  ignoring: !isVisible,
                  child: AnimatedSlide(
                    offset: isVisible ? Offset.zero : const Offset(0, 1.15),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: childNav,
                    ),
                  ),
                );
              },
              child: RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentIndex,
                  builder: (context, index, _) {
                    return NewsBottomNavigation(
                      currentIndex: index,
                      onItemSelected: _onNavigationChanged,
                      language: _currentLanguage,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MENU SHEET (Optimized with Const Colors)
// ============================================================================

class _MenuSheet extends StatelessWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;
  final ValueChanged<String>? onLanguageChanged;
  final void Function(String state, String district)? onLocationChanged;

  const _MenuSheet({
    required this.selectedLanguage,
    required this.selectedState,
    required this.selectedDistrict,
    this.onLanguageChanged,
    this.onLocationChanged,
  });

  // NEW: Fill Form tap handler.
  // Guests (no logged-in Supabase user) get sent to WelcomeScreen to log in.
  // Logged-in users get sent to the submission form.
  void _onFillFormTap(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final nav = Navigator.of(context);

    // Close the menu sheet first
    Navigator.pop(context);

    if (user == null) {
      // Guest — not logged in, send them to login instead of the form
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    // Logged in — reporters/freelancers get the form; readers are offered registration.
    openNewsroom(nav);
  }

  // Language selection modal (English, Hindi, Telugu)
  void _showLanguagePicker(BuildContext context) {
    NeatLanguagePickerSheet.show(
      context,
      currentLanguage: selectedLanguage,
      onSelected: (l) async {
        Navigator.pop(context); // close menu
        onLanguageChanged?.call(l);
        await SessionPrefs.saveSelections(
          language: l,
          state: selectedState,
          district: selectedDistrict,
        );
      },
    );
  }

  // Theme selection modal
  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2026) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'App Theme',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.light_mode_outlined),
                  title: const Text('Light Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: AppThemeState.instance.themeMode == ThemeMode.light
                      ? const Icon(Icons.check_circle_rounded, color: Colors.black)
                      : null,
                  onTap: () {
                    AppThemeState.instance.setThemeMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: AppThemeState.instance.themeMode == ThemeMode.dark
                      ? const Icon(Icons.check_circle_rounded, color: Colors.white)
                      : null,
                  onTap: () {
                    AppThemeState.instance.setThemeMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_auto_outlined),
                  title: const Text('System Default', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: AppThemeState.instance.themeMode == ThemeMode.system
                      ? const Icon(Icons.check_circle_rounded)
                      : null,
                  onTap: () {
                    AppThemeState.instance.setThemeMode(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = Supabase.instance.client.auth.currentUser == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2026) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // Black 0.10
              blurRadius: 30,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.close_rounded, size: 22),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 1) Theme option (Renamed from dark mode to Theme)
            _MenuItem(
              icon: Icons.palette_outlined,
              title: AppStrings.t('theme', selectedLanguage),
              trailing: AppThemeState.instance.isDarkMode ? 'Dark' : 'Light',
              onTap: () => _showThemePicker(context),
            ),

            // 2) Language (English, Hindi, Telugu)
            _MenuItem(
              icon: Icons.language_outlined,
              title: AppStrings.t('language', selectedLanguage),
              trailingWidget: LanguagePill(language: selectedLanguage),
              onTap: () => _showLanguagePicker(context),
            ),

            // 5) Magazine
            _MenuItem(
              icon: Icons.auto_stories_outlined,
              title: AppStrings.t('magazine', selectedLanguage),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 320),
                    reverseTransitionDuration: const Duration(milliseconds: 250),
                    pageBuilder: (_, _, _) => MagazineListScreen(
                      selectedLanguage: selectedLanguage,
                    ),
                    transitionsBuilder: (_, animation, _, child) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(curved),
                          child: child,
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // 6) Fill Form (unchanged)
            _MenuItem(
              icon: Icons.edit_note_rounded,
              title: 'Fill Form',
              showLock: isGuest,
              onTap: () => _onFillFormTap(context),
            ),

            // 6b) Reporter / Freelancer registration (open to everyone)
            _MenuItem(
              icon: Icons.how_to_reg_rounded,
              title: 'Reporter Registration',
              onTap: () {
                final nav = Navigator.of(context);
                Navigator.pop(context);
                nav.push(MaterialPageRoute(builder: (_) => const ReporterRegistrationScreen()));
              },
            ),

            // 7) Settings (now contains Location & Account Deletion)
            _MenuItem(
              icon: Icons.settings_outlined,
              title: AppStrings.t('settings', selectedLanguage),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      selectedLanguage: selectedLanguage,
                      selectedState: selectedState,
                      selectedDistrict: selectedDistrict,
                      onLanguageChanged: onLanguageChanged,
                      onLocationChanged: onLocationChanged,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MENU ITEM
// ============================================================================

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Widget? trailingWidget;
  final bool
  showLock; // NEW: when true, shows a small lock icon instead of the chevron
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.trailingWidget,
    this.showLock = false, // NEW
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0x0C000000), // Black 0.045
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 20, color: Colors.black87),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (trailingWidget != null)
                  trailingWidget!
                else if (trailing != null)
                  Flexible(
                    child: Text(
                      trailing!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                    ),
                  )
                else if (showLock) // NEW: guest-locked state
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: Colors.black38,
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.black38,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE SHEET
// ============================================================================

class _ProfileSheet extends StatefulWidget {
  final String language;

  const _ProfileSheet({required this.language});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  String _profileName = 'Becho test app';

  void _editProfileName() {
    final controller = TextEditingController(text: _profileName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.black12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  setState(() {
                    _profileName = name;
                  });
                }

                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      controller.dispose();
    });
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be available soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _profileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0x0C000000),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 20, color: Colors.black87),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    Navigator.pop(context);

    await AuthService.instance.signOut();

    await SessionPrefs.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 30,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 20),

            // Profile avatar
            GestureDetector(
              onTap: _editProfileName,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x0E000000),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Colors.black45,
                    ),
                  ),

                  // Edit badge
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Text(
              AppStrings.t('your_profile', widget.language),
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              _profileName,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),

            const SizedBox(height: 18),

            // Edit profile
            _profileOption(
              icon: Icons.edit_outlined,
              title: 'Edit profile',
              subtitle: 'Change your profile name',
              onTap: _editProfileName,
            ),

            // Language
            _profileOption(
              icon: Icons.language_outlined,
              title: AppStrings.t('language', widget.language),
              subtitle: DisplayFormatters.languageDisplayName(widget.language),
              onTap: () {
                NeatLanguagePickerSheet.show(
                  context,
                  currentLanguage: widget.language,
                  onSelected: (l) async {
                    await SessionPrefs.saveLanguage(l);
                  },
                );
              },
            ),

            // Settings
            _profileOption(
              icon: Icons.settings_outlined,
              title: AppStrings.t('settings', widget.language),
              subtitle: 'App preferences',
              onTap: () {
                _showComingSoon('Settings');
              },
            ),

            const SizedBox(height: 10),

            // Divider
            Container(height: 1, color: const Color(0xFFEDEDED)),

            const SizedBox(height: 16),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.t('log_out', widget.language),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
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
}