import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_article.dart';
import '../../models/story_timeline.dart';
import '../../services/editor_service.dart';
import '../../services/story_timeline_service.dart';
import 'story_timeline_linker_screen.dart';

/// Central management screen for Editors and Admins to view and organize
/// all ongoing story threads and chronological follow-ups.
class StoryTimelinesOverviewScreen extends StatefulWidget {
  const StoryTimelinesOverviewScreen({super.key});

  @override
  State<StoryTimelinesOverviewScreen> createState() => _StoryTimelinesOverviewScreenState();
}

class _StoryTimelinesOverviewScreenState extends State<StoryTimelinesOverviewScreen> {
  final StoryTimelineService _timelineService = StoryTimelineService.instance;
  final EditorService _editorService = EditorService();

  List<NewsArticle> _allPublishedNews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timelineService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _timelineService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await _timelineService.load();
    try {
      final news = await _editorService.fetchPublishedNews();
      if (mounted) {
        setState(() {
          _allPublishedNews = news;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openLinkerForTimeline(StoryTimeline timeline) {
    final main = _allPublishedNews.where((a) => a.id == timeline.mainArticleId).firstOrNull;
    if (main == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Original story for this timeline not found in published list.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryTimelineLinkerScreen(
          mainArticle: main,
          allPublishedNews: _allPublishedNews,
        ),
      ),
    );
  }

  void _createNewTimeline() {
    if (_allPublishedNews.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No published articles available to link.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Main / Anchor Article',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose the original story to which subsequent follow-ups will be chronologically linked.',
                style: GoogleFonts.inter(fontSize: 11.5, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: _allPublishedNews.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final article = _allPublishedNews[i];
                    final hasTimeline = _timelineService.hasLinkedStories(article.id);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${article.category} • ${article.publishedAt}',
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                      trailing: hasTimeline
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('LINKED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.blueAccent)),
                            )
                          : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StoryTimelineLinkerScreen(
                              mainArticle: article,
                              allPublishedNews: _allPublishedNews,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timelines = _timelineService.allTimelines.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        title: Text(
          'Story Timelines & Follow-ups',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        onPressed: _createNewTimeline,
        icon: const Icon(Icons.add_link_rounded),
        label: const Text('Create Timeline', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black87))
          : timelines.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: timelines.length,
                  itemBuilder: (ctx, i) {
                    final t = timelines[i];
                    return _buildTimelineCard(t);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              child: const Icon(Icons.timeline_rounded, size: 40, color: Colors.blueAccent),
            ),
            const SizedBox(height: 16),
            Text(
              'No Story Timelines Yet',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Link ongoing developments together so readers can follow news story updates chronologically in one place.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _createNewTimeline,
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Create First Story Timeline'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(StoryTimeline timeline) {
    final main = _allPublishedNews.where((a) => a.id == timeline.mainArticleId).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hub_outlined, size: 12, color: Colors.blueAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${timeline.articleIds.length} ARTICLES LINKED',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Updated ${timeline.createdAt.day}/${timeline.createdAt.month}/${timeline.createdAt.year}',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            timeline.title,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          if (main != null) ...[
            const SizedBox(height: 6),
            Text(
              'Original Anchor: "${main.title}"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Manage & Reorder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () => _openLinkerForTimeline(timeline),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                tooltip: 'Delete Timeline',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Story Timeline?'),
                      content: const Text('This will unlink all articles in this thread. The articles themselves remain published.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _timelineService.deleteTimeline(timeline.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
