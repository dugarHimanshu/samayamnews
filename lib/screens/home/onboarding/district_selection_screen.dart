import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/location_data.dart';
import '../../main/main_shell.dart';
import '../../../services/session_prefs.dart';
import '../../../services/app_strings.dart';
import '../../../services/place_translations.dart';
import '../../../services/translation_service.dart';

class DistrictSelectionScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;

  const DistrictSelectionScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
  });

  @override
  State<DistrictSelectionScreen> createState() =>
      _DistrictSelectionScreenState();
}

class _DistrictSelectionScreenState extends State<DistrictSelectionScreen>
    with SingleTickerProviderStateMixin {
  // Maps our app's language ids to the ISO codes TranslationService expects.
  static const Map<String, String> _isoCodes = {'hindi': 'hi', 'telugu': 'te'};

  // 1. ValueNotifier prevents full-screen rebuilds when selecting a district
  final ValueNotifier<String?> _selectedDistrictNotifier = ValueNotifier(null);
  final TextEditingController _searchController = TextEditingController();

  // Caches English district name -> translated name, so both the
  // display AND the search box can use the translated text without
  // re-translating on every keystroke.
  final Map<String, String> _translatedDistricts = {};
  bool _isTranslatingDistricts = false;

  late final AnimationController _auroraController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat(reverse: true);

  List<String> get _districts {
    return getDistrictsForState(widget.selectedState);
  }

  @override
  void initState() {
    super.initState();
    _loadTranslatedDistricts();
  }

  // Translates every district name for this state up front, once,
  // instead of per-card — this is what lets search work correctly
  // in Hindi/Telugu (it can check the cached translated text), and
  // avoids a flicker-per-card as each one resolves independently.
  Future<void> _loadTranslatedDistricts() async {
    final isoCode = _isoCodes[widget.selectedLanguage];

    if (isoCode == null) {
      // English selected — nothing to translate.
      return;
    }

    setState(() => _isTranslatingDistricts = true);

    final entries = await Future.wait(
      _districts.map((district) async {
        try {
          final translated = await TranslationService.instance.translate(
            text: district,
            targetLanguage: isoCode,
          );
          return MapEntry(district, translated);
        } catch (_) {
          // Translation failed for this one — just fall back to English.
          return MapEntry(district, district);
        }
      }),
    );

    if (!mounted) return;

    setState(() {
      _translatedDistricts
        ..clear()
        ..addEntries(entries);
      _isTranslatingDistricts = false;
    });
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _selectedDistrictNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _continue() {
    final selectedDistrict = _selectedDistrictNotifier.value;

    if (selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0x1FFFFFFF), // White 0.12
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.t('select_district_first', widget.selectedLanguage),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(18),
          backgroundColor: const Color(0xFF171717),
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
      return;
    }

    SessionPrefs.saveSelections(
      language: widget.selectedLanguage,
      state: widget.selectedState,
      district: selectedDistrict,
    );

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) {
          return MainShell(
            selectedLanguage: widget.selectedLanguage,
            selectedState: widget.selectedState,
            selectedDistrict: selectedDistrict,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F6),
      body: Stack(
        children: [
          // ============================================================
          // AURORA BACKGROUND (Isolated with RepaintBoundary)
          // ============================================================
          RepaintBoundary(
            child: Positioned.fill(
              child: AnimatedBuilder(
                animation: _auroraController,
                builder: (context, child) {
                  final value = _auroraController.value;
                  return Stack(
                    children: [
                      Positioned(
                        top: -130 + (value * 40),
                        right: -110,
                        child: const _AuroraBlob(
                          size: 350,
                          color: Color(0x40D7C2FF),
                        ),
                      ),
                      Positioned(
                        top: 180 - (value * 45),
                        left: -160,
                        child: const _AuroraBlob(
                          size: 320,
                          color: Color(0x38B9E9FF),
                        ),
                      ),
                      Positioned(
                        bottom: -150 + (value * 55),
                        right: -90,
                        child: const _AuroraBlob(
                          size: 350,
                          color: Color(0x35DEC68B),
                        ),
                      ),
                      Positioned(
                        bottom: 120,
                        left: -120,
                        child: const _AuroraBlob(
                          size: 250,
                          color: Color(0x28EAC7DD),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // STATIC WHITE OVERLAY (Using const Hex colors)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD9FFFFFF),
                    Color(0x91FFFFFF),
                    Color(0xE6F8F8F6),
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // MAIN CONTENT (Optimized with Slivers for fast scrolling)
          // ============================================================
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildTopBar(),
                            const SizedBox(height: 27),
                            _buildProgress(),
                            const SizedBox(height: 31),
                            _buildHeroHeader(),
                            const SizedBox(height: 25),
                            _buildContextCard(),
                            const SizedBox(height: 27),
                            _buildSectionHeader(),
                            const SizedBox(height: 10),
                            _buildSearchBar(),
                            if (_isTranslatingDistricts) ...[
                              const SizedBox(height: 10),
                              _buildTranslatingHint(),
                            ],
                            const SizedBox(height: 13),
                          ]),
                        ),
                      ),

                      // Districts list, filtered live by the search box.
                      // Only rebuilds when the search text changes.
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, search, _) {
                          final query = search.text.trim().toLowerCase();
                          final filteredDistricts = query.isEmpty
                              ? _districts
                              : _districts.where((d) {
                                  final translated =
                                      (_translatedDistricts[d] ?? '')
                                          .toLowerCase();
                                  return d.toLowerCase().contains(query) ||
                                      translated.contains(query);
                                }).toList();

                          if (_districts.isEmpty) {
                            // No districts exist at all for this state.
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                ),
                                child: _buildEmptyState(isSearching: false),
                              ),
                            );
                          }

                          if (filteredDistricts.isEmpty) {
                            // Districts exist, but none match the search.
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                ),
                                child: _buildEmptyState(isSearching: true),
                              ),
                            );
                          }

                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final district = filteredDistricts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ValueListenableBuilder<String?>(
                                    valueListenable: _selectedDistrictNotifier,
                                    builder: (context, selected, _) {
                                      return _BouncyDistrictCard(
                                        district: district,
                                        displayText:
                                            _translatedDistricts[district] ??
                                            district,
                                        isSelected: selected == district,
                                        language: widget.selectedLanguage,
                                        onTap: () {
                                          _selectedDistrictNotifier.value =
                                              district;
                                        },
                                      );
                                    },
                                  ),
                                );
                              }, childCount: filteredDistricts.length),
                            ),
                          );
                        },
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),

                // ============================================================
                // REACT-STYLE CONTINUE BUTTON
                // ============================================================
                _buildBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0x9EFFFFFF), // White 0.62
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xE6FFFFFF),
                  ), // White 0.9
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0E000000), // Black 0.055
                      blurRadius: 16,
                      offset: Offset(2, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0x94FFFFFF), // White 0.58
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xE6FFFFFF)), // White 0.9
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: Color(0xFFB18A48),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '03 / 03',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Row(
      children: const [
        Expanded(child: _PremiumProgress(active: true)),
        SizedBox(width: 7),
        Expanded(child: _PremiumProgress(active: true)),
        SizedBox(width: 7),
        Expanded(child: _PremiumProgress(active: true)),
      ],
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB58A3A), Color(0xFFE5C98A)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              AppStrings.t('final_step', widget.selectedLanguage),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: const Color(0xFFB18A48),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        Text(
          AppStrings.t('your_local', widget.selectedLanguage),
          style: GoogleFonts.playfairDisplay(
            fontSize: 42,
            height: 0.98,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF151515),
          ),
        ),
        Text(
          AppStrings.t('news_starts_here', widget.selectedLanguage),
          style: GoogleFonts.playfairDisplay(
            fontSize: 42,
            height: 1.05,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF151515),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          AppStrings.t('district_subtitle', widget.selectedLanguage),
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.6,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
      ],
    );
  }

  Widget _buildContextCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0x99FFFFFF), // White 0.60
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xE6FFFFFF)), // White 0.9
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000000), // Black 0.045
                blurRadius: 25,
                offset: Offset(0, 11),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFEDEDE8)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000), // Black 0.06
                      blurRadius: 12,
                      offset: Offset(3, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFB18A48),
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('your_location', widget.selectedLanguage),
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: const Color(0xFF9A9A9A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PlaceTranslations.stateName(
                        widget.selectedState,
                        widget.selectedLanguage,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF202020),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F0EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: Color(0xFFB18A48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Text(
          '01',
          style: GoogleFonts.playfairDisplay(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB18A48),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          AppStrings.t('select_district', widget.selectedLanguage),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: const Color(0xFF777777),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: const Color(0xFFE2E2DD))),
      ],
    );
  }

  // Small caption shown under the search bar while districts are
  // still being translated in the background.
  Widget _buildTranslatingHint() {
    return Row(
      children: [
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        ),
        const SizedBox(width: 8),
        Text(
          AppStrings.t('translating_districts', widget.selectedLanguage),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x9EFFFFFF), // White 0.62
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xE6FFFFFF)), // White 0.9
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000000), // Black 0.045
                blurRadius: 25,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) {
              return TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF222222),
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.t(
                    'search_district_hint',
                    widget.selectedLanguage,
                  ),
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF999999),
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F1ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: Color(0xFF666666),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 54,
                    minHeight: 54,
                  ),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          onPressed: () => _searchController.clear(),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF777777),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 18,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isSearching}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x8CFFFFFF), // White 0.55
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xE6FFFFFF)), // White 0.9
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 36,
            color: Color(0xFFAAAAAA),
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? AppStrings.t('no_district_found', widget.selectedLanguage)
                : AppStrings.t(
                    'no_districts_available',
                    widget.selectedLanguage,
                  ),
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isSearching) ...[
            const SizedBox(height: 5),
            Text(
              AppStrings.t('try_another_search', widget.selectedLanguage),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF888888),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      decoration: const BoxDecoration(
        color: Color(0xEFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0E000000), // Black 0.055
            blurRadius: 25,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<String?>(
          valueListenable: _selectedDistrictNotifier,
          builder: (context, selectedDistrict, _) {
            return _LuxuryContinueButton(
              isActive: selectedDistrict != null,
              onPressed: _continue,
              language: widget.selectedLanguage,
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// BOUNCY DISTRICT CARD (No BackdropFilter = 120 FPS!)
// ============================================================

class _BouncyDistrictCard extends StatefulWidget {
  final String district; // canonical English name (used for selection)
  final String displayText; // translated name, or English if no translation
  final bool isSelected;
  final VoidCallback onTap;
  final String language;

  const _BouncyDistrictCard({
    required this.district,
    required this.displayText,
    required this.isSelected,
    required this.onTap,
    required this.language,
  });

  @override
  State<_BouncyDistrictCard> createState() => _BouncyDistrictCardState();
}

class _BouncyDistrictCardState extends State<_BouncyDistrictCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          // Squish inwards when pressed
          transform: Matrix4.diagonal3Values(
            _isPressed ? 0.97 : 1.0,
            _isPressed ? 0.97 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            // Removed BackdropFilter! Used exact transparent hex colors instead.
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? const Color(0xF2191919) // Dark 0.95
                  : const Color(0xE6FFFFFF), // White 0.90
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: widget.isSelected
                    ? const Color(0xBFD8B66A) // Gold 0.75
                    : const Color(0xE0FFFFFF), // White 0.88
                width: widget.isSelected ? 1.2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? const Color(0x35B18A48)
                      : const Color(0x0B000000), // Black 0.045
                  blurRadius: widget.isSelected ? 23 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // LOCATION ICON
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: widget.isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE4C98A), Color(0xFFB78B42)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFFFFF), Color(0xFFEDEDE8)],
                          ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isSelected
                            ? const Color(0x50B18A48)
                            : const Color(0x0E000000),
                        blurRadius: 12,
                        offset: const Offset(3, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: widget.isSelected
                        ? Colors.white
                        : const Color(0xFF777777),
                  ),
                ),

                const SizedBox(width: 14),

                // DISTRICT NAME — displayText is already the translated
                // (or fallback English) name resolved by the parent
                // screen, so this is just a plain, synchronous Text.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected
                              ? Colors.white
                              : const Color(0xFF202020),
                        ),
                        child: Text(
                          widget.displayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: widget.isSelected
                              ? const Color(0x85FFFFFF)
                              : const Color(0xFF999999),
                        ),
                        child: Text(
                          widget.isSelected
                              ? AppStrings.t(
                                  'selected_for_feed',
                                  widget.language,
                                )
                              : AppStrings.t('tap_to_select', widget.language),
                        ),
                      ),
                    ],
                  ),
                ),

                // SELECTION CHECKMARK
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack, // Bouncy spring effect
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? const Color(0x1AFFFFFF)
                        : const Color(0xFFF2F2EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isSelected
                        ? Icons.check_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: widget.isSelected ? 18 : 11,
                    color: widget.isSelected
                        ? const Color(0xFFE4C98A)
                        : const Color(0xFF999999),
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

// ============================================================
// LUXURY SQUISH BUTTON
// ============================================================

class _LuxuryContinueButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onPressed;
  final String language;

  const _LuxuryContinueButton({
    required this.isActive,
    required this.onPressed,
    required this.language,
  });

  @override
  State<_LuxuryContinueButton> createState() => _LuxuryContinueButtonState();
}

