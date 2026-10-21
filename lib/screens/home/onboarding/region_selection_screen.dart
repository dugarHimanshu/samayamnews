import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'district_selection_screen.dart'; // Make sure to uncomment this in your project
import '../../../services/app_strings.dart';
import '../../../services/place_translations.dart';

class RegionSelectionScreen extends StatefulWidget {
  final String selectedLanguage;

  const RegionSelectionScreen({super.key, required this.selectedLanguage});

  @override
  State<RegionSelectionScreen> createState() => _RegionSelectionScreenState();
}

class _RegionSelectionScreenState extends State<RegionSelectionScreen>
    with SingleTickerProviderStateMixin {
  // 1. Replaced setState with ValueNotifiers for targeted, ultra-fast rebuilds
  final ValueNotifier<String?> _selectedStateNotifier = ValueNotifier(null);
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _auroraController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat(reverse: true);

  final List<IndianState> _states = const [
    IndianState(id: 'andhra_pradesh', name: 'Andhra Pradesh', shortName: 'AP'),
    // IndianState(id: 'arunachal_pradesh', name: 'Arunachal Pradesh', shortName: 'AR',),
    // IndianState(id: 'assam', name: 'Assam', shortName: 'AS'),
    // IndianState(id: 'bihar', name: 'Bihar', shortName: 'BR'),
    // IndianState(id: 'chhattisgarh', name: 'Chhattisgarh', shortName: 'CG'),
    // IndianState(id: 'goa', name: 'Goa', shortName: 'GA'),
    // IndianState(id: 'gujarat', name: 'Gujarat', shortName: 'GJ'),
    // IndianState(id: 'haryana', name: 'Haryana', shortName: 'HR'),
    // IndianState(id: 'himachal_pradesh', name: 'Himachal Pradesh', shortName: 'HP',),
    // IndianState(id: 'jharkhand', name: 'Jharkhand', shortName: 'JH'),
    // IndianState(id: 'karnataka', name: 'Karnataka', shortName: 'KA'),
    // IndianState(id: 'kerala', name: 'Kerala', shortName: 'KL'),
    // IndianState(id: 'madhya_pradesh', name: 'Madhya Pradesh', shortName: 'MP'),
    // IndianState(id: 'maharashtra', name: 'Maharashtra', shortName: 'MH'),
    // IndianState(id: 'manipur', name: 'Manipur', shortName: 'MN'),
    // IndianState(id: 'meghalaya', name: 'Meghalaya', shortName: 'ML'),
    // IndianState(id: 'mizoram', name: 'Mizoram', shortName: 'MZ'),
    // IndianState(id: 'nagaland', name: 'Nagaland', shortName: 'NL'),
    // IndianState(id: 'odisha', name: 'Odisha', shortName: 'OD'),
    // IndianState(id: 'punjab', name: 'Punjab', shortName: 'PB'),
    // IndianState(id: 'rajasthan', name: 'Rajasthan', shortName: 'RJ'),
    // IndianState(id: 'sikkim', name: 'Sikkim', shortName: 'SK'),
    // IndianState(id: 'tamil_nadu', name: 'Tamil Nadu', shortName: 'TN'),
    IndianState(id: 'telangana', name: 'Telangana', shortName: 'TS'),
    // IndianState(id: 'tripura', name: 'Tripura', shortName: 'TR'),
    // IndianState(id: 'uttar_pradesh', name: 'Uttar Pradesh', shortName: 'UP'),
    // IndianState(id: 'uttarakhand', name: 'Uttarakhand', shortName: 'UK'),
    // IndianState(id: 'west_bengal', name: 'West Bengal', shortName: 'WB'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _auroraController.dispose();
    _selectedStateNotifier.dispose();
    super.dispose();
  }

  void _continue() {
    final selectedStateId = _selectedStateNotifier.value;

    if (selectedStateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0x80000000), // Black 0.5
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.t('select_state_first', widget.selectedLanguage),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
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

    final selectedState = _states.firstWhere(
      (state) => state.id == selectedStateId,
    );

    /* UNCOMMENT THIS TO ENABLE NAVIGATION */
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            DistrictSelectionScreen(
              selectedLanguage: widget.selectedLanguage,
              selectedState: selectedState.name,
            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F6),
      body: Stack(
        children: [
          // ============================================================
          // BACKGROUND LAYER (Optimized with RepaintBoundary)
          // ============================================================
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _auroraController,
              builder: (context, child) {
                final value = _auroraController.value;

                return Stack(
                  children: [
                    Positioned(
                      top: -120 + (value * 35),
                      right: -100,
                      child: const _AuroraBlob(
                        size: 340,
                        color: Color(0x3DD9C6FF),
                      ),
                    ),
                    Positioned(
                      top: 160 - (value * 50),
                      left: -150,
                      child: const _AuroraBlob(
                        size: 310,
                        color: Color(0x35B9E9FF),
                      ),
                    ),
                    Positioned(
                      bottom: -140 + (value * 60),
                      right: -80,
                      child: const _AuroraBlob(
                        size: 330,
                        color: Color(0x2FDCCB96),
                      ),
                    ),
                    Positioned(
                      bottom: 120,
                      left: -120,
                      child: const _AuroraBlob(
                        size: 250,
                        color: Color(0x25EFC9DD),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // STATIC WHITE GRADIENT OVERLAY
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCCFFFFFF),
                    Color(0x88FFFFFF),
                    Color(0xD9F8F8F6),
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // MAIN CONTENT
          // ============================================================
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 30),
                        _buildProgress(),
                        const SizedBox(height: 32),
                        _buildHeroHeader(),
                        const SizedBox(height: 30),
                        _buildCountryCard(),
                        const SizedBox(height: 28),
                        _buildSectionLabel(
                          AppStrings.t('your_region', widget.selectedLanguage),
                          '01',
                        ),
                        const SizedBox(height: 10),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildStateList(),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
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
        _GlassIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0x8CFFFFFF), // White 0.55
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xCCFFFFFF)), // White 0.8
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.public_rounded,
                    size: 14,
                    color: Color(0xFF555555),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    AppStrings.t('india', widget.selectedLanguage),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: const Color(0xFF444444),
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
        Expanded(child: _PremiumProgress(active: true, number: '01')),
        SizedBox(width: 7),
        Expanded(child: _PremiumProgress(active: true, number: '02')),
        SizedBox(width: 7),
        Expanded(child: _PremiumProgress(active: false, number: '03')),
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
                  colors: [Color(0xFFB58A3A), Color(0xFFE4C98A)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              AppStrings.t('personalize_feed', widget.selectedLanguage),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: const Color(0xFFB18A48),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          AppStrings.t('where_are_you', widget.selectedLanguage),
          style: GoogleFonts.playfairDisplay(
            fontSize: 42,
            height: 0.98,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF151515),
          ),
        ),
        Text(
          AppStrings.t('reading_from', widget.selectedLanguage),
          style: GoogleFonts.playfairDisplay(
            fontSize: 42,
            height: 1.05,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF151515),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.t('region_subtitle', widget.selectedLanguage),
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.65,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryCard() {
    return _GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFEFEFEA)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000), // Black 0.06
                  blurRadius: 15,
                  offset: Offset(4, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('🇮🇳', style: TextStyle(fontSize: 25)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t('country', widget.selectedLanguage),
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: const Color(0xFF9A9A9A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'India',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF191919),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF171717),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x26000000), // Black 0.15
                  blurRadius: 15,
                  offset: Offset(3, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, String number) {
    return Row(
      children: [
        Text(
          number,
          style: GoogleFonts.playfairDisplay(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB18A48),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
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
                    'search_state_hint',
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

  Widget _buildStateList() {
    // 2. Only the List rebuilds on typing, saving massive performance
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, search, child) {
        final query = search.text.trim().toLowerCase();
        final filteredStates = query.isEmpty
            ? _states
            : _states
                  .where(
                    (s) =>
                        s.name.toLowerCase().contains(query) ||
                        s.shortName.toLowerCase().contains(query),
                  )
                  .toList();

        if (filteredStates.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredStates.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final state = filteredStates[index];

            // 3. Only the individual card rebuilds on selection
            return ValueListenableBuilder<String?>(
              valueListenable: _selectedStateNotifier,
              builder: (context, selectedId, _) {
                return _PremiumStateCard(
                  state: state,
                  isSelected: state.id == selectedId,
                  language: widget.selectedLanguage,
                  onTap: () {
                    _selectedStateNotifier.value = state.id;
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x80FFFFFF), // White 0.5
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0F0EC),
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 24,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            AppStrings.t('no_state_found', widget.selectedLanguage),
            style: GoogleFonts.playfairDisplay(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            AppStrings.t('try_another_search', widget.selectedLanguage),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF888888),
            ),
          ),
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
          valueListenable: _selectedStateNotifier,
          builder: (context, selectedId, _) {
            final selected = selectedId != null;

            return GestureDetector(
              onTap: _continue,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                height: 60,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF171717)
                      : const Color(0xFFD7D7D2),
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x2E000000), // Black 0.18
                            blurRadius: 20,
                            offset: Offset(0, 9),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.t('continue', widget.selectedLanguage),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x0F000000),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// PREMIUM STATE CARD (Optimized!)
// ============================================================

class _PremiumStateCard extends StatelessWidget {
  final IndianState state;
  final bool isSelected;
  final VoidCallback onTap;
  final String language;

  const _PremiumStateCard({
    required this.state,
    required this.isSelected,
    required this.onTap,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    // 4. RepaintBoundary isolates this specific list item when it animates!
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translateByDouble(
              isSelected ? 3.0 : 0.0,
              isSelected ? -1.0 : 0.0,
              0.0,
              1.0,
            ),
          child: Container(
            padding: const EdgeInsets.all(10),
            // 5. REMOVED EXPENSIVE BackdropFilter.
            // Substituted with identical-looking semi-transparent solid colors.
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xF2191919)
                  : const Color(0xE6FFFFFF),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: isSelected
                    ? const Color(0xBFD8B66A)
                    : const Color(0xD9FFFFFF),
                width: isSelected ? 1.2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0x33B18A48)
                      : const Color(0x0B000000),
                  blurRadius: isSelected ? 24 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: isSelected
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
                        color: isSelected
                            ? const Color(0x55B18A48)
                            : const Color(0x0F000000),
                        blurRadius: 12,
                        offset: const Offset(3, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    state.shortName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF555555),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF202020),
                        ),
                        child: Text(
                          PlaceTranslations.stateName(state.name, language),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(0x8CFFFFFF)
                              : const Color(0xFF999999),
                        ),
                        child: Text(
                          isSelected
                              ? AppStrings.t('selected_for_feed', language)
                              : AppStrings.t('tap_to_select', language),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack, // Added a nice bounce effect
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0x1AFFFFFF)
                        : const Color(0xFFF2F2EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: isSelected ? 18 : 12,
                    color: isSelected
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
// GLASS CONTAINER
// ============================================================

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  const _GlassContainer({
    required this.child,
    this.borderRadius = 24,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x99FFFFFF), // White 0.60
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: const Color(0xE6FFFFFF)), // White 0.9
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000000), // Black 0.045
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ============================================================
// GLASS ICON BUTTON
// ============================================================

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x94FFFFFF), // White 0.58
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xE6FFFFFF)), // White 0.9
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000), // Black 0.06
                  blurRadius: 15,
                  offset: Offset(2, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF333333)),
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
  final String number;

  const _PremiumProgress({required this.active, required this.number});

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
                  color: Color(0x14000000), // Black 0.08
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

// ============================================================
// MODEL
// ============================================================

class IndianState {
  final String id;
  final String name;
  final String shortName;

  const IndianState({
    required this.id,
    required this.name,
    required this.shortName,
  });
}
