// widgets/news/news_actions.dart
//
// The Like · Share (WhatsApp) · Comment bar shown on every news page, the WhatsApp
// share helper, and the comments sheet.

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/news_article.dart';
import '../../screens/home/onboarding/welcome_screen.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/news_service.dart';

const _whatsAppGreen = Color(0xFF25D366);

/// Opens WhatsApp with the story; falls back to the system share sheet.
Future<void> shareNewsToWhatsApp(NewsArticle a, {String? title, String? summary}) async {
  final text = [
    '*${(title ?? a.title).trim()}*',
    if ((summary ?? a.description).trim().isNotEmpty) (summary ?? a.description).trim(),
    '— Samayam News',
  ].join('\n\n');
  Analytics.instance.track('share', a.id);
  final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {}
  await SharePlus.instance.share(ShareParams(text: text));
}

/// Big, clearly labelled action buttons: Like, Share, Comment (+ small Save).
class NewsActionBar extends StatelessWidget {
  final NewsArticle article;
  final bool liked;
  final int likeCount;
  final int commentCount;
  final bool bookmarked;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback? onBookmark;
  final bool dark;

  const NewsActionBar({
    super.key,
    required this.article,
    required this.liked,
    required this.likeCount,
    required this.commentCount,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    this.bookmarked = false,
    this.onBookmark,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20, color: liked ? const Color(0xFFE53935) : (dark ? Colors.white : const Color(0xFF1F2937))),
            label: likeCount > 0 ? 'Like · $likeCount' : 'Like',
            onTap: onLike,
            dark: dark,
            highlight: liked ? const Color(0xFFFFEBEE) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionPill(
            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 19, color: _whatsAppGreen),
            label: 'Share',
            onTap: onShare,
            dark: dark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionPill(
            icon: Icon(Icons.mode_comment_outlined, size: 19, color: dark ? Colors.white : const Color(0xFF1F2937)),
            label: commentCount > 0 ? 'Comment · $commentCount' : 'Comment',
            onTap: onComment,
            dark: dark,
          ),
        ),
        if (onBookmark != null) ...[
          const SizedBox(width: 6),
          InkResponse(
            onTap: onBookmark,
            radius: 22,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 22,
                color: bookmarked ? const Color(0xFF6D28D9) : (dark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool dark;
  final Color? highlight;

  const _ActionPill({required this.icon, required this.label, required this.onTap, this.dark = false, this.highlight});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ?? (dark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFF3F4F6)),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: dark ? Colors.white : const Color(0xFF111827)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with the article's comments and a box to add one.
class CommentsSheet extends StatefulWidget {
  final NewsArticle article;
  final ValueChanged<int>? onCountChanged;

  const CommentsSheet({super.key, required this.article, this.onCountChanged});

  static Future<void> show(BuildContext context, NewsArticle article, {ValueChanged<int>? onCountChanged}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(article: article, onCountChanged: onCountChanged),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _input = TextEditingController();
  final List<NewsComment> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String? _myId;
  String? _myRole;

  bool get _signedIn => Supabase.instance.client.auth.currentSession != null;

  @override
  void initState() {
    super.initState();
    _myId = Supabase.instance.client.auth.currentUser?.id;
    if (_signedIn) {
      AuthService.instance.getCurrentUserProfile().then((p) {
        if (mounted) setState(() => _myRole = p?['role']?.toString());
      }).catchError((_) {});
    }
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    try {
      final res = await CommunityService.instance.comments(widget.article.id, cursor: more ? _cursor : null);
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        _items.addAll(res.items);
        _cursor = res.nextCursor;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Could not load comments.';
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final c = await CommunityService.instance.addComment(widget.article.id, text);
      _input.clear();
      setState(() => _items.insert(0, c));
      widget.onCountChanged?.call(_items.length);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not post your comment. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(NewsComment c) async {
    try {
      await CommunityService.instance.deleteComment(c.id);
      setState(() => _items.removeWhere((x) => x.id == c.id));
      widget.onCountChanged?.call(_items.length);
    } catch (_) {
      _snack('Could not delete the comment.');
    }
  }

  void _snack(String m) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m)));

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
              child: Row(
                children: [
                  Text('Comments', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Text('${_items.length}${_cursor != null ? '+' : ''}', style: GoogleFonts.inter(color: Colors.black45, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _items.isEmpty
                      ? Center(child: Text(_error!, style: GoogleFonts.inter(color: Colors.black54)))
                      : _items.isEmpty
                          ? Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.forum_outlined, size: 44, color: Colors.black26),
                                const SizedBox(height: 8),
                                Text('Be the first to comment', style: GoogleFonts.inter(color: Colors.black54)),
                              ]),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              itemCount: _items.length + (_cursor != null ? 1 : 0),
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                if (i == _items.length) {
                                  return TextButton(onPressed: () => _load(more: true), child: const Text('Load more'));
                                }
                                final c = _items[i];
                                final canDelete = c.userId == _myId || _myRole == 'admin' || _myRole == 'editor';
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: const Color(0xFFEDE9FE),
                                      child: Text(c.author.isEmpty ? '?' : c.author[0].toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF5B21B6))),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Flexible(child: Text(c.author, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13))),
                                            const SizedBox(width: 6),
                                            Text(_ago(c.createdAt), style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
                                          ]),
                                          const SizedBox(height: 2),
                                          Text(c.body, style: GoogleFonts.inter(fontSize: 14, height: 1.35)),
                                        ],
                                      ),
                                    ),
                                    if (canDelete)
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.black38),
                                        onPressed: () => _delete(c),
                                      ),
                                  ],
                                );
                              },
                            ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: _signedIn
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _input,
                              maxLength: 1000,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'Write a comment…',
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF111827)),
                            onPressed: _sending ? null : _send,
                            icon: _sending
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
                          },
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Sign in to comment'),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