class _LuxuryContinueButtonState extends State<_LuxuryContinueButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (widget.isActive) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (widget.isActive) {
            setState(() => _isPressed = false);
            widget.onPressed();
          } else {
            widget.onPressed(); // Triggers the snackbar if null
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          height: 60,
          transform: Matrix4.diagonal3Values(
            _isPressed ? 0.96 : 1.0,
            _isPressed ? 0.96 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF171717)
                : const Color(0xFFD7D7D2),
            borderRadius: BorderRadius.circular(21),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: const Color(0x2E000000), // Black 0.18
                      blurRadius: _isPressed ? 10 : 20,
                      offset: _isPressed
                          ? const Offset(0, 4)
                          : const Offset(0, 9),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.t('continue_to_news', widget.language),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.isActive
                      ? Colors.white
                      : const Color(0xFF888888),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? (_isPressed
                            ? const Color(0x2AFFFFFF)
                            : const Color(0x1FFFFFFF))
                      : const Color(0x0F000000),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: widget.isActive
                      ? Colors.white
                      : const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PREMIUM PROGRESS
// ============================================================

class _PremiumProgress extends StatelessWidget {
  final bool active;
  const _PremiumProgress({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFF171717), Color(0xFF555555)],
              )
            : const LinearGradient(
                colors: [Color(0xFFE1E1DC), Color(0xFFEAEAE6)],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
    );
  }
}

// ============================================================
// AURORA BLOB
// ============================================================

class _AuroraBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _AuroraBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.08), Colors.transparent],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}
