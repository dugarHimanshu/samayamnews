import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassHeader extends StatelessWidget {
  final bool visible;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  const GlassHeader({
    super.key,
    required this.visible,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      top: visible ? 0 : -90,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.055),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // ------------------------------------------------
                      // LEFT - HAMBURGER MENU
                      // ------------------------------------------------
                      _HeaderButton(icon: Icons.menu_rounded, onTap: onMenuTap),

                      // ------------------------------------------------
                      // CENTER - LOGO
                      // ------------------------------------------------
                      const Expanded(child: Center(child: _HeaderLogo())),

                      // ------------------------------------------------
                      // RIGHT - PROFILE AVATAR
                      // ------------------------------------------------
                      _ProfileHeaderButton(onTap: onProfileTap),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Text(
      'BECHO',
      style: GoogleFonts.playfairDisplay(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.black,
      ),
    );
  }
}

// ================================================================
// HAMBURGER BUTTON
// ================================================================

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashFactory: InkRipple.splashFactory,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Icon(icon, size: 24, color: Colors.black87)),
        ),
      ),
    );
  }
}

// ================================================================
// PROFILE AVATAR BUTTON
// ================================================================

class _ProfileHeaderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileHeaderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashFactory: InkRipple.splashFactory,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 24,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
