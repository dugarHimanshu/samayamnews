import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/demo_news.dart';
import '../../models/news_article.dart';
import '../../services/news_service.dart';
import '../../services/saved_news_store.dart';
import '../../services/article_translator.dart';

// ============================================================
// LAYOUT CONFIG
// ============================================================

enum DeviceType { mobile, foldable, tablet, desktop }

class NewsLayoutConfig {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final shortest = MediaQuery.of(context).size.shortestSide;
    if (width < 320 || (width >= 280 && width <= 360 && shortest < 450)) {
      return DeviceType.foldable;
    }
    if (width < 600) return DeviceType.mobile;
    if (width < 1024) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static double maxWidth(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.foldable:
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 680;
      case DeviceType.desktop:
        return 780;
    }
  }

  static double heroHeight(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return h < 600 ? h * 0.35 : h * 0.40;
  }
}

// ============================================================
// NEWS HOME SCREEN
// ============================================================

class NewsHomeScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;
  final ValueChanged<bool>? onChromeVisibilityChanged;

  const NewsHomeScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
    required this.selectedDistrict,
    this.onChromeVisibilityChanged,
  });

  @override
  State<NewsHomeScreen> createState() => _NewsHomeScreenState();
}

class _NewsHomeScreenState extends State<NewsHomeScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final NewsService _newsService = NewsService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final SavedNewsStore _savedStore = SavedNewsStore.instance;

  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  int _currentPage = 0;
  bool _showHeader = true;
  double _lastPage = 0;
  final Set<int> _liked = {};
  RealtimeChannel? _channel;
  static const int _newsPerAd = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _savedStore.load();
    _pageController.addListener(_onScroll);
    _loadNews();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant NewsHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedState != widget.selectedState ||
        oldWidget.selectedDistrict != widget.selectedDistrict ||
        oldWidget.selectedLanguage != widget.selectedLanguage) {
      _loadNews();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSilently();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
    }
    super.dispose();
  }

  void _subscribe() {
    if (_channel != null) return;
    _channel = _supabase
        .channel('news-feed')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'news_articles',
          callback: (_) => _refreshSilently(),
        )
        .subscribe();
  }

  Future<void> _refreshSilently() async {
    try {
      final live = await _newsService.fetchNews(
        state: widget.selectedState,
        district: widget.selectedDistrict,
      );
      if (!mounted) return;
      setState(() => _articles = _merge(live));
    } catch (_) {}
  }

  List<NewsArticle> _merge(List<NewsArticle> live) {
    final res = <NewsArticle>[];
    final ids = <String>{};
    final titles = <String>{};
    for (var a in [...live, ...demoNews]) {
      final id = a.id.trim();
      final title = a.title.trim().toLowerCase();
      if ((id.isNotEmpty && ids.contains(id)) ||
          (title.isNotEmpty && titles.contains(title))) {
        continue;
      }
      if (id.isNotEmpty) ids.add(id);
      if (title.isNotEmpty) titles.add(title);
      res.add(a);
    }
    return res;
  }

  Future<void> _loadNews({bool refresh = false}) async {
    setState(() {
      if (!refresh) {
        _isLoading = true;
      }
    });

    try {
      final live = await _newsService.fetchNews(
        state: widget.selectedState,
        district: widget.selectedDistrict,
      );
      if (!mounted) return;
      setState(() {
        _articles = _merge(live);
        _isLoading = false;
        _currentPage = 0;
        _lastPage = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _articles = _merge([]);
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? 0;
    if (page > _lastPage + 0.02 && _showHeader) {
      _showHeader = false;
      widget.onChromeVisibilityChanged?.call(false);
    } else if ((page < _lastPage - 0.02 || page <= 0.05) && !_showHeader) {
      _showHeader = true;
      widget.onChromeVisibilityChanged?.call(true);
    }
    _lastPage = page;
  }

  void _toggleChrome() {
    setState(() {
      _showHeader = !_showHeader;
      widget.onChromeVisibilityChanged?.call(_showHeader);
    });
  }

  int _totalPages() => _articles.isEmpty
      ? 0
      : _articles.length + (_articles.length ~/ _newsPerAd);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF8F8F6),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.black54),
        ),
      );
    }

    if (_articles.isEmpty) {
      return Container(
        color: const Color(0xFFF8F8F6),
        child: Center(
          child: OutlinedButton(
            onPressed: () => _loadNews(refresh: true),
            child: const Text('REFRESH'),
          ),
        ),
      );
    }

    final total = _totalPages();
    const adBlock = _newsPerAd + 1;

    return Container(
      color: const Color(0xFFF8F8F6),
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleChrome,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const ClampingScrollPhysics(),
              itemCount: total,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                if ((index + 1) % adBlock == 0) return const _AdPage();
                final newsIdx = index - (index ~/ adBlock);
                if (newsIdx >= _articles.length) return const SizedBox();
                final article = _articles[newsIdx];

                return _SinglePageStory(
                  key: ValueKey(
                    article.id.isNotEmpty
                        ? article.id
                        : '${article.title}-$newsIdx',
                  ),
                  article: article,
                  liked: _liked.contains(newsIdx),
                  bookmarked: _savedStore.isSaved(article.title),
                  onLike: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (_liked.contains(newsIdx)) {
                        _liked.remove(newsIdx);
                      } else {
                        _liked.add(newsIdx);
                      }
                    });
                  },
                  onBookmark: () async {
                    await _savedStore.toggle(article.title);
                    setState(() {});
                  },
                  selectedLanguage: widget.selectedLanguage,
                  selectedDistrict: widget.selectedDistrict,
                );
              },
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 70,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentPage + 1}/$total',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SINGLE PAGE STORY VIEW
// ============================================================

