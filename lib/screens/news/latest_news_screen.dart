// screens/news/latest_news_screen.dart
//
// "News" tab: every story, newest first, as compact fixed-size cards
// (card size never grows with the length of the story).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_article.dart';
import '../../services/app_strings.dart';
import '../../services/news_service.dart';
import '../../widgets/common/app_media_viewer.dart';
import '../../widgets/home/news_bottom_navigation.dart' show kNewsBottomBarSpace;
import '../../widgets/news/news_actions.dart';
import '../home/news_story_page.dart';

class LatestNewsScreen extends StatefulWidget {
  final String selectedLanguage;

  const LatestNewsScreen({super.key, required this.selectedLanguage});

  @override
  State<LatestNewsScreen> createState() => _LatestNewsScreenState();
}

class _LatestNewsScreenState extends State<LatestNewsScreen> with AutomaticKeepAliveClientMixin {
  final List<NewsArticle> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final res = await NewsRepository.instance.page(limit: 20);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _cursor = res.nextCursor;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Could not load news. Pull down to retry.';
      });
    }
  }

  Future<void> _more() async {
    if (_loadingMore || _cursor == null) return;
    _loadingMore = true;
    try {
      final res = await NewsRepository.instance.page(cursor: _cursor, limit: 20);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _cursor = res.nextCursor;
      });
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom + kNewsBottomBarSpace;
    return Container(
      color: const Color(0xFFF4F6FB),
      child: Column(
        children: [
          // Header (sits between the corner menu/profile buttons)
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(60, top + 12, 60, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF3949AB)]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Text(
              AppStrings.t('latest_news', widget.selectedLanguage),
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansTelugu(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) _more();
                        return false;
                      },
                      child: _items.isEmpty
                          ? ListView(children: [
                              const SizedBox(height: 140),
                              Center(child: Text(_error ?? 'No news yet', style: GoogleFonts.inter(color: Colors.black54))),
                            ])
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(12, 12, 12, bottom + 12),
                              itemCount: _items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _NewsTile(article: _items[i], language: widget.selectedLanguage),
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  final NewsArticle article;
  final String language;

  const _NewsTile({required this.article, required this.language});

  @override
  Widget build(BuildContext context) {
    final img = article.thumbUrl.isNotEmpty ? article.thumbUrl : article.imageUrl;
    final video = isVideoUrl(img);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsStoryPage(article: article, selectedLanguage: language)),
        ),
        child: SizedBox(
          height: 128, // fixed: every card is the same size
          child: Row(
            children: [
              SizedBox(
                width: 118,
                height: double.infinity,
                child: img.isEmpty
                    ? Container(color: const Color(0xFFE3E8F4), child: const Icon(Icons.article_outlined, color: Colors.black26))
                    : video
                        ? Container(color: Colors.black87, child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40))
                        : CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, errorWidget: (_, _, _) => Container(color: const Color(0xFFE3E8F4))),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [article.categoryIn(language), article.districtName].where((x) => x.isNotEmpty).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E88E5)),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansTelugu(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.3, color: const Color(0xFF111827)),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(article.publishedAt, style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
                          ),
                          _MiniAction(icon: Icons.favorite_border_rounded, label: article.likeCount > 0 ? '${article.likeCount}' : null, onTap: null),
                          _MiniAction(icon: Icons.mode_comment_outlined, label: article.commentCount > 0 ? '${article.commentCount}' : null, onTap: () => CommentsSheet.show(context, article)),
                          _MiniAction(icon: Icons.share_rounded, color: const Color(0xFF25D366), onTap: () => shareNewsToWhatsApp(article)),
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
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color? color;

  const _MiniAction({required this.icon, this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(children: [
          Icon(icon, size: 17, color: color ?? Colors.black54),
          if (label != null) ...[const SizedBox(width: 3), Text(label!, style: GoogleFonts.inter(fontSize: 11, color: Colors.black54))],
        ]),
      ),
    );
  }
}
