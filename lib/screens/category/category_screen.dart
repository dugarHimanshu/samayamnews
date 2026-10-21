import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/demo_news.dart';
import '../../models/news_article.dart';
import '../../services/saved_news_store.dart';
import '../../widgets/home/glass_header.dart';
import '../../widgets/home/news_bottom_navigation.dart';
import '../search/search_screen.dart';
import '../home/news_story_page.dart';

class CategoryScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;

  const CategoryScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
    required this.selectedDistrict,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ValueNotifier<int> _selectedCategoryNotifier = ValueNotifier(0);

  // ============================================================
  // SAVED NEWS
  // ============================================================

  final SavedNewsStore _savedStore = SavedNewsStore.instance;

  static const List<String> _categories = [
    'All',
    'Politics',
    'Business',
    'Technology',
    'Sports',
    'Entertainment',
    'World',
    'India',
    'Lifestyle',
  ];

  @override
  void initState() {
    super.initState();

    // Load existing saved articles.
    _savedStore.load();
  }

  @override
  void dispose() {
    _selectedCategoryNotifier.dispose();
    super.dispose();
  }

  // ============================================================
  // TOGGLE BOOKMARK
  // ============================================================

  Future<void> _toggleBookmark(NewsArticle article) async {
    await _savedStore.toggle(article.title);

    if (!mounted) return;

    // Refresh the bookmark icon immediately.
    setState(() {});

    final bool saved = _savedStore.isSaved(article.title);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 100),
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_remove_rounded,
              size: 19,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                saved ? 'Story saved' : 'Story removed from saved',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _handleNavigation(int index) {
    if (index == 1) return;

    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (index == 2) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return SearchScreen(
              selectedLanguage: widget.selectedLanguage,
              selectedState: widget.selectedState,
              selectedDistrict: widget.selectedDistrict,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  // ============================================================
  // OPEN FULL STORY
  // ============================================================

  void _openArticle(NewsArticle article) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return NewsStoryPage(
            article: article,
            selectedLanguage: widget.selectedLanguage,
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
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ==================================================
              // SPACE FOR GLASS HEADER
              // ==================================================
              const SliverToBoxAdapter(child: SizedBox(height: 110)),

              // ==================================================
              // EXPLORE HEADER
              // ==================================================
              const SliverToBoxAdapter(child: _ExploreHeader()),

              // ==================================================
              // CATEGORY FILTERS
              // ==================================================
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _selectedCategoryNotifier,
                    builder: (context, selectedIndex, _) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) {
                          return const SizedBox(width: 9);
                        },
                        itemBuilder: (context, index) {
                          return _BouncyCategoryPill(
                            label: _categories[index],
                            isSelected: selectedIndex == index,
                            onTap: () {
                              _selectedCategoryNotifier.value = index;
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 26)),

              // ==================================================
              // ARTICLE LIST
              // ==================================================
              SliverToBoxAdapter(
                child: ValueListenableBuilder<int>(
                  valueListenable: _selectedCategoryNotifier,
                  builder: (context, selectedIndex, _) {
                    final selectedCategory = _categories[selectedIndex]
                        .toLowerCase();

                    final articles = selectedIndex == 0
                        ? demoNews
                        : demoNews
                              .where(
                                (article) =>
                                    article.category.toLowerCase() ==
                                    selectedCategory,
                              )
                              .toList();

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: articles.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              key: ValueKey<int>(selectedIndex),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                125,
                              ),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: articles.length,
                              separatorBuilder: (_, _) {
                                return const SizedBox(height: 18);
                              },
                              itemBuilder: (context, index) {
                                final article = articles[index];

                                return _BouncyNewsCard(
                                  article: article,
                                  bookmarked: _savedStore.isSaved(
                                    article.title,
                                  ),
                                  onBookmark: () {
                                    _toggleBookmark(article);
                                  },
                                  onReadMore: () {
                                    _openArticle(article);
                                  },
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ],
          ),

          // ============================================================
          // GLASS HEADER
          // ============================================================
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassHeader(
              visible: true,
              onMenuTap: _noop,
              onProfileTap: _noop,
            ),
          ),

          // ============================================================
          // BOTTOM NAVIGATION
          // ============================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NewsBottomNavigation(
              currentIndex: 1,
              onItemSelected: _handleNavigation,
              language: widget.selectedLanguage,
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

// ============================================================================
// EXPLORE HEADER
// ============================================================================

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB58A3A), Color(0xFFE4C98A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                'EXPLORE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: const Color(0xFFB18A48),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            'Categories',
            style: GoogleFonts.playfairDisplay(
              fontSize: 42,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: -0.5,
              color: const Color(0xFF151515),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Discover stories curated from every corner '
            'of the world.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CATEGORY PILL
// ============================================================================

class _BouncyCategoryPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BouncyCategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BouncyCategoryPill> createState() => _BouncyCategoryPillState();
}

class _BouncyCategoryPillState extends State<_BouncyCategoryPill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },

      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });

        widget.onTap();
      },

      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },

      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 21),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isSelected ? const Color(0xFF151515) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF151515)
                  : const Color(0x1A000000),
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.2,
              color: widget.isSelected ? Colors.white : const Color(0xFF444444),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NEWS CARD
