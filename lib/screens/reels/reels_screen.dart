// screens/reels/reels_screen.dart
//
// "Reels" tab: full-screen, swipe-up feed of news stories that have a video.
// Only the video on screen plays, and nothing plays while another tab is open.

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../models/news_article.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/api_client.dart';
import '../../services/app_strings.dart';
import '../../services/news_service.dart';
import '../../widgets/home/news_bottom_navigation.dart' show kNewsBottomBarSpace;
import '../../widgets/news/news_actions.dart';
import '../home/news_story_page.dart';

class ReelsScreen extends StatefulWidget {
  final String selectedLanguage;
  final ValueNotifier<int> active; // current bottom-bar tab
  final int tabIndex;

  const ReelsScreen({super.key, required this.selectedLanguage, required this.active, required this.tabIndex});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final List<NewsArticle> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _loaded = false;
  int _page = 0;

  bool get _tabActive => widget.active.value == widget.tabIndex;

  @override
  void initState() {
    super.initState();
    widget.active.addListener(_onTab);
  }

  @override
  void dispose() {
    widget.active.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (_tabActive && !_loaded) _load();
    setState(() {}); // play / pause
  }

  Future<void> _load() async {
    _loaded = true;
    try {
      final res = await NewsRepository.instance.page(videoOnly: true, limit: 10);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _cursor = res.nextCursor;
        _loading = false;
      });
    } catch (_) {
      _loaded = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _more() async {
    if (_cursor == null) return;
    final c = _cursor;
    _cursor = null;
    try {
      final res = await NewsRepository.instance.page(videoOnly: true, cursor: c, limit: 10);
      if (mounted) setState(() {
        _items.addAll(res.items);
        _cursor = res.nextCursor;
      });
    } catch (_) {
      _cursor = c;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded && _tabActive) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    return Container(
      color: Colors.black,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white70))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.play_circle_outline_rounded, color: Colors.white38, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        '${AppStrings.t('reels', widget.selectedLanguage)}\nVideo news will appear here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 15, height: 1.5),
                      ),
                      TextButton(onPressed: () { setState(() => _loading = true); _load(); }, child: const Text('Refresh')),
                    ]),
                  ),
                )
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _items.length,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    if (i >= _items.length - 3) _more();
                  },
                  itemBuilder: (_, i) => _Reel(
                    article: _items[i],
                    playing: _tabActive && i == _page,
                    language: widget.selectedLanguage,
                  ),
                ),
    );
  }
}

class _Reel extends StatefulWidget {
  final NewsArticle article;
  final bool playing;
  final String language;

  const _Reel({required this.article, required this.playing, required this.language});

  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _failed = false;
  bool _liked = false;
  late int _comments = widget.article.commentCount;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.article.imageUrl))
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _sync();
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
  }

  @override
  void didUpdateWidget(covariant _Reel old) {
    super.didUpdateWidget(old);
    _sync();
  }

  Future<void> _toggleLike() async {
    setState(() => _liked = !_liked);
    if (Supabase.instance.client.auth.currentSession == null) return;
    try {
      _liked ? await ApiClient.instance.put('/me/likes/${widget.article.id}') : await ApiClient.instance.delete('/me/likes/${widget.article.id}');
    } catch (_) {}
  }

  void _sync() {
    if (!_ready || _c == null) return;
    widget.playing ? _c!.play() : _c!.pause();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + kNewsBottomBarSpace;
    final a = widget.article;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            if (!_ready) return;
            _c!.value.isPlaying ? _c!.pause() : _c!.play();
            setState(() {});
          },
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: _failed
                ? const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 56)
                : !_ready
                    ? const CircularProgressIndicator(color: Colors.white54)
                    : AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)),
          ),
        ),
        // readability gradient
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.transparent, Color(0xCC000000)], stops: [0, 0.55, 1]),
            ),
          ),
        ),
        // Title + read more
        Positioned(
          left: 16,
          right: 84,
          bottom: bottom + 14,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsStoryPage(article: a, selectedLanguage: widget.language))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.districtName.isNotEmpty)
                  Text(a.districtName, style: GoogleFonts.inter(color: const Color(0xFFFFD54F), fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 4),
                Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansTelugu(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 4),
                Text('Read full story →', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        // Like · Share · Comment on the right
        Positioned(
          right: 10,
          bottom: bottom + 14,
          child: Column(
            children: [
              _ReelButton(
                icon: Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _liked ? const Color(0xFFFF5252) : Colors.white, size: 30),
                label: '${a.likeCount + (_liked ? 1 : 0)}',
                onTap: _toggleLike,
              ),
              _ReelButton(
                icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 30),
                label: 'Share',
                onTap: () => shareNewsToWhatsApp(a),
              ),
              _ReelButton(
                icon: const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 28),
                label: '$_comments',
                onTap: () => CommentsSheet.show(context, a, onCountChanged: (n) => setState(() => _comments = n)),
              ),
            ],
          ),
        ),
        if (_ready && !_c!.value.isPlaying && widget.playing)
          const IgnorePointer(child: Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 80))),
      ],
    );
  }
}

class _ReelButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _ReelButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(children: [
          icon,
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
