import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_strings.dart';

class NewsBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final String language; // 'english' / 'hindi' / 'telugu'

  const NewsBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        // A fixed height ensures the Stack sizes correctly
        child: SizedBox(
          height: 70,
          child: Stack(
            children: [
              // ============================================================
              // LAYER 1: STATIC GLASS BACKGROUND
              // Isolated in a RepaintBoundary. This never rebuilds when
              // switching tabs, saving massive GPU cycles.
              // ============================================================
              const RepaintBoundary(child: _StaticGlassBackground()),

              // ============================================================
              // LAYER 2: INTERACTIVE ITEMS
              // Only this lightweight layer rebuilds on state change.
              // ============================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavigationItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: AppStrings.t('home', language),
                        selected: currentIndex == 0,
                        onTap: () => onItemSelected(0),
                      ),
                    ),
                    Expanded(
                      child: _NavigationItem(
                        icon: Icons.grid_view_outlined,
                        selectedIcon: Icons.grid_view_rounded,
                        label: AppStrings.t('categories', language),
                        selected: currentIndex == 1,
                        onTap: () => onItemSelected(1),
                      ),
                    ),
                    // NEW — Location tab
                    Expanded(
                      child: _NavigationItem(
                        icon: Icons.location_on_outlined,
                        selectedIcon: Icons.location_on_rounded,
                        label: AppStrings.t('location', language),
                        selected: currentIndex == 2,
                        onTap: () => onItemSelected(2),
                      ),
                    ),
                    Expanded(
                      child: _NavigationItem(
                        icon: Icons.search_outlined,
                        selectedIcon: Icons.search_rounded,
                        label: AppStrings.t('search', language),
                        selected: currentIndex == 3, // was 2
                        onTap: () => onItemSelected(3), // was 2
                      ),
                    ),
                    Expanded(
                      child: _NavigationItem(
                        icon: Icons.bookmark_outline_rounded,
                        selectedIcon: Icons.bookmark_rounded,
                        label: AppStrings.t('saved', language),
                        selected: currentIndex == 4, // was 3
                        onTap: () => onItemSelected(4), // was 3
                      ),
                    ),
                  ],
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
// STATIC GLASS BACKGROUND
// ============================================================
class _StaticGlassBackground extends StatelessWidget {
  const _StaticGlassBackground();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xE0FFFFFF), // White 0.88 alpha
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xE6FFFFFF), // White 0.9 alpha
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000), // Black 0.08 alpha
                blurRadius: 25,
                offset: Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ANIMATED NAVIGATION ITEM (React Bits Style)
// ============================================================
class _NavigationItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem> {
  // Tracks if the user's finger is currently pressing down on the item
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // Determine the scale based on press state AND selection state.
    // Gives that satisfying "squish" feel when tapped.
    final double targetScale = _isPressed
        ? 0.85
        : (widget.selected ? 1.05 : 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: widget.selected ? const Color(0x0F000000) : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Spring Animation
            AnimatedScale(
              scale: targetScale,
              duration: const Duration(milliseconds: 300),
              // Elastic curve gives it the bouncy Framer Motion / React look
              curve: Curves.easeOutBack,
              child: Icon(
                widget.selected ? widget.selectedIcon : widget.icon,
                size: 22,
                color: widget.selected ? Colors.black : Colors.black45,
              ),
            ),
            const SizedBox(height: 4),

            // Label Fade & Slide Animation
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: GoogleFonts.inter(
                fontSize: widget.selected ? 9.5 : 9,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.selected ? Colors.black : Colors.black45,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
