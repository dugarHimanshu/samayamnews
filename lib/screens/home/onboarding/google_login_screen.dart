import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'language_selection_screen.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _isLoading = false;

  Future<void> _continueWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ============================================================
          // AURORA BACKGROUND
          // ============================================================
          Positioned(
            top: -120,
            right: -90,
            child: _AuroraOrb(
              size: 300,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFD9E8FF),
                  Color(0xFFE8DEFF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),

          Positioned(
            top: 260,
            left: -150,
            child: _AuroraOrb(
              size: 320,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFDDF8F0),
                  Color(0xFFE6F0FF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: -140,
            right: -100,
            child: _AuroraOrb(
              size: 320,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFE6EF),
                  Color(0xFFE8E2FF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),

          // ============================================================
          // STATIC CONTENT
          // ============================================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                children: [
                  // ======================================================
                  // TOP BAR
                  // ======================================================
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const Spacer(),

                  // ======================================================
                  // GOOGLE GLASS ORB
                  // ======================================================
                  const _GoogleGlassLogo(),

                  const SizedBox(height: 34),

                  // ======================================================
                  // TITLE
                  // ======================================================
                  Text(
                    'Continue with',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: const Color(0xFF17181B),
                    ),
                  ),

                  Text(
                    'Google.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: const Color(0xFF17181B),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Sign in securely with your Google account and personalize your news experience.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        height: 1.55,
                        color: const Color(0xFF656A73),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ======================================================
                  // GLASS AUTH CARD
                  // ======================================================
                  _AuthCard(
                    isLoading: _isLoading,
                    onContinue: _continueWithGoogle,
                  ),

                  const SizedBox(height: 18),

                  // ======================================================
                  // SECURITY NOTE
                  // ======================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Color(0xFF737983),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          'Your Google account is only used for authentication.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF8A9099),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Private • Secure • Simple',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: const Color(0xFFB0B5BC),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// AUTH CARD
// ================================================================

class _AuthCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onContinue;

  const _AuthCard({required this.isLoading, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              // ==========================================================
              // ACCOUNT INFORMATION
              // ==========================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFEFF3F8)],
                        ),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 21,
                        color: Color(0xFF69717D),
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Account',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF272A30),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Secure authentication',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: const Color(0xFF8A9099),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F7F4),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDCECE3)),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Color(0xFF3F8F69),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // GOOGLE BUTTON
              // ==========================================================
              SizedBox(
                width: double.infinity,
                height: 60,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading ? null : onContinue,
                    borderRadius: BorderRadius.circular(21),
                    splashColor: Colors.white.withValues(alpha: 0.08),
                    highlightColor: Colors.white.withValues(alpha: 0.04),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF202124), Color(0xFF111214)],
                        ),
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _GoogleMiniLogo(),

                                  const SizedBox(width: 10),

                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(width: 9),

                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
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
// AURORA ORB
// ============================================================

class _AuroraOrb extends StatelessWidget {
  final double size;
  final Gradient gradient;

  const _AuroraOrb({required this.size, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      ),
    );
  }
}

// ============================================================
// GLASS BACK BUTTON
// ============================================================

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.black.withValues(alpha: 0.04),
            highlightColor: Colors.black.withValues(alpha: 0.02),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 17, color: const Color(0xFF30343A)),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GOOGLE GLASS LOGO
// ============================================================

class _GoogleGlassLogo extends StatelessWidget {
  const _GoogleGlassLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF2F5F9)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF91A7C0).withValues(alpha: 0.13),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 14,
            offset: const Offset(-6, -6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.72),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),

          Text(
            'G',
            style: GoogleFonts.inter(
              fontSize: 46,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4285F4),
            ),
          ),

          Positioned(
            top: 15,
            right: 21,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34A853),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MINI GOOGLE LOGO
// ============================================================

class _GoogleMiniLogo extends StatelessWidget {
  const _GoogleMiniLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF4285F4),
        ),
      ),
    );
  }
}