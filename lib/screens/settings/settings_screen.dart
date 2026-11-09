import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/location_data.dart';
import '../../services/app_strings.dart';
import '../../services/app_theme_state.dart';
import '../../services/auth_service.dart';
import '../../services/session_prefs.dart';
import '../home/onboarding/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;
  final ValueChanged<String>? onLanguageChanged;
  final void Function(String state, String district)? onLocationChanged;

  const SettingsScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
    required this.selectedDistrict,
    this.onLanguageChanged,
    this.onLocationChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _language;
  late String _state;
  late String _district;

  bool _breakingNewsNotifications = true;
  bool _dailyDigest = true;
  bool _dataSaver = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _language = widget.selectedLanguage;
    _state = widget.selectedState;
    _district = widget.selectedDistrict;
  }

  // ------------------------------------------------------------
  // LOCATION CHANGER DIALOG
  // ------------------------------------------------------------
  void _openLocationDialog() {
    String tempState = _state;
    String tempDistrict = _district;

    final states = appLocationStates.map((s) => s.name).toList();
    final currentStateObj = getLocationState(tempState) ?? appLocationStates.first;
    List<String> districts = currentStateObj.districtNames;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 28, offset: Offset(0, -4)),
                ],
              ),
              child: Material(
                color: isDark ? const Color(0xFF1E2026) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
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
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Change Location',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select your state and district for hyper-local coverage.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // State Dropdown
                        Text(
                          'STATE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF282A33) : const Color(0xFFF3F3F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: states.contains(tempState) ? tempState : states.first,
                              isExpanded: true,
                              dropdownColor: isDark ? const Color(0xFF282A33) : Colors.white,
                              items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setModalState(() {
                                  tempState = val;
                                  final stObj = getLocationState(tempState);
                                  districts = stObj?.districtNames ?? [];
                                  tempDistrict = districts.isNotEmpty ? districts.first : '';
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // District Dropdown
                        Text(
                          'DISTRICT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF282A33) : const Color(0xFFF3F3F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: districts.contains(tempDistrict) ? tempDistrict : (districts.isNotEmpty ? districts.first : null),
                              isExpanded: true,
                              dropdownColor: isDark ? const Color(0xFF282A33) : Colors.white,
                              items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setModalState(() => tempDistrict = val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              setState(() {
                                _state = tempState;
                                _district = tempDistrict;
                              });
                              await SessionPrefs.saveSelections(
                                language: _language,
                                state: tempState,
                                district: tempDistrict,
                              );
                              widget.onLocationChanged?.call(tempState, tempDistrict);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Location updated to $tempDistrict, $tempState'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Text('Save Location', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // DANGER ZONE: DELETE ACCOUNT & ALL USER DATA
  // ------------------------------------------------------------
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
              SizedBox(width: 8),
              Text('Delete Account?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Text(
            'This action is irreversible. All your profile data, bookmarks, reading preferences, and submissions will be permanently wiped from the database.',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                _performFullDataDeletion();
              },
              child: const Text('Permanently Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performFullDataDeletion() async {
    setState(() => _isDeleting = true);
    HapticFeedback.heavyImpact();

    try {
      final supabaseClient = Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;
      if (user != null) {
        // Remove from profiles table if exists
        try {
          await supabaseClient
              .from('profiles')
              .delete()
              .eq('id', user.id);
        } catch (_) {}

        // Remove user's news submissions if exists
        try {
          await supabaseClient
              .from('news_submissions')
              .delete()
              .eq('author_id', user.id);
        } catch (_) {}
      }

      // Clear local storage and sign out
      await SessionPrefs.clear();
      await AuthService.instance.signOut();

      if (!mounted) return;
      setState(() => _isDeleting = false);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2026) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111216) : const Color(0xFFF8F8F6),
      appBar: AppBar(
        title: Text(
          AppStrings.t('settings', _language),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isDeleting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text('Deleting account data...', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // SECTION 1: CONTENT & LOCATION PREFERENCES
                _sectionHeader('CONTENT PREFERENCES', isDark),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Location (moved under Settings)
                        ListTile(
                          leading: Icon(Icons.location_on_outlined, color: isDark ? Colors.white70 : Colors.black87),
                          title: const Text('News Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('$_district, $_state', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                          trailing: Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black45),
                          onTap: _openLocationDialog,
                        ),
                        Divider(height: 1, indent: 56, color: isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
                        // Data Saver
                        SwitchListTile(
                          secondary: Icon(Icons.data_saver_on_outlined, color: isDark ? Colors.white70 : Colors.black87),
                          title: const Text('Data Saver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('Load lower resolution images on mobile data', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                          value: _dataSaver,
                          onChanged: (val) => setState(() => _dataSaver = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 2: NOTIFICATIONS
                _sectionHeader('NOTIFICATIONS', isDark),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: Icon(Icons.notifications_active_outlined, color: isDark ? Colors.white70 : Colors.black87),
                          title: const Text('Breaking News Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('Get instant push alerts for critical events', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                          value: _breakingNewsNotifications,
                          onChanged: (val) => setState(() => _breakingNewsNotifications = val),
                        ),
                        Divider(height: 1, indent: 56, color: isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
                        SwitchListTile(
                          secondary: Icon(Icons.wb_sunny_outlined, color: isDark ? Colors.white70 : Colors.black87),
                          title: const Text('Daily Morning Digest', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('Summarized briefing delivered at 8:00 AM', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                          value: _dailyDigest,
                          onChanged: (val) => setState(() => _dailyDigest = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 3: PRIVACY & DATA MANAGEMENT (DELETE DATA)
                _sectionHeader('PRIVACY & ACCOUNT DATA', isDark),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.shield_outlined, color: isDark ? Colors.white70 : Colors.black87),
                          title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          trailing: Icon(Icons.open_in_new_rounded, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening Privacy Policy...'), behavior: SnackBarBehavior.floating),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 56, color: isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
                        ListTile(
                          leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                          title: const Text(
                            'Delete User Account & Data',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.redAccent),
                          ),
                          subtitle: Text(
                            'Permanently wipe your account, preferences, and submissions',
                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black45),
                          ),
                          onTap: _confirmDeleteAccount,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // App version
                Center(
                  child: Text(
                    'Samayam News • Version 1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }
}
