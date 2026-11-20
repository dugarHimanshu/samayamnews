// widgets/timeline/story_timeline_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_article.dart';
import '../../models/story_timeline.dart';
import '../../screens/home/news_story_page.dart';
import '../../services/story_timeline_service.dart';

/// Modal bottom sheet and inline widget that allows readers to view all
/// related news reports and latest developments for a story in chronological order.
class StoryTimelineSheet extends StatelessWidget {
  final String currentArticleId;
  final List<NewsArticle> availableArticles;
  final String selectedLanguage;

  const StoryTimelineSheet({
    super.key,
    required this.currentArticleId,
    required this.availableArticles,
    this.selectedLanguage = 'English',
  });

  /// Displays the interactive Story Timeline modal bottom sheet.
  static void show(
    BuildContext context, {
    required String articleId,
    required List<NewsArticle> availableArticles,
    String selectedLanguage = 'English',
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StoryTimelineSheet(
        currentArticleId: articleId,
        availableArticles: availableArticles,
        selectedLanguage: selectedLanguage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timelineService = StoryTimelineService.instance;
    final timeline = timelineService.getTimelineForArticle(currentArticleId);

    if (timeline == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Text('No linked timeline found for this story.'),
      );
    }

    final chronologicalItems = timelineService.getChronologicalArticles(
      currentArticleId,
      availableArticles,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16181F) : Colors.white;
    final cardBg = isDark ? const Color(0xFF20232D) : const Color(0xFFF7F8FA);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timeline_rounded,
                              size: 13,
                              color: Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'DEVELOPING STORY TIMELINE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: const Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${chronologicalItems.length} Reports',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    timeline.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chronological sequence of news updates and follow-ups as they unfolded.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: secondaryTextColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Timeline Items List
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: chronologicalItems.length,
                itemBuilder: (context, index) {
                  final item = chronologicalItems[index];
                  final isCurrent = item.article.id == currentArticleId;
                  final isLast = index == chronologicalItems.length - 1;

                  return _TimelineStepCard(
                    item: item,
                    isCurrent: isCurrent,
                    isLast: isLast,
                    isDark: isDark,
                    cardBg: cardBg,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    onTapRead: () {
                      if (isCurrent) return;
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewsStoryPage(
                            article: item.article,
                            selectedLanguage: selectedLanguage,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual step in the chronological timeline
class _TimelineStepCard extends StatelessWidget {
  final TimelineArticleItem item;
  final bool isCurrent;
  final bool isLast;
  final bool isDark;
  final Color cardBg;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTapRead;

  const _TimelineStepCard({
    required this.item,
    required this.isCurrent,
    required this.isLast,
    required this.isDark,
    required this.cardBg,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTapRead,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    Color badgeBg;
    Color badgeTextColor;
    IconData stepIcon;

    if (item.isLatestDevelopment) {
      indicatorColor = const Color(0xFF10B981);
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
      badgeTextColor = const Color(0xFF059669);
      stepIcon = Icons.auto_awesome_rounded;
    } else if (item.isOriginalReport) {
      indicatorColor = const Color(0xFF3B82F6);
      badgeBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
      badgeTextColor = const Color(0xFF2563EB);
      stepIcon = Icons.flag_rounded;
    } else {
      indicatorColor = const Color(0xFFF59E0B);
      badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      badgeTextColor = const Color(0xFFD97706);
      stepIcon = Icons.update_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left timeline indicator and connecting vertical line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrent ? indicatorColor : indicatorColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: indicatorColor,
                    width: isCurrent ? 2.5 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: indicatorColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    stepIcon,
                    size: 15,
                    color: isCurrent ? Colors.white : indicatorColor,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          indicatorColor.withValues(alpha: 0.5),
                          indicatorColor.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Right content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrent
                    ? (isDark ? const Color(0xFF282C39) : const Color(0xFFEEF4FF))
                    : cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent
                      ? indicatorColor.withValues(alpha: 0.5)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase Badge & Date Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.phaseLabel.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.article.publishedAt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'CURRENT',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Headline
                  Text(
                    item.article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: primaryTextColor,
                    ),
                  ),

                  if (item.article.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Action Button
                  if (!isCurrent)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onTapRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFF1565C0),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: Text(
                          'Read Report',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
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
}

/// Inline version of the timeline suitable for embedding directly inside story pages
class StoryTimelineInlineSection extends StatelessWidget {
  final String currentArticleId;
  final List<NewsArticle> availableArticles;
  final String selectedLanguage;

  const StoryTimelineInlineSection({
    super.key,
    required this.currentArticleId,
    required this.availableArticles,
    this.selectedLanguage = 'English',
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StoryTimelineService.instance,
      builder: (context, _) {
        final timelineService = StoryTimelineService.instance;
        final timeline = timelineService.getTimelineForArticle(currentArticleId);

        if (timeline == null || timeline.articleIds.length <= 1) {
          return const SizedBox.shrink();
        }

        final items = timelineService.getChronologicalArticles(
          currentArticleId,
          availableArticles,
        );

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF1A1C23) : const Color(0xFFF9FAFB);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timeline_rounded,
                      size: 16,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STORY TIMELINE & DEVELOPMENTS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        Text(
                          timeline.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      StoryTimelineSheet.show(
                        context,
                        articleId: currentArticleId,
                        availableArticles: availableArticles,
                        selectedLanguage: selectedLanguage,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'View All (${items.length})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Compact horizontal/vertical preview of other items
              ...items.map((item) {
                final isCurrent = item.article.id == currentArticleId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: isCurrent
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewsStoryPage(
                                  article: item.article,
                                  selectedLanguage: selectedLanguage,
                                ),
                              ),
                            );
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF1565C0).withValues(alpha: 0.08)
                            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFF1565C0).withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF1565C0)
                                  : (isDark ? Colors.white12 : Colors.black12),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${item.chronologicalIndex}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.phaseLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: item.isLatestDevelopment
                                            ? const Color(0xFF059669)
                                            : (isCurrent
                                                ? const Color(0xFF1565C0)
                                                : Colors.black45),
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        '• Viewing now',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.article.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isCurrent)
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: Colors.black38,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
