import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_article.dart';
import '../../services/saved_news_store.dart';
import '../home/news_story_page.dart';

class SavedScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;

  const SavedScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
    required this.selectedDistrict,
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _selectedCategory = 'All';

  final SavedNewsStore _store = SavedNewsStore.instance;

  @override
  void initState() {
    super.initState();

    _store.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    await _store.load();

    if (!mounted) return;

    setState(() {});
  }

  void _refresh() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  List<String> get _categories {
    final categories = <String>{
      'All',
      ..._store.savedArticles.map((article) => article.category).where((c) => c.isNotEmpty),
    };

    return categories.toList();
  }

  // ============================================================
  // SAVED ARTICLES
  // ============================================================

  List<NewsArticle> get _savedArticles {
    final saved = _store.savedArticles;

    if (_selectedCategory == 'All') {
      return saved.toList();
    }

    return saved
        .where(
          (article) =>
              article.category.toLowerCase() == _selectedCategory.toLowerCase(),
        )
        .toList();
  }

  // ============================================================
  // OPEN FULL STORY
  // ============================================================

  void _openStory(NewsArticle article) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
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
                begin: const Offset(0, 0.04),
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
    final articles = _savedArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ==================================================
            // PREMIUM HEADER
            // ==================================================
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 75, 22, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ----------------------------------------
                      // SECTION LABEL
                      // ----------------------------------------
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
                            'SAVED',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: const Color(0xFFB18A48),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ----------------------------------------
                      // MAIN TITLE
                      // ----------------------------------------
                      Text(
                        'Your saved stories.',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: -0.5,
                          color: const Color(0xFF151515),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Stories you want to come back to.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.5,
                          color: const Color(0xFF777777),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------
                      // CATEGORY FILTERS
                      // ----------------------------------------
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final selected = category == _selectedCategory;

                            return _CategoryPill(
                              label: category,
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------
                      // SAVED COUNT
                      // ----------------------------------------
                      if (articles.isNotEmpty)
                        Row(
                          children: [
                            Text(
                              '${articles.length}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF222222),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              articles.length == 1
                                  ? 'saved story'
                                  : 'saved stories',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================
            if (articles.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptySavedState(category: _selectedCategory),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                sliver: SliverList.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];

                    return _SavedNewsCard(
                      article: article,
                      onTap: () => _openStory(article),
                      onRemove: () async {
                        await _store.remove(article.id);
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

// ================================================================
// CATEGORY PILL
// ================================================================

class _CategoryPill extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressed = false;
        });

        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _pressed = false;
        });
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.selected ? const Color(0xFF151515) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.selected
                  ? const Color(0xFF151515)
                  : const Color(0x18000000),
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.09),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
              color: widget.selected ? Colors.white : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SAVED NEWS CARD
// ================================================================

class _SavedNewsCard extends StatefulWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedNewsCard({
    required this.article,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_SavedNewsCard> createState() => _SavedNewsCardState();
}

class _SavedNewsCardState extends State<_SavedNewsCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTapDown: (_) {
          setState(() {
            _pressed = true;
          });
        },

        onTapUp: (_) {
          setState(() {
            _pressed = false;
          });

          widget.onTap();
        },

        onTapCancel: () {
          setState(() {
            _pressed = false;
          });
        },

        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withValues(alpha: 0.035)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ==================================================
                // IMAGE
                // ==================================================
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 105,
                    height: 105,
                    child: Image.network(
                      widget.article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF0F0EE),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 24,
                            color: Colors.black26,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 13),

                // ==================================================
                // ARTICLE INFORMATION
                // ==================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --------------------------------------------
                      // CATEGORY
                      // --------------------------------------------
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFB18A48),
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Expanded(
                            child: Text(
                              widget.article.category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: const Color(0xFF9C7A43),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // --------------------------------------------
                      // TITLE
                      // --------------------------------------------
                      Text(
                        widget.article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: const Color(0xFF171717),
                        ),
                      ),

                      const SizedBox(height: 7),

                      // --------------------------------------------
                      // AUTHOR / TIME
                      // --------------------------------------------
                      Text(
                        '${widget.article.author} • ${widget.article.publishedAt}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.black38,
                        ),
                      ),

                      const SizedBox(height: 9),

                      // --------------------------------------------
                      // READ MORE
                      // --------------------------------------------
                      Row(
                        children: [
                          Text(
                            'READ MORE',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: const Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Color(0xFF222222),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 3),

                // ==================================================
                // BOOKMARK
                // ==================================================
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onRemove,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.bookmark_rounded,
                        size: 21,
                        color: const Color(0xFF171717),
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

// ================================================================
// EMPTY SAVED STATE
// ================================================================

class _EmptySavedState extends StatelessWidget {
  final String category;

  const _EmptySavedState({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 90),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ----------------------------------------------------
            // ICON
            // ----------------------------------------------------
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.045),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                size: 32,
                color: Colors.black38,
              ),
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------
            // TITLE
            // ----------------------------------------------------
            Text(
              category == 'All'
                  ? 'Nothing saved yet'
                  : 'No saved $category news',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 25,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF151515),
              ),
            ),

            const SizedBox(height: 9),

            // ----------------------------------------------------
            // DESCRIPTION
            // ----------------------------------------------------
            Text(
              'Bookmark a story and it will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.45,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
