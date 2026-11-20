// lib/widgets/home/auto_sliding_ad_card.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/advertisement_campaign.dart';
import '../../data/demo_ads.dart';

/// Interactive, 4-page auto-sliding advertisement card.
/// Automatically slides through 4 distinct pages/slides with story-style progress
/// indicators, pause-on-touch interaction, and a direct call to action.
class AutoSlidingAdCard extends StatefulWidget {
  final AdvertisementCampaign? campaign;
  final AdvertisementItem? fallbackAd;

  const AutoSlidingAdCard({
    super.key,
    this.campaign,
    this.fallbackAd,
  });

  @override
  State<AutoSlidingAdCard> createState() => _AutoSlidingAdCardState();
}

class _AutoSlidingAdCardState extends State<AutoSlidingAdCard> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _isUserTouching = false;

  late final List<AdSlide> _slides;
  late final String _sponsor;
  late final String _ctaText;
  late final String _ctaUrl;
  late final String _scheduleBadge;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    if (widget.campaign != null && widget.campaign!.slides.isNotEmpty) {
      _slides = widget.campaign!.slides;
      _sponsor = widget.campaign!.sponsor;
      _ctaText = widget.campaign!.ctaText;
      _ctaUrl = widget.campaign!.ctaUrl;
      _scheduleBadge = widget.campaign!.scheduleLabel;
    } else {
      final ad = widget.fallbackAd ?? demoAds[0];
      _sponsor = ad.sponsor;
      _ctaText = ad.ctaText;
      _ctaUrl = '';
      _scheduleBadge = '3+1 Schedule (4 Days)';
      // Generate 4 dynamic slides for fallback
      _slides = [
        AdSlide(
          pageIndex: 1,
          tag: ad.tag,
          headline: ad.headline,
          description: ad.description,
          imageUrl: ad.imageUrl,
          highlightBadge: 'PAGE 1 OF 4 • OVERVIEW',
        ),
        AdSlide(
          pageIndex: 2,
          tag: 'FEATURE HIGHLIGHTS',
          headline: 'Engineered with Precision & Industry-Leading Innovation.',
          description:
              'Seamless integration, verified reliability, and top-tier performance for discerning users.',
          imageUrl:
              'https://images.unsplash.com/photo-1558441719-573255e1b6cb?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 2 OF 4 • SPECS',
        ),
        AdSlide(
          pageIndex: 3,
          tag: 'VERIFIED VALUE',
          headline: 'Trusted by Thousands of Satisfied Customers Nationwide.',
          description:
              'Backed by round-the-clock priority customer support and risk-free satisfaction guarantee.',
          imageUrl:
              'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 3 OF 4 • BENEFITS',
        ),
        AdSlide(
          pageIndex: 4,
          tag: 'EXCLUSIVE OFFER',
          headline: 'Claim Special Introductory Privilege Available This Week.',
          description:
              'Unlock exclusive savings and priority onboarding when you reserve your spot today.',
          imageUrl:
              'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=900&q=80',
          highlightBadge: 'PAGE 4 OF 4 • ACTION',
        ),
      ];
    }

    _startAutoSlideTimer();
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (_isUserTouching || !mounted || _slides.isEmpty) return;

      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onUserTouchStart() {
    setState(() => _isUserTouching = true);
  }

  void _onUserTouchEnd() {
    setState(() => _isUserTouching = false);
  }

  Future<void> _handleCta() async {
    if (_ctaUrl.isNotEmpty) {
      final uri = Uri.tryParse(_ctaUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening sponsor link for $_sponsor...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 680;

    return Container(
      color: const Color(0xFFF3F1EC),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Listener(
                  onPointerDown: (_) => _onUserTouchStart(),
                  onPointerUp: (_) => _onUserTouchEnd(),
                  onPointerCancel: (_) => _onUserTouchEnd(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // TOP HEADER: SPONSOR CHIP & SCHEDULE BADGE
                      // ==================================================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SPONSORED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    _sponsor.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 11,
                                    color: Color(0xFF1565C0),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _scheduleBadge,
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0D47A1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // 4-PAGE AUTO-SLIDING CAROUSEL
                      // ==================================================
                      SizedBox(
                        height: isCompact ? 340 : 410,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: _slides.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                final slide = _slides[index];
                                return _buildSlidePage(slide, isCompact);
                              },
                            ),

                            // Story-style 4-segment progress bars
                            Positioned(
                              top: 10,
                              left: 14,
                              right: 14,
                              child: Row(
                                children: List.generate(_slides.length, (idx) {
                                  final isCurrent = idx == _currentPage;
                                  final isPast = idx < _currentPage;

                                  return Expanded(
                                    child: Container(
                                      height: 3.5,
                                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? Colors.white
                                            : (isPast
                                                ? Colors.white.withValues(alpha: 0.85)
                                                : Colors.white.withValues(alpha: 0.35)),
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            // Slide counter pill (e.g. "3 / 4")
                            Positioned(
                              top: 22,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_currentPage + 1} / ${_slides.length}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // BOTTOM FOOTER: CALL TO ACTION BUTTON
                      // ==================================================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _handleCta,
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                label: Text(
                                  _ctaText,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSlidePage(AdSlide slide, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slide Visual Banner
        Expanded(
          flex: isCompact ? 5 : 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: slide.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  color: const Color(0xFFE5E7EB),
                  child: const Center(
                    child: Icon(
                      Icons.campaign_outlined,
                      size: 42,
                      color: Colors.black26,
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              if (slide.highlightBadge != null)
                Positioned(
                  bottom: 12,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      slide.highlightBadge!,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Slide Text Content
        Expanded(
          flex: isCompact ? 4 : 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isCompact ? 16 : 19,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  slide.description,
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: isCompact ? 11 : 12.5,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
