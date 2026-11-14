import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/news_service.dart';
import '../../models/magazine.dart';
import '../../services/app_strings.dart';
import '../../services/magazine_store.dart';
import 'magazine_reader_page.dart';

class MagazineListScreen extends StatefulWidget {
  final String selectedLanguage;

  const MagazineListScreen({
    super.key,
    required this.selectedLanguage,
  });

  @override
  State<MagazineListScreen> createState() => _MagazineListScreenState();
}

class _MagazineListScreenState extends State<MagazineListScreen> {
  final MagazineStore _store = MagazineStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load().then((_) {
      if (mounted) setState(() {});
    });
    NewsRepository.instance.loadMagazines().then((_) {
      if (mounted) setState(() {});
    });
  }

  List<Magazine> get _magazines => NewsRepository.instance.magazines;

  void _openReader(Magazine magazine) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => MagazineReaderPage(magazine: magazine),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
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
    final title = AppStrings.t('magazine', widget.selectedLanguage);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF111216) : const Color(0xFFF8F8F6);
    final cardBg = isDark ? const Color(0xFF1E2026) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;
    final subtleTextColor = isDark ? Colors.white38 : Colors.black45;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryTextColor,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _magazines.length,
        itemBuilder: (context, index) {
          final mag = _magazines[index];
          final isLiked = _store.isLiked(mag.id);
          final isSaved = _store.isSaved(mag.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openReader(mag),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Magazine Cover thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: mag.coverImageUrl,
                              width: 96,
                              height: 142,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                width: 96,
                                height: 142,
                                color: isDark ? const Color(0xFF282A33) : Colors.grey.shade200,
                                child: Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PDF',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Magazine Details (Flexible and overflow-safe)
                      Expanded(
                        child: SizedBox(
                          height: 142,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A2D37) : const Color(0xFFF0F0EE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      mag.category.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    mag.title,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      color: primaryTextColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    mag.subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: secondaryTextColor,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),

                              // Bottom bar: Issue tag and action buttons with zero overflow risk
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      mag.issue,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: subtleTextColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkResponse(
                                    radius: 18,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _store.toggleLike(mag.id);
                                      setState(() {});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        size: 19,
                                        color: isLiked ? Colors.redAccent : subtleTextColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkResponse(
                                    radius: 18,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _store.toggleSave(mag.id);
                                      setState(() {});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                        size: 19,
                                        color: isSaved ? Colors.amber.shade700 : subtleTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
