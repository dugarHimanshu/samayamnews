import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'region_selection_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedLanguage;

  late final AnimationController _auroraController;

  final List<NewsLanguage> _languages = const [
    NewsLanguage(id: 'english', nativeName: 'English', englishName: 'English'),
    NewsLanguage(id: 'hindi', nativeName: 'हिन्दी', englishName: 'Hindi'),
    // NewsLanguage(
    //   id: 'hinglish',
    //   nativeName: 'Hinglish',
    //   englishName: 'Hindi + English',
    // ),
    NewsLanguage(id: 'telugu', nativeName: 'తెలుగు', englishName: 'Telugu'),
    // NewsLanguage(id: 'urdu', nativeName: 'اردو', englishName: 'Urdu'),
    // NewsLanguage(id: 'tamil', nativeName: 'தமிழ்', englishName: 'Tamil'),
    // NewsLanguage(id: 'kannada', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
    // NewsLanguage(id: 'marathi', nativeName: 'मराठी', englishName: 'Marathi'),
    // NewsLanguage(id: 'bengali', nativeName: 'বাংলা', englishName: 'Bengali'),
  ];

  @override
  void initState() {
    super.initState();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  void _selectLanguage(String languageId) {
    if (_selectedLanguage == languageId) return;

    setState(() {
      _selectedLanguage = languageId;
    });
  }

  void _continue() {
    final selectedLanguage = _selectedLanguage;

    if (selectedLanguage == null) {
      final messenger = ScaffoldMessenger.of(context);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.language_rounded,
                  size: 19,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Choose a language to continue.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF171717),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            elevation: 8,
            duration: const Duration(milliseconds: 1600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );

      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, _) {
          return RegionSelectionScreen(selectedLanguage: selectedLanguage);
        },
        transitionsBuilder: (_, animation, _, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
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
      backgroundColor: const Color(0xFFF9FAFC),
      body: Stack(
        children: [
          // ============================================================
          // AURORA BACKGROUND (Optimized)
          // ============================================================
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _auroraController,
              builder: (context, child) {
                final value = _auroraController.value;

                return Stack(
                  children: [
                    Positioned(
                      top: -100 + (value * 30),
                      right: -80,
                      child: const _AuroraBlob(
                        size:
                            350, // Increased size to compensate for removed blur spread
                        color: Color(0xFFE5D9FF),
                      ),
                    ),
                    Positioned(
                      top: 220 - (value * 40),
                      left: -130,
                      child: const _AuroraBlob(
                        size: 380,
                        color: Color(0xFFDDF4FF),
                      ),
                    ),
                    Positioned(
                      bottom: -120 + (value * 35),
                      right: -80,
                      child: const _AuroraBlob(
                        size: 380,
                        color: Color(0xFFE3F7E9),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ============================================================
          // SOFT WHITE OVERLAY (Made const)
          // ============================================================
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xB8FFFFFF), // 0.72 alpha
                      Color(0x6BFFFFFF), // 0.42 alpha
                      Color(0xD1F7F8FB), // 0.82 alpha
                    ],
                  ),
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
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _GlassProgress(),
                        const SizedBox(height: 34),

                        // ==================================================
                        // EYEBROW
                        // ==================================================
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFB58A3A),
                                    Color(0xFFE4C98A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'PERSONALIZE YOUR EXPERIENCE',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: const Color(0xFFB18A48),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ==================================================
                        // HEADER
                        // ==================================================
                        Text(
                          'What language',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.8,
                            color: const Color(0xFF101114),
                          ),
                        ),
                        Text(
                          'feels like home?',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.8,
                            color: const Color(0xFF101114),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose the language you would like to read your news in.',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            height: 1.55,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // ==================================================
                        // SECTION LABEL
                        // ==================================================
                        Row(
                          children: [
                            Text(
                              'LANGUAGES',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(
                                  0x0F000000,
                                ), // Black 0.06 alpha
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ==================================================
                        // LANGUAGE GRID
                        // ==================================================
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _languages.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 13,
                                mainAxisSpacing: 13,
                                childAspectRatio: 1.32,
                              ),
                          itemBuilder: (context, index) {
                            final language = _languages[index];
                            final isSelected = _selectedLanguage == language.id;

                            return _LanguageGlassCard(
                              language: language,
                              isSelected: isSelected,
                              index: index,
                              onTap: () => _selectLanguage(language.id),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ============================================================
                // BOTTOM GLASS ACTION AREA
                // ============================================================
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                      decoration: const BoxDecoration(
                        color: Color(0xADFFFFFF), // White 0.68 alpha
                        border: Border(
                          top: BorderSide(
                            color: Color(0xE6FFFFFF), // White 0.9 alpha
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0F000000), // Black 0.06 alpha
                            blurRadius: 30,
                            offset: Offset(0, -10),
                          ),
                        ],
                      ),
                      child: LuxuryContinueButton(onPressed: _continue),
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

// ============================================================
// AURORA BLOB (Highly Optimized)
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
          // Replaced ImageFilter.blur with a RadialGradient.
          // This renders instantly and drops CPU/GPU usage drastically.
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.62),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.2, 1.0],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GLASS PROGRESS
// ============================================================

class _GlassProgress extends StatelessWidget {
  const _GlassProgress();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x8CFFFFFF), // White 0.55
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xD9FFFFFF)), // White 0.85
            boxShadow: const [
              BoxShadow(
                color: Color(0x09000000), // Black 0.035
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: const [
              Expanded(child: _ProgressSegment(active: true)),
              SizedBox(width: 6),
              Expanded(child: _ProgressSegment(active: false)),
              SizedBox(width: 6),
              Expanded(child: _ProgressSegment(active: false)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final bool active;

  const _ProgressSegment({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      height: 4,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFF111111), Color(0xFF555555)],
              )
            : null,
        color: active ? null : const Color(0x12000000), // Black 0.07
        borderRadius: BorderRadius.circular(20),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x2E000000), // Black 0.18
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}

// ============================================================
// GLASS LANGUAGE CARD
// ============================================================

class _LanguageGlassCard extends StatelessWidget {
  final NewsLanguage language;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _LanguageGlassCard({
    required this.language,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  Color _accentColor() {
    const colors = [
      Color(0xFFE8DFFF),
      Color(0xFFDDF5FF),
      Color(0xFFE1F7EA),
      Color(0xFFFFE9D8),
      Color(0xFFFFE1EC),
      Color(0xFFE4E8FF),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary here isolates the animations of individual cards
    // from the rest of the list, improving selection performance.
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          splashColor: const Color(0x0A000000), // Black 0.04
          highlightColor: const Color(0x06000000), // Black 0.025
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF151515), Color(0xFF292929)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xE6FFFFFF), Color(0xB8FFFFFF)],
                    ),
              border: Border.all(
                color: isSelected
                    ? const Color(0x40FFFFFF) // White 0.25
                    : const Color(0xE0FFFFFF), // White 0.88
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      const BoxShadow(
                        color: Color(0x24000000), // Black 0.14
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: _accentColor().withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(-3, -4),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x0C000000), // Black 0.045
                        blurRadius: 14,
                        offset: Offset(4, 7),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                if (!isSelected)
                  Positioned(
                    top: -25,
                    right: -25,
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentColor().withValues(alpha: 0.26),
                      ),
                    ),
                  ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xE6FFFFFF), // White 0.9
                          Color(0x0DFFFFFF), // White 0.05
                        ],
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF161719),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        language.englishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          color: isSelected
                              ? const Color(0x94FFFFFF) // White 0.58
                              : const Color(0x6B000000), // Black 0.42
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 1,
                  right: 1,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    scale: isSelected ? 1 : 0,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1F000000), // Black 0.12
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Color(0xFF111111),
                      ),
                    ),
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
// LUXURY CONTINUE BUTTON
// ============================================================

class LuxuryContinueButton extends StatefulWidget {
  final VoidCallback onPressed;

  const LuxuryContinueButton({super.key, required this.onPressed});

  @override
  State<LuxuryContinueButton> createState() => _LuxuryContinueButtonState();
}

class _LuxuryContinueButtonState extends State<LuxuryContinueButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // 1. RepaintBoundary ensures the gradient/shadow animations
    // don't force the parent screen to redraw.
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // 2. Instant feedback triggers the exact frame the finger touches down
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          // 3. Ultra-fast 150ms animation makes it feel snappy and responsive
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 60,
          // 4. Shrinks the button by 4% when pressed
          transform: Matrix4.diagonal3Values(
            _isPressed ? 0.96 : 1.0,
            _isPressed ? 0.96 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF101010), Color(0xFF2B2B2B)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x2E000000), // Black 0.18
                // 5. Shrink the shadow to simulate pressing into the screen
                blurRadius: _isPressed ? 10 : 24,
                offset: _isPressed ? const Offset(0, 4) : const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  // Slightly brighten the icon circle when pressed
                  color: _isPressed
                      ? const Color(0x2AFFFFFF)
                      : const Color(0x1FFFFFFF), // White 0.12
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x2EFFFFFF), // White 0.18
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsLanguage {
  final String id;
  final String nativeName;
  final String englishName;

  const NewsLanguage({
    required this.id,
    required this.nativeName,
    required this.englishName,
  });
}
