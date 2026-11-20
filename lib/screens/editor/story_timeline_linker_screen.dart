import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_article.dart';
import '../../models/story_timeline.dart';
import '../../services/editor_service.dart';
import '../../services/story_timeline_service.dart';
import '../../utils/display_formatters.dart';

/// Dedicated screen for Editors and Admins to link and organize
/// related news articles into chronological story threads.
class StoryTimelineLinkerScreen extends StatefulWidget {
  final NewsArticle mainArticle;
  final List<NewsArticle>? allPublishedNews;

  const StoryTimelineLinkerScreen({
    super.key,
    required this.mainArticle,
    this.allPublishedNews,
  });

  @override
  State<StoryTimelineLinkerScreen> createState() => _StoryTimelineLinkerScreenState();
}

class _StoryTimelineLinkerScreenState extends State<StoryTimelineLinkerScreen> {
  final StoryTimelineService _timelineService = StoryTimelineService.instance;
  final EditorService _editorService = EditorService();

  late final TextEditingController _titleController;
  final TextEditingController _searchController = TextEditingController();

  List<NewsArticle> _allNews = [];
  bool _loading = false;
  bool _saving = false;

  late Set<String> _selectedArticleIds;
  StoryTimeline? _existingTimeline;

  @override
  void initState() {
    super.initState();

    _existingTimeline = _timelineService.getTimelineForArticle(widget.mainArticle.id);
    _selectedArticleIds = Set<String>.from(_existingTimeline?.articleIds ?? [widget.mainArticle.id]);

    final defaultTitle = _existingTimeline?.title ?? '${widget.mainArticle.category}: ${widget.mainArticle.title}';
    _titleController = TextEditingController(text: defaultTitle);

    _searchController.addListener(() => setState(() {}));

    _loadArticles();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    if (widget.allPublishedNews != null && widget.allPublishedNews!.isNotEmpty) {
      _allNews = widget.allPublishedNews!;
      setState(() {});
      return;
    }

    setState(() => _loading = true);
    try {
      final fetched = await _editorService.fetchPublishedNews();
      if (mounted) {
        setState(() {
          _allNews = fetched;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<NewsArticle> get _filteredCandidates {
    final query = _searchController.text.trim().toLowerCase();
    return _allNews.where((a) {
      if (a.id == widget.mainArticle.id) return false; // Main article is always included
      if (query.isEmpty) return true;
      return a.title.toLowerCase().contains(query) ||
          a.category.toLowerCase().contains(query) ||
          a.location.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _saveTimeline() async {
    setState(() => _saving = true);
    try {
      final followUpIds = _selectedArticleIds.where((id) => id != widget.mainArticle.id).toList();

      await _timelineService.linkArticlesToMain(
        mainArticleId: widget.mainArticle.id,
        relatedArticleIds: followUpIds,
        topicTitle: _titleController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Story Timeline updated! ${followUpIds.length + 1} articles linked chronologically.',
          ),
          backgroundColor: const Color(0xFF166534),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update story timeline. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _unlinkAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink All Developments?'),
        content: const Text(
          'This will remove the chronological link between these articles. Each article will remain published individually.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (_existingTimeline != null) {
      await _timelineService.deleteTimeline(_existingTimeline!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timeline removed.'), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        title: Text(
          'Link Follow-up Stories',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          if (_existingTimeline != null)
            IconButton(
              icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
              tooltip: 'Unlink Timeline',
              onPressed: _unlinkAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black87))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Topic Title Card
                _buildTopicTitleCard(),

                const SizedBox(height: 16),

                // 2. Main Story Anchor Card
                _buildMainStoryCard(),

                const SizedBox(height: 16),

                // 3. Chronological Linked Preview
                _buildChronologicalTimelinePreview(),

                const SizedBox(height: 16),

                // 4. Select Follow-Up Articles from published list
                _buildCandidateSelector(),

                const SizedBox(height: 80),
              ],
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saving ? null : _saveTimeline,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _saving
                    ? 'Saving Timeline...'
                    : 'Save Chronological Timeline (${_selectedArticleIds.length} Linked)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicTitleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timeline_rounded, color: Colors.blueAccent, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Story Thread / Topic Name',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Readers will see this topic header linking all follow-up developments together in chronological order.',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9F9F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5E2)),
              ),
              hintText: 'e.g. Hyderabad Metro Phase 2: Latest Updates',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF166534),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MAIN / ORIGINAL REPORT',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              Text(
                widget.mainArticle.publishedAt,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.mainArticle.title,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.mainArticle.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildChronologicalTimelinePreview() {
    // Collect all selected articles in chronological sequence
    final selectedArticles = <NewsArticle>[widget.mainArticle];
    for (final id in _selectedArticleIds) {
      if (id != widget.mainArticle.id) {
        final match = _allNews.where((a) => a.id == id).firstOrNull;
        if (match != null) {
          selectedArticles.add(match);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHRONOLOGICAL ORDER (${selectedArticles.length})',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black54),
              ),
              Text(
                'Earliest → Latest',
                style: GoogleFonts.inter(fontSize: 10.5, color: Colors.blueAccent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < selectedArticles.length; i++) ...[
            _buildTimelineStepTile(
              index: i + 1,
              isFirst: i == 0,
              isLast: i == selectedArticles.length - 1,
              article: selectedArticles[i],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStepTile({
    required int index,
    required bool isFirst,
    required bool isLast,
    required NewsArticle article,
  }) {
    final isMain = article.id == widget.mainArticle.id;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline line & dot
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isFirst
                    ? const Color(0xFF166534)
                    : (isLast ? Colors.purple : const Color(0xFF3B82F6)),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isFirst
                          ? 'ORIGINAL STORY'
                          : (isLast ? 'LATEST DEVELOPMENT' : 'UPDATE #$index'),
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isFirst
                            ? const Color(0xFF166534)
                            : (isLast ? Colors.purple : const Color(0xFF2563EB)),
                      ),
                    ),
                    const Spacer(),
                    if (!isMain)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedArticleIds.remove(article.id);
                          });
                        },
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.black45),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${article.publishedAt}${article.location.isNotEmpty ? ' • ${DisplayFormatters.shortDistrict(article.location)}' : ''}',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateSelector() {
    final candidates = _filteredCandidates;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT RELATED PUBLISHED ARTICLES',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            'Search and check articles that represent subsequent developments on this same story.',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search published articles...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              filled: true,
              fillColor: const Color(0xFFF9F9F8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5E2)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (candidates.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Text(
                'No matching published articles found.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: candidates.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final art = candidates[i];
                final isSelected = _selectedArticleIds.contains(art.id);

                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isSelected,
                  activeColor: Colors.black87,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedArticleIds.add(art.id);
                      } else {
                        _selectedArticleIds.remove(art.id);
                      }
                    });
                  },
                  title: Text(
                    art.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${art.category} • ${art.publishedAt}',
                    style: GoogleFonts.inter(fontSize: 10.5, color: Colors.black45),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