// ============================================================================

class _BouncyNewsCard extends StatefulWidget {
  final NewsArticle article;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onReadMore;

  const _BouncyNewsCard({
    required this.article,
    required this.bookmarked,
    required this.onBookmark,
    required this.onReadMore,
  });

  @override
  State<_BouncyNewsCard> createState() => _BouncyNewsCardState();
}

class _BouncyNewsCardState extends State<_BouncyNewsCard> {
  bool _bookmarkPressed = false;
  bool _readMorePressed = false;

  // ============================================================
  // BOOKMARK PRESS ANIMATION
  // ============================================================

  void _bookmarkDown() {
    if (!mounted) return;

    setState(() {
      _bookmarkPressed = true;
    });
  }

  void _bookmarkUp() {
    if (!mounted) return;

    setState(() {
      _bookmarkPressed = false;
    });
  }

  // ============================================================
  // READ MORE PRESS ANIMATION
  // ============================================================

  void _readMoreDown() {
    if (!mounted) return;

    setState(() {
      _readMorePressed = true;
    });
  }

  void _readMoreUp() {
    if (!mounted) return;

    setState(() {
      _readMorePressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // HERO IMAGE
            // ============================================================
            Hero(
              tag: 'category-image-${widget.article.imageUrl}',
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF2F2F0),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 45,
                            color: Color(0x40000000),
                          ),
                        );
                      },
                    ),

                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x22000000)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // EDITORIAL CONTENT
            // ============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 19, 20, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================================
                  // CATEGORY + BOOKMARK
                  // ========================================================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.article.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: const Color(0xFF555555),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ==================================================
                      // FUNCTIONAL BOOKMARK
                      // ==================================================
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        onTapDown: (_) {
                          _bookmarkDown();
                        },

                        onTapUp: (_) {
                          _bookmarkUp();
                          widget.onBookmark();
                        },

                        onTapCancel: () {
                          _bookmarkUp();
                        },

                        child: AnimatedScale(
                          scale: _bookmarkPressed ? 0.86 : 1.0,
                          duration: const Duration(milliseconds: 130),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: widget.bookmarked
                                  ? const Color(0xFFEFEAFF)
                                  : const Color(0xFFF5F5F2),
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                widget.bookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_outline_rounded,
                                key: ValueKey(widget.bookmarked),
                                size: 19,
                                color: widget.bookmarked
                                    ? Colors.deepPurple
                                    : const Color(0xFF888888),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ========================================================
                  // TITLE
                  // ========================================================
                  Text(
                    widget.article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: const Color(0xFF111111),
                    ),
                  ),

                  const SizedBox(height: 11),

                  // ========================================================
                  // DESCRIPTION
                  // ========================================================
                  Text(
                    widget.article.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.6,
                      color: const Color(0xFF666666),
                    ),
                  ),

                  const SizedBox(height: 19),

                  // ========================================================
                  // AUTHOR + READ MORE
                  // ========================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ----------------------------------------------------
                      // AUTHOR AVATAR
                      // ----------------------------------------------------
                      Container(
                        width: 29,
                        height: 29,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBEBE6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 15,
                          color: Color(0xFF888888),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ----------------------------------------------------
                      // AUTHOR DETAILS
                      // ----------------------------------------------------
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.article.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF555555),
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              widget.article.publishedAt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ----------------------------------------------------
                      // READ MORE BUTTON
                      // ----------------------------------------------------
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        onTapDown: (_) {
                          _readMoreDown();
                        },

                        onTapUp: (_) {
                          _readMoreUp();
                          widget.onReadMore();
                        },

                        onTapCancel: () {
                          _readMoreUp();
                        },

                        child: AnimatedScale(
                          scale: _readMorePressed ? 0.94 : 1.0,
                          duration: const Duration(milliseconds: 130),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: _readMorePressed
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFF151515),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Read more',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(width: 5),

                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: Colors.white,
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
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70, bottom: 120),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0x0C000000),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_outlined,
              color: Color(0xFF999999),
              size: 32,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'No stories yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'More stories will appear here soon.\n'
            'Check back later.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}
