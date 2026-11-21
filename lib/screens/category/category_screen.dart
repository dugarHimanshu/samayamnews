import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/category_repository.dart';
import '../../services/news_service.dart';
import '../../models/news_article.dart';
import '../../services/saved_news_store.dart';
import '../../widgets/common/app_media_viewer.dart';
import '../home/news_story_page.dart';

class CategoryItemInfo {
  final String keyName;
  final String label;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;
  final String description;

  const CategoryItemInfo({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
    required this.description,
  });
}

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
  final SavedNewsStore _savedStore = SavedNewsStore.instance;

  // Selected category for drill-down news view (null = viewing icon grid)
  CategoryItemInfo? _selectedCategory;

  static const List<CategoryItemInfo> _categories = [
    CategoryItemInfo(
      keyName: 'politics',
      label: 'Politics',
      icon: Icons.account_balance_rounded,
      primaryColor: Color(0xFF1E3A8A), // Rich Navy
      accentColor: Color(0xFF3B82F6),
      description: 'Elections, government policies, and national affairs.',
    ),
    CategoryItemInfo(
      keyName: 'business',
      label: 'Business',
      icon: Icons.trending_up_rounded,
      primaryColor: Color(0xFF047857), // Forest Green
      accentColor: Color(0xFF10B981),
      description: 'Markets, economy, startups, and corporate milestones.',
    ),
    CategoryItemInfo(
      keyName: 'technology',
      label: 'Technology',
      icon: Icons.biotech_rounded,
      primaryColor: Color(0xFF6D28D9), // Electric Purple
      accentColor: Color(0xFF8B5CF6),
      description: 'AI breakthroughs, gadgets, software, and cybersecurity.',
    ),
    CategoryItemInfo(
      keyName: 'sports',
      label: 'Sports',
      icon: Icons.sports_cricket_rounded,
      primaryColor: Color(0xFFC2410C), // Deep Crimson/Orange
      accentColor: Color(0xFFF97316),
      description: 'Cricket, football, championships, and athletic feats.',
    ),
    CategoryItemInfo(
      keyName: 'entertainment',
      label: 'Entertainment',
      icon: Icons.movie_filter_rounded,
      primaryColor: Color(0xFFBE185D), // Magenta Pink
      accentColor: Color(0xFFEC4899),
      description: 'Cinema, music, celebrity culture, and web series.',
    ),
    CategoryItemInfo(
      keyName: 'world',
      label: 'World',
      icon: Icons.public_rounded,
      primaryColor: Color(0xFF0369A1), // Sky Deep Blue
      accentColor: Color(0xFF0EA5E9),
      description: 'Global diplomacy, conflict, treaties, and international news.',
    ),
    CategoryItemInfo(
      keyName: 'india',
      label: 'India',
      icon: Icons.flag_rounded,
      primaryColor: Color(0xFFB45309), // Amber/Saffron
      accentColor: Color(0xFFF59E0B),
      description: 'Nationwide headlines, state developments, and social impact.',
    ),
    CategoryItemInfo(
      keyName: 'lifestyle',
      label: 'Lifestyle',
      icon: Icons.spa_rounded,
      primaryColor: Color(0xFF0F766E), // Deep Teal
      accentColor: Color(0xFF14B8A6),
      description: 'Health, wellness, gastronomy, travel, and mindful living.',
    ),
  ];

  final NewsRepository _repo = NewsRepository.instance;
  final Set<String> _requested = {};

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _savedStore.load();
    _repo.addListener(_onRepoChanged);
    CategoryRepository.instance.init();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  Future<void> _toggleBookmark(NewsArticle article) async {
    await _savedStore.toggle(article);
    if (!mounted) return;
    setState(() {});

    final bool saved = _savedStore.isSaved(article.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 90),
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

  void _openArticle(NewsArticle article) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => NewsStoryPage(
          article: article,
          selectedLanguage: widget.selectedLanguage,
        ),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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

  List<NewsArticle> _getArticlesForCategory(String categoryKey) {
    final slug = CategoryRepository.instance.slugFor(categoryKey);
    if (_requested.add(slug)) _repo.loadCategory(slug);
    return _repo.articles.where((a) => a.categorySlug == slug).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _selectedCategory == null
            ? _buildCategoryGrid()
            : _buildCategoryArticlesView(_selectedCategory!),
      ),
    );
  }

  // ============================================================
  // VIEW 1: VIBRANT INTERACTIVE CATEGORY ICONS GRID
  // ============================================================
  Widget _buildCategoryGrid() {
    return CustomScrollView(
      key: const ValueKey('category_grid'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Spacing for GlassHeader
        const SliverToBoxAdapter(child: SizedBox(height: 105)),

        // Section Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB58A3A), Color(0xFFE4C98A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EXPLORE BEATS',
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
                Text(
                  'Categories',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: const Color(0xFF151515),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick a topic to dive into curated stories & live breaking news.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2-Column Grid of Stylish Category Cards
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = _categories[index];
                final articleCount = _getArticlesForCategory(cat.keyName).length;

                return _CategoryCardTile(
                  category: cat,
                  articleCount: articleCount,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                );
              },
              childCount: _categories.length,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VIEW 2: CATEGORY SPECIFIC ARTICLES LIST WITH BACK BUTTON
  // ============================================================
  Widget _buildCategoryArticlesView(CategoryItemInfo category) {
    final articles = _getArticlesForCategory(category.keyName);

    return CustomScrollView(
      key: ValueKey('category_articles_${category.keyName}'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Spacing for GlassHeader
        const SliverToBoxAdapter(child: SizedBox(height: 105)),

        // Category Detail Banner with Back Button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button & category badge
                Row(
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 1,
                      shadowColor: Colors.black12,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 17, color: Colors.black87),
                              SizedBox(width: 6),
                              Text(
                                'All Categories',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: category.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: category.primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(category.icon, size: 14, color: category.primaryColor),
                          const SizedBox(width: 5),
                          Text(
                            '${articles.length} Stories',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: category.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Category Headline Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [category.primaryColor, category.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: category.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(category.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.label,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF151515),
                            ),
                          ),
                          Text(
                            category.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Articles List
        if (articles.isEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.feed_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No articles found in ${category.label}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final article = articles[index];
                  final isBookmarked = _savedStore.isSaved(article.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.035),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _openArticle(article),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Article Hero Image
                            if (article.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: SizedBox(
                                  height: 160,
                                  width: double.infinity,
                                  child: AppMediaViewer(
                                    url: article.imageUrl,
                                    fit: BoxFit.cover,
                                    autoPlay: false,
                                    looping: true,
                                    showControls: true,
                                  ),
                                ),
                              ),

                            // Article Body
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        article.source.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: category.primaryColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        article.publishedAt,
                                        style: const TextStyle(fontSize: 10.5, color: Colors.black45),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    article.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    article.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        'Tap to read full story',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: category.primaryColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          isBookmarked
                                              ? Icons.bookmark_rounded
                                              : Icons.bookmark_border_rounded,
                                          color: isBookmarked ? Colors.amber.shade800 : Colors.black45,
                                          size: 20,
                                        ),
                                        onPressed: () => _toggleBookmark(article),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: articles.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// CATEGORY CARD TILE
// ============================================================================

class _CategoryCardTile extends StatefulWidget {
  final CategoryItemInfo category;
  final int articleCount;
  final VoidCallback onTap;

  const _CategoryCardTile({
    required this.category,
    required this.articleCount,
    required this.onTap,
  });

  @override
  State<_CategoryCardTile> createState() => _CategoryCardTileState();
}

class _CategoryCardTileState extends State<_CategoryCardTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.category.primaryColor.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
              ),
            ],
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Category Icon badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.category.primaryColor,
                            widget.category.accentColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: widget.category.primaryColor.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(widget.category.icon, color: Colors.white, size: 23),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.black26),
                  ],
                ),

                // Title and story count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF151515),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.articleCount > 0 ? '${widget.articleCount} Articles' : 'Explore news',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.category.primaryColor,
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