class _SinglePageStory extends StatefulWidget {
  final NewsArticle article;
  final bool liked;
  final bool bookmarked;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final String selectedLanguage;
  final String selectedDistrict;

  const _SinglePageStory({
    super.key,
    required this.article,
    required this.liked,
    required this.bookmarked,
    required this.onLike,
    required this.onBookmark,
    required this.selectedLanguage,
    required this.selectedDistrict,
  });

  @override
  State<_SinglePageStory> createState() => _SinglePageStoryState();
}

class _SinglePageStoryState extends State<_SinglePageStory> {
  bool _isTranslating = false;
  late String _lang;
  late String _title, _desc, _body;

  @override
  void initState() {
    super.initState();
    _lang = widget.selectedLanguage;
    _initContent();
    if (_lang != 'English' &&
        ArticleTranslator.languageCodes.containsKey(_lang)) {
      _translate(_lang);
    }
  }

  void _initContent() {
    _title = widget.article.title;
    _desc = widget.article.description;
    _body = widget.article.content.isNotEmpty
        ? widget.article.content
        : widget.article.description;
  }

  @override
  void didUpdateWidget(covariant _SinglePageStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.id != widget.article.id ||
        oldWidget.selectedLanguage != widget.selectedLanguage) {
      _lang = widget.selectedLanguage;
      _initContent();
      if (_lang != 'English' &&
          ArticleTranslator.languageCodes.containsKey(_lang)) {
        _translate(_lang);
      }
    }
  }

  Future<void> _translate(String target) async {
    setState(() => _isTranslating = true);
    try {
      final translatedMap = await ArticleTranslator.translateArticle(
        title: widget.article.title,
        description: widget.article.description,
        body: widget.article.content.isNotEmpty
            ? widget.article.content
            : widget.article.description,
        targetLanguage: target,
      );

      if (!mounted) return;
      setState(() {
        _title = translatedMap['title'] ?? _title;
        _desc = translatedMap['description'] ?? _desc;
        _body = translatedMap['body'] ?? _body;
        _isTranslating = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _showLangPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Read in',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...ArticleTranslator.languageCodes.keys.map(
              (l) => ListTile(
                title: Text(
                  l,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                trailing: l == _lang ? const Icon(Icons.check, size: 18) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _lang = l);
                  _translate(l);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroH = NewsLayoutConfig.heroHeight(context);
    final maxW = NewsLayoutConfig.maxWidth(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HERO IMAGE + WATERMARKS
            SizedBox(
              height: heroH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.article.imageUrl.isEmpty
                      ? Container(color: Colors.grey.shade200)
                      : CachedNetworkImage(
                          imageUrl: widget.article.imageUrl,
                          fit: BoxFit.cover,
                        ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black38,
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                  // TOP RIGHT WATERMARK
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Image.asset(
                      'assets/public/images/watermark/watermark_top_right.png',
                      width: 74,
                      height: 74,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  // BOTTOM LEFT WATERMARK
                  Positioned(
                    bottom: -32,
                    left: -4, // Pushes it further to the left (off-screen)
                    child: Image.asset(
                      'assets/public/images/watermark/watermark_bottom_left.png',
                      width: 250, // Larger width
                      height: 100, // Larger height
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomLeft,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.article.category.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ARTICLE INFO & COMPACT CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title displays fully with no cut-off
                        Text(
                          _title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          color: Colors.black.withValues(
                            alpha: 0.5,
                          ), // Subtle divider color
                          thickness: 1, // Line thickness
                          height: 1, // Space taken by the divider widget
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _desc,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _body,
                          maxLines: 9,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    // ACTIONS + FOOTER INFO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.article.author.isEmpty ? widget.article.source : widget.article.author} • ${widget.article.publishedAt}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                widget.liked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: widget.liked
                                    ? Colors.red
                                    : Colors.black54,
                              ),
                              onPressed: widget.onLike,
                            ),
                            IconButton(
                              icon: Icon(
                                widget.bookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                size: 20,
                                color: widget.bookmarked
                                    ? Colors.deepPurple
                                    : Colors.black54,
                              ),
                              onPressed: widget.onBookmark,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.share_outlined,
                                size: 20,
                                color: Colors.black54,
                              ),
                              onPressed: () => SharePlus.instance.share(
                                ShareParams(
                                  text: '$_title\n\n$_desc\n\n$_body',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: _isTranslating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.translate,
                                      size: 20,
                                      color: Colors.black54,
                                    ),
                              onPressed: _showLangPicker,
                            ),
                          ],
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
    );
  }
}

// ============================================================
// AD PAGE
// ============================================================

class _AdPage extends StatelessWidget {
  const _AdPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F1EC),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.campaign_outlined,
                size: 36,
                color: Colors.black54,
              ),
              const SizedBox(height: 12),
              Text(
                'ADVERTISEMENT',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your story continues here.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
