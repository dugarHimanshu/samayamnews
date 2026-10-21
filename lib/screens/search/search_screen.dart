import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/demo_news.dart';
import '../../models/news_article.dart';

class SearchScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;

  const SearchScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
    required this.selectedDistrict,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // 1. ValueNotifiers eliminate full-screen rebuilds!
  final ValueNotifier<String> _queryNotifier = ValueNotifier('');
  final ValueNotifier<String> _filterNotifier = ValueNotifier('All');

  // Animated Aurora Background
  late final AnimationController _auroraController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 15),
  )..repeat(reverse: true);

  final List<String> _filters = [
    'All',
    'Politics',
    'Business',
    'Technology',
    'Sports',
    'World',
    'India',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _queryNotifier.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _queryNotifier.dispose();
    _filterNotifier.dispose();
    _auroraController.dispose();
    super.dispose();
  }

  List<NewsArticle> _getFilteredResults(String query, String filter) {
    final q = query.trim().toLowerCase();
    final f = filter.toLowerCase();

    if (q.isEmpty && f == 'all') return [];

    return demoNews.where((article) {
      final matchesQuery =
          q.isEmpty ||
          article.title.toLowerCase().contains(q) ||
          article.description.toLowerCase().contains(q) ||
          article.author.toLowerCase().contains(q);

      final matchesFilter = f == 'all' || article.category.toLowerCase() == f;

      return matchesQuery && matchesFilter;
    }).toList();
  }

  void _openArticle(NewsArticle article) {
    _searchFocusNode.unfocus();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _SearchArticleScreen(article: article);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: Stack(
        children: [
          // ============================================================
          // LUXURY AURORA BACKGROUND
          // ============================================================
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _auroraController,
              builder: (context, child) {
                final value = _auroraController.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -100 + (value * 40),
                      right: -50,
                      child: const _AuroraBlob(
                        size: 350,
                        color: Color(0x33D9C6FF),
                      ), // Soft Purple
                    ),
                    Positioned(
                      top: 150 - (value * 30),
                      left: -100,
                      child: const _AuroraBlob(
                        size: 300,
                        color: Color(0x2EB9E9FF),
                      ), // Soft Blue
                    ),
                  ],
                );
              },
            ),
          ),

          // STATIC FROSTED OVERLAY
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99FFFFFF),
                    Color(0xE6F7F7F5),
                    Color(0xFFF7F7F5),
                  ],
                  stops: [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          // ============================================================
          // MAIN CONTENT
          // ============================================================
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: 96),
              ), // Spacing for MainShell Header
              // 1. HEADER & SEARCH BAR
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
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
                                  colors: [
                                    Color(0xFFB58A3A),
                                    Color(0xFFE4C98A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'DISCOVER',
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
                          'Search',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            letterSpacing: -0.5,
                            color: const Color(0xFF151515),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildGlassSearchBar(),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. FILTER CHIPS
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ValueListenableBuilder<String>(
                    valueListenable: _filterNotifier,
                    builder: (context, currentFilter, _) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          return _BouncyFilterChip(
                            label: filter,
                            isSelected: currentFilter == filter,
                            onTap: () => _filterNotifier.value = filter,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 3. DYNAMIC RESULTS LIST
              // Listens to BOTH query and filter changes
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _queryNotifier,
                    _filterNotifier,
                  ]),
                  builder: (context, _) {
                    final query = _queryNotifier.value;
                    final filter = _filterNotifier.value;
                    final results = _getFilteredResults(query, filter);
                    final isInitial = query.trim().isEmpty && filter == 'All';

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: isInitial
                          ? const _InitialState()
                          : results.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              key: ValueKey('${query}_$filter'),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                120,
                              ), // Spacing for Nav
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: results.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 18),
                              itemBuilder: (context, index) {
                                return _BouncyResultCard(
                                  article: results[index],
                                  onTap: () => _openArticle(results[index]),
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xB3FFFFFF), // White 0.70
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xE6FFFFFF)), // White 0.90
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000), // Black 0.04
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              const Icon(
                Icons.search_rounded,
                size: 22,
                color: Color(0xFF666666),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF222222),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search stories, topics, people...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF999999),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              ValueListenableBuilder<String>(
                valueListenable: _queryNotifier,
                builder: (context, query, _) {
                  if (query.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _searchFocusNode.requestFocus();
                    },
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: Color(0xFF999999),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BOUNCY FILTER CHIP (React-style interaction)
// ============================================================================
class _BouncyFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BouncyFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BouncyFilterChip> createState() => _BouncyFilterChipState();
}

class _BouncyFilterChipState extends State<_BouncyFilterChip> {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          _isPressed ? 0.92 : 1.0,
          _isPressed ? 0.92 : 1.0,
          1.0,
        ),
        transformAlignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF151515)
                : const Color(0x99FFFFFF), // Glass white
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF151515)
                  : const Color(0x66FFFFFF),
              width: 1.2,
            ),
            boxShadow: widget.isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
              color: widget.isSelected ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BOUNCY SEARCH RESULT CARD (Skeuomorphic & Glass)
// ============================================================================
class _BouncyResultCard extends StatefulWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _BouncyResultCard({required this.article, required this.onTap});

  @override
  State<_BouncyResultCard> createState() => _BouncyResultCardState();
}

class _BouncyResultCardState extends State<_BouncyResultCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
            _isPressed ? 0.96 : 1.0,
            _isPressed ? 0.96 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000), // Black 0.045
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: widget.article.imageUrl,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 105,
                    height: 105,
                    child: Image.network(
                      widget.article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFF2F2F0),
                        child: const Icon(
                          Icons.image_outlined,
                          color: Color(0x40000000),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 105,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.article.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: const Color(0xFF151515),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.article.author}  •  ${widget.article.publishedAt}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ],
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

// ============================================================================
// STATES (Initial & Empty)
// ============================================================================
class _InitialState extends StatelessWidget {
  const _InitialState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0x0A000000),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              size: 36,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'What are you looking for?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for stories, topics, authors or explore\nour curated categories above.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0x0A000000),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No stories found',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or\nsearching with different keywords.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ARTICLE DETAIL SCREEN (With Hero & Glass)
// ============================================================================
class _SearchArticleScreen extends StatelessWidget {
  final NewsArticle article;

  const _SearchArticleScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0x4D000000), // Black 0.30
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              title: Text(
                article.category.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              background: Hero(
                tag: article.imageUrl,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(article.imageUrl, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x66000000),
                            Colors.transparent,
                            Color(0xB3000000),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 80),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBEBE6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.author,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF222222),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              article.publishedAt,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E2DD)),
                        ),
                        child: const Icon(
                          Icons.bookmark_outline_rounded,
                          size: 18,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    article.description,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.8,
                      color: const Color(0xFF444444),
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

// ============================================================================
// AURORA BLOB
// ============================================================================
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
            colors: [color, color.withValues(alpha:0.05), Colors.transparent],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}