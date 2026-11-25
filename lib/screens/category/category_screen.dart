// screens/category/category_screen.dart
//
// "Headlines" tab.
//  • Every headline (category) fits on ONE screen — no scrolling. The tile size and
//    font shrink to fit however many headlines the newsroom configures.
//  • The headline list comes from the server (/v1/categories), so changing the
//    list never needs a new app release.
//  • Names are always in the reader's chosen language.
//  • Opening a headline shows its news as pages you turn sideways, with a fixed
//    number of stories per page.

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_article.dart';
import '../../services/app_strings.dart';
import '../../services/category_repository.dart';
import '../../services/news_service.dart';
import '../../widgets/common/app_media_viewer.dart';
import '../../widgets/home/news_bottom_navigation.dart' show kNewsBottomBarSpace;
import '../home/news_story_page.dart';
import '../wishes/wishes_screen.dart';

/// Colour + icon for a headline tile, chosen from its slug (fallbacks rotate).
class _Look {
  final IconData icon;
  final List<Color> colors;
  const _Look(this.icon, this.colors);
}

const Map<String, _Look> _looks = {
  'local': _Look(Icons.location_city_rounded, [Color(0xFFFF7043), Color(0xFFF4511E)]),
  'politics': _Look(Icons.account_balance_rounded, [Color(0xFF3949AB), Color(0xFF283593)]),
  'national': _Look(Icons.flag_rounded, [Color(0xFFFFA726), Color(0xFFEF6C00)]),
  'international': _Look(Icons.public_rounded, [Color(0xFF29B6F6), Color(0xFF0277BD)]),
  'business': _Look(Icons.trending_up_rounded, [Color(0xFF26A69A), Color(0xFF00796B)]),
  'sports': _Look(Icons.sports_cricket_rounded, [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
  'entertainment': _Look(Icons.movie_filter_rounded, [Color(0xFFEC407A), Color(0xFFAD1457)]),
  'technology': _Look(Icons.memory_rounded, [Color(0xFF7E57C2), Color(0xFF4527A0)]),
  'health': _Look(Icons.favorite_rounded, [Color(0xFFEF5350), Color(0xFFC62828)]),
  'education': _Look(Icons.school_rounded, [Color(0xFF5C6BC0), Color(0xFF303F9F)]),
  'crime': _Look(Icons.local_police_rounded, [Color(0xFF78909C), Color(0xFF37474F)]),
  'agriculture': _Look(Icons.agriculture_rounded, [Color(0xFF9CCC65), Color(0xFF558B2F)]),
  'weather': _Look(Icons.cloud_rounded, [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
  'devotional': _Look(Icons.temple_hindu_rounded, [Color(0xFFFFB74D), Color(0xFFE65100)]),
  'cinema': _Look(Icons.theaters_rounded, [Color(0xFFF06292), Color(0xFFC2185B)]),
  'jobs': _Look(Icons.work_rounded, [Color(0xFF4DB6AC), Color(0xFF00695C)]),
};
const List<List<Color>> _fallbackColors = [
  [Color(0xFF8D6E63), Color(0xFF5D4037)],
  [Color(0xFF26C6DA), Color(0xFF00838F)],
  [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
  [Color(0xFFFFCA28), Color(0xFFFF8F00)],
];

class CategoryScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;
  final String selectedDistrict;

  const CategoryScreen({super.key, required this.selectedLanguage, required this.selectedState, required this.selectedDistrict});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> _cats = const [];
  bool _loading = true;

  String get _lang => AppStrings.normalize(widget.selectedLanguage);

  String _name(Category c) => switch (_lang) {
        'telugu' => c.nameTe.isNotEmpty ? c.nameTe : c.nameEn,
        'hindi' => c.nameHi.isNotEmpty ? c.nameHi : c.nameEn,
        _ => c.nameEn,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await CategoryRepository.instance.init();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _cats = CategoryRepository.instance.items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final tiles = <_TileData>[
      for (final (i, c) in _cats.indexed)
        _TileData(
          label: _name(c),
          look: _looks[c.slug] ?? _Look(Icons.article_rounded, _fallbackColors[i % _fallbackColors.length]),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HeadlinePagesScreen(category: c, title: _name(c), language: widget.selectedLanguage)),
          ),
        ),
      _TileData(
        label: AppStrings.t('birthday_wishes', widget.selectedLanguage),
        look: const _Look(Icons.cake_rounded, [Color(0xFFFF80AB), Color(0xFFD81B60)]),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WishesScreen(kind: 'birthday', language: widget.selectedLanguage))),
      ),
      _TileData(
        label: AppStrings.t('anniversary_wishes', widget.selectedLanguage),
        look: const _Look(Icons.favorite_rounded, [Color(0xFFFFB74D), Color(0xFFE53935)]),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WishesScreen(kind: 'anniversary', language: widget.selectedLanguage))),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF8E1), Color(0xFFFFFFFF)]),
      ),
      padding: EdgeInsets.fromLTRB(12, mq.padding.top + 8, 12, mq.padding.bottom + kNewsBottomBarSpace + 6),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Center(
              child: Text(
                AppStrings.t('headlines', widget.selectedLanguage),
                style: GoogleFonts.notoSansTelugu(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFBF360C)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(builder: (context, box) {
                    // Pick the column count whose tiles are closest to square, then size rows to fill exactly.
                    final n = tiles.length;
                    var cols = 3;
                    var best = double.infinity;
                    for (var c = 2; c <= 4; c++) {
                      final rows = (n / c).ceil();
                      final w = box.maxWidth / c, h = box.maxHeight / rows;
                      final score = (w / h - 1.1).abs();
                      if (score < best) {
                        best = score;
                        cols = c;
                      }
                    }
                    final rows = (n / cols).ceil();
                    const gap = 8.0;
                    final tileW = (box.maxWidth - gap * (cols - 1)) / cols;
                    final tileH = (box.maxHeight - gap * (rows - 1)) / rows;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [for (final t in tiles) SizedBox(width: tileW, height: tileH, child: _HeadlineTile(data: t))],
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

class _TileData {
  final String label;
  final _Look look;
  final VoidCallback onTap;
  const _TileData({required this.label, required this.look, required this.onTap});
}

class _HeadlineTile extends StatelessWidget {
  final _TileData data;
  const _HeadlineTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight);
      return Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: data.look.colors.last.withValues(alpha: 0.4),
        child: Ink(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: data.look.colors)),
          child: InkWell(
            onTap: data.onTap,
            child: Padding(
              padding: EdgeInsets.all(s * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(s * 0.08),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                    child: Icon(data.look.icon, color: Colors.white, size: s * 0.28),
                  ),
                  SizedBox(height: s * 0.06),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: box.maxWidth * 0.95),
                        child: Text(
                          data.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.notoSansTelugu(fontSize: (s * 0.13).clamp(11.0, 16.0), fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
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
    });
  }
}

// ============================================================================
// One headline's news, as pages turned sideways (fixed 4 stories per page)
// ============================================================================

class HeadlinePagesScreen extends StatefulWidget {
  final Category category;
  final String title;
  final String language;

  const HeadlinePagesScreen({super.key, required this.category, required this.title, required this.language});

  @override
  State<HeadlinePagesScreen> createState() => _HeadlinePagesScreenState();
}

class _HeadlinePagesScreenState extends State<HeadlinePagesScreen> {
  static const perPage = 4; // fixed by the page design
  final _pager = PageController();
  final List<NewsArticle> _items = [];
  String? _cursor;
  bool _loading = true;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pager.addListener(() => setState(() => _page = _pager.page ?? 0));
    _load();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    try {
      final res = await NewsRepository.instance.page(category: widget.category.slug, cursor: more ? _cursor : null, limit: 24);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _cursor = res.nextCursor;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = (_items.length / perPage).ceil();
    final look = _looks[widget.category.slug];
    final colors = look?.colors ?? _fallbackColors.first;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        backgroundColor: colors.last,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: GoogleFonts.notoSansTelugu(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          if (pages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${_page.round() + 1} / $pages', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text('No news in this headline yet', style: GoogleFonts.inter(color: Colors.black54)))
              : PageView.builder(
                  controller: _pager,
                  itemCount: pages,
                  onPageChanged: (i) {
                    if (i >= pages - 2 && _cursor != null) _load(more: true);
                  },
                  itemBuilder: (_, p) {
                    // Page-turn effect: the page rotates around its left edge as you swipe.
                    final delta = (p - _page).clamp(-1.0, 1.0);
                    final slice = _items.skip(p * perPage).take(perPage).toList();
                    return Transform(
                      alignment: delta > 0 ? Alignment.centerLeft : Alignment.centerRight,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(delta * -0.9),
                      child: Opacity(
                        opacity: (1 - delta.abs() * 0.5).clamp(0.0, 1.0),
                        child: _NewsPage(articles: slice, language: widget.language, accent: colors.last),
                      ),
                    );
                  },
                ),
    );
  }
}

class _NewsPage extends StatelessWidget {
  final List<NewsArticle> articles;
  final String language;
  final Color accent;

  const _NewsPage({required this.articles, required this.language, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(2, 6))],
      ),
      child: Column(
        children: [
          for (var i = 0; i < _HeadlinePagesScreenState.perPage; i++) ...[
            if (i > 0) Divider(height: 10, color: Colors.black.withValues(alpha: 0.08)),
            // Every slot has the same height whether or not a story fills it.
            Expanded(child: i < articles.length ? _StoryCell(article: articles[i], language: language, accent: accent) : const SizedBox()),
          ],
        ],
      ),
    );
  }
}

class _StoryCell extends StatelessWidget {
  final NewsArticle article;
  final String language;
  final Color accent;

  const _StoryCell({required this.article, required this.language, required this.accent});

  @override
  Widget build(BuildContext context) {
    final img = article.thumbUrl.isNotEmpty ? article.thumbUrl : article.imageUrl;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsStoryPage(article: article, selectedLanguage: language))),
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: img.isEmpty
                  ? Container(color: accent.withValues(alpha: 0.12))
                  : isVideoUrl(img)
                      ? Container(color: Colors.black87, child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white))
                      : CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, errorWidget: (_, _, _) => Container(color: accent.withValues(alpha: 0.12))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansTelugu(fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.3, color: const Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 4),
                Text(
                  [article.districtName, article.publishedAt].where((x) => x.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: accent, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
