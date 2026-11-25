import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'email_login_screen.dart';
import '../../contributor/reporter_registration_screen.dart';
import 'mobile_login_screen.dart';
import 'google_login_screen.dart';
import 'language_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F6),
      body: Stack(
        children: [
          // ============================================================
          // AURORA BACKGROUND
          // ============================================================
          Positioned(
            top: -150,
            right: -120,
            child: _AuroraBlob(size: 370, color: const Color(0x55DCCBFF)),
          ),

          Positioned(
            top: 180,
            left: -180,
            child: _AuroraBlob(size: 350, color: const Color(0x48BFE8FF)),
          ),

          Positioned(
            bottom: -180,
            right: -100,
            child: _AuroraBlob(size: 380, color: const Color(0x42E5D09C)),
          ),

          Positioned(
            bottom: 190,
            left: -130,
            child: _AuroraBlob(size: 270, color: const Color(0x35EBCBDD)),
          ),

          // ============================================================
          // SOFT LIGHT OVERLAY
          // ============================================================
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xE8FFFFFF),
                    Color(0xB8FFFFFF),
                    Color(0xF2F8F8F6),
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // CONTENT
          // ============================================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ======================================================
                  // PREMIUM LOGO
                  // ======================================================
                  _buildLogo(),

                  const SizedBox(height: 27),

                  // ======================================================
                  // HEADLINE
                  // ======================================================
                  Text(
                    'Stay informed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 39,
                      fontWeight: FontWeight.w600,
                      height: 1.02,
                      color: const Color(0xFF151515),
                    ),
                  ),

                  Text(
                    'Stay connected.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 39,
                      fontWeight: FontWeight.w600,
                      height: 1.02,
                      color: const Color(0xFF151515),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'Your world. Your language. Your news.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF777777),
                      letterSpacing: 0.25,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ======================================================
                  // LOGIN OPTIONS GLASS PANEL
                  // ======================================================
                  _buildLoginPanel(context),

                  const SizedBox(height: 14),

                  // ======================================================
                  // REPORTER / FREELANCER REGISTRATION
                  // ======================================================
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReporterRegistrationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.how_to_reg_rounded, size: 18, color: Color(0xFF1A1A1A)),
                    label: Text(
                      'Register as Reporter / Freelancer',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ======================================================
                  // TERMS
                  // ======================================================
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9A9A9A),
                      ),
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

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Image.asset('assets/public/images/app_logo.png'),
        ),
        const SizedBox(height: 10),
        Text('సమయం న్యూస్', style: GoogleFonts.notoSansTelugu(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1A237E))),
      ],
    );
  }

  // ============================================================
  // LOGIN PANEL
  // ============================================================

  Widget _buildLoginPanel(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(29),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(29),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.88),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              _LoginButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Continue with Google',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoogleLoginScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 9),

              _LoginButton(
                icon: Icons.email_outlined,
                label: 'Continue with Email',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmailLoginScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 9),

              _LoginButton(
                icon: Icons.phone_outlined,
                label: 'Continue with Mobile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MobileLoginScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 17),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.07),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF999999),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.07),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 17),

              _GuestButton(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.22),
                    builder: (context) {
                      return _GuestDialog(
                        onContinue: () {
                          Navigator.pop(context);

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LanguageSelectionScreen(),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// LOGIN BUTTON
// ================================================================

class _LoginButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LoginButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTap: widget.onTap,

      onTapDown: (_) {
        _setPressed(true);
      },

      onTapUp: (_) {
        _setPressed(false);
      },

      onTapCancel: () {
        _setPressed(false);
      },

      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 57,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF3F3EF)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 5,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),

              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1EC),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.045),
                      blurRadius: 7,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: const Color(0xFF222222),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF222222),
                  ),
                ),
              ),

              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F1ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: Color(0xFF777777),
                ),
              ),

              const SizedBox(width: 13),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// GUEST BUTTON
// ================================================================

class _GuestButton extends StatefulWidget {
  final VoidCallback onTap;

  const _GuestButton({required this.onTap});

  @override
  State<_GuestButton> createState() => _GuestButtonState();
}

class _GuestButtonState extends State<_GuestButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTap: widget.onTap,

      onTapDown: (_) {
        _setPressed(true);
      },

      onTapUp: (_) {
        _setPressed(false);
      },

      onTapCancel: () {
        _setPressed(false);
      },

      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF252525), Color(0xFF080808)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue as Guest',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 10),

              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Color(0xFFE8CB91),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// GUEST DIALOG
// ================================================================

class _GuestDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const _GuestDialog({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.fromLTRB(23, 23, 23, 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 35,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAD29C), Color(0xFFB78B43)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),

                const SizedBox(height: 19),

                Text(
                  'Continue as guest?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF171717),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'You can explore and read the news without creating an account.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.55,
                    color: const Color(0xFF707070),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1ED),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: GestureDetector(
                        onTap: onContinue,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF252525), Color(0xFF080808)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(width: 7),

                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: Color(0xFFE8CB91),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// AURORA BLOB
// ================================================================

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
            colors: [color, color.withValues(alpha: 0.12), Colors.transparent],
            stops: const [0.0, 0.48, 1.0],
          ),
        ),
      ),
    );
  }
}