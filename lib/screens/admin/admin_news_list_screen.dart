// screens/admin/admin_news_list_screen.dart
//
// Admin News List: every published story with a clearly visible Delete button.
// Deleting asks for confirmation and removes the story for all readers.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_article.dart';
import '../../services/api_client.dart';
import '../../widgets/common/app_media_viewer.dart';
import '../home/news_story_page.dart';

class AdminNewsListScreen extends StatefulWidget {
  const AdminNewsListScreen({super.key});

  @override
  State<AdminNewsListScreen> createState() => _AdminNewsListScreenState();
}

class _AdminNewsListScreenState extends State<AdminNewsListScreen> {
  final _api = ApiClient.instance;
  final _search = TextEditingController();
  final List<NewsArticle> _items = [];
  final Map<String, String> _status = {};
  String? _cursor;
  bool _loading = true;
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (!more) setState(() => _loading = true);
    try {
      final res = await _api.get('/admin/articles', query: {
        'q': _search.text.trim().isEmpty ? null : _search.text.trim(),
        'cursor': more ? _cursor : null,
        'limit': 30,
      }) as Map;
      final list = <NewsArticle>[];
      for (final raw in res['items'] as List) {
        final m = Map<String, dynamic>.from(raw as Map);
        final a = NewsArticle.fromApi(m);
        _status[a.id] = (m['status'] ?? 'live').toString();
        list.add(a);
      }
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        _items.addAll(list);
        _cursor = res['nextCursor'] as String?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e is ApiException ? e.message : 'Could not load news.');
    }
  }

  Future<void> _delete(NewsArticle a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFC62828), size: 38),
        title: const Text('Delete this news permanently?'),
        content: Text('"${a.title}"\n\nIt will be removed from the app for all readers, including likes and comments. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting.add(a.id));
    try {
      await _api.delete('/admin/articles/${a.id}');
      setState(() => _items.removeWhere((x) => x.id == a.id));
      _snack('News deleted.');
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Could not delete. Please try again.');
    } finally {
      if (mounted) setState(() => _deleting.remove(a.id));
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(title: Text('News List', style: GoogleFonts.inter(fontWeight: FontWeight.w800)), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search by headline or reporter',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                      itemCount: _items.length + (_cursor != null ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        if (i == _items.length) return TextButton(onPressed: () => _load(more: true), child: const Text('Load more'));
                        final a = _items[i];
                        final img = a.thumbUrl.isNotEmpty ? a.thumbUrl : a.imageUrl;
                        final unpublished = _status[a.id] == 'unpublished';
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsStoryPage(article: a, selectedLanguage: 'english'))),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: img.isEmpty || isVideoUrl(img)
                                          ? Container(color: const Color(0xFFEDEDED), child: Icon(isVideoUrl(img) ? Icons.videocam_rounded : Icons.article_outlined, color: Colors.black38))
                                          : CachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansTelugu(fontWeight: FontWeight.w700, fontSize: 14)),
                                        const SizedBox(height: 3),
                                        Text(
                                          [a.author, a.districtName, a.publishedAt, if (unpublished) 'UNPUBLISHED'].where((x) => x.isNotEmpty).join(' • '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(fontSize: 11, color: unpublished ? Colors.orange.shade800 : Colors.black45),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _deleting.contains(a.id)
                                      ? const SizedBox(width: 36, height: 36, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                                      : OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFC62828),
                                            side: const BorderSide(color: Color(0xFFEF9A9A)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          onPressed: () => _delete(a),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                          label: const Text('Delete'),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
