// screens/editor/editor_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/news_article.dart';
import '../../models/news_submission.dart';
import '../../services/editor_service.dart';
import '../home/onboarding/welcome_screen.dart';
import 'editor_review_screen.dart';
import 'published_news_edit_screen.dart';

// ============================================================
// FILTERS
// ============================================================

const List<String> _kStateFilters = ['All', 'Telangana', 'Andhra Pradesh'];

const List<String> _kQueueFilters = ['New', 'My Reviews', 'Available', 'All'];

// ============================================================
// EDITOR DASHBOARD
// ============================================================

class EditorDashboardScreen extends StatefulWidget {
  const EditorDashboardScreen({super.key});

  @override
  State<EditorDashboardScreen> createState() => _EditorDashboardScreenState();
}

class _EditorDashboardScreenState extends State<EditorDashboardScreen>
    with WidgetsBindingObserver {
  final EditorService _editorService = EditorService();

  String? _currentEditorId;

  // ============================================================
  // SUBMISSION QUEUE
  // ============================================================

  bool _loading = true;

  Map<String, int> _stats = {};

  List<NewsSubmission> _queue = [];

  Map<String, List<Map<String, dynamic>>> _reviewsBySubmission = {};

  // ============================================================
  // PUBLISHED NEWS
  // ============================================================

  List<NewsArticle> _publishedNews = [];

  String? _busyPublishedArticleId;

  // ============================================================
  // FILTER STATE
  // ============================================================

  String _stateFilter = 'All';

  String _queueFilter = 'New';

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    final user = Supabase.instance.client.auth.currentUser;

    _currentEditorId = user?.id;

    _loadEverything();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadEverything();
    }
  }

  // ============================================================
  // LOAD EVERYTHING
  // ============================================================

  Future<void> _loadEverything() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final stats = await _editorService.fetchStats();

      final queue = await _editorService.fetchQueue();

      final submissionIds = queue
          .where((submission) => submission.id != null)
          .map((submission) => submission.id!)
          .toList();

      final reviews = await _editorService.fetchReviewsFor(submissionIds);

      final published = await _editorService.fetchPublishedNews();

      final grouped = <String, List<Map<String, dynamic>>>{};

      for (final review in reviews) {
        final submissionId = review['submission_id'];

        if (submissionId == null) {
          continue;
        }

        final id = submissionId.toString();

        grouped.putIfAbsent(id, () => []).add(review);
      }

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _queue = queue;
        _reviewsBySubmission = grouped;
        _publishedNews = published;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage('Unable to load the Editor Desk. Please try again.');
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Are you sure you want to sign out from the Editor Desk?',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  // ============================================================
  // QUEUE CARD INFO
  // ============================================================

  _QueueCardInfo _infoFor(NewsSubmission submission) {
    final reviews = _reviewsBySubmission[submission.id] ?? const [];

    Map<String, dynamic>? activeReview;

    for (final review in reviews) {
      if (review['status'] == 'active') {
        activeReview = review;
        break;
      }
    }

    if (activeReview != null) {
      final editorId = activeReview['editor_id']?.toString();

      final isMe = editorId != null && editorId == _currentEditorId;

      if (isMe) {
        return const _QueueCardInfo(
          label: 'You are reviewing this',
          locked: false,
          accentColor: Color(0xFF2E7D32),
        );
      }

      final profiles = activeReview['profiles'];

      String editorName = 'another editor';

      if (profiles is Map<String, dynamic>) {
        final name = profiles['full_name'];

        if (name != null && name.toString().trim().isNotEmpty) {
          editorName = name.toString().trim();
        }
      }

      return _QueueCardInfo(
        label: 'Being reviewed by $editorName',
        locked: true,
        accentColor: const Color(0xFFD32F2F),
      );
    }

    final hasAnyReview = reviews.isNotEmpty;

    return _QueueCardInfo(
      label: hasAnyReview ? 'Available' : 'New submission',
      locked: false,
      accentColor: hasAnyReview
          ? const Color(0xFF0288D1)
          : const Color(0xFFEF6C00),
    );
  }

  // ============================================================
  // FILTERED QUEUE
  // ============================================================

  List<NewsSubmission> get _filteredQueue {
    return _queue.where((submission) {
      if (_stateFilter != 'All' && submission.state != _stateFilter) {
        return false;
      }

      final info = _infoFor(submission);

      switch (_queueFilter) {
        case 'New':
          return info.label == 'New submission';

        case 'My Reviews':
          return info.label == 'You are reviewing this';

        case 'Available':
          return info.label == 'Available' || info.label == 'New submission';

        case 'All':
        default:
          return true;
      }
    }).toList();
  }

  // ============================================================
  // OPEN SUBMISSION REVIEW
  // ============================================================

  Future<void> _openReview(NewsSubmission submission) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorReviewScreen(submission: submission),
      ),
    );

    if (!mounted) return;

    await _loadEverything();
  }

  // ============================================================
  // EDIT PUBLISHED ARTICLE
  // ============================================================

  Future<void> _editPublishedArticle(NewsArticle article) async {
    if (_busyPublishedArticleId != null) {
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PublishedNewsEditScreen(article: article),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadEverything();

      if (!mounted) return;

      _showMessage('Published news updated.');
    }
  }

  // ============================================================
  // DELETE PUBLISHED ARTICLE
  // ============================================================

  Future<void> _deletePublishedArticle(NewsArticle article) async {
    if (_busyPublishedArticleId != null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete published news?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'This will permanently remove the article from the live news feed.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _busyPublishedArticleId = article.id;
    });

    try {
      await _editorService.deletePublishedNews(article.id);

      if (!mounted) return;

      setState(() {
        _publishedNews.removeWhere((item) => item.id == article.id);
      });

      _showMessage('Published news deleted.');

      await _loadEverything();
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to delete this news article.');
    } finally {
      if (mounted) {
        setState(() {
          _busyPublishedArticleId = null;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.newspaper_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'EDITOR DESK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadEverything,
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
          ),
          IconButton(
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout_rounded, color: Colors.black54),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.black,
          onRefresh: _loadEverything,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 20),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildFilterChips(_kStateFilters, _stateFilter, (value) {
                      setState(() {
                        _stateFilter = value;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildFilterChips(_kQueueFilters, _queueFilter, (value) {
                      setState(() {
                        _queueFilter = value;
                      });
                    }),
                    const SizedBox(height: 22),
                    const Text(
                      'SUBMISSION QUEUE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_filteredQueue.isEmpty)
                      _buildEmptyQueueState()
                    else
                      ..._filteredQueue.map(_buildSubmissionCard),
                    const SizedBox(height: 36),
                    _buildPublishedHeader(),
                    const SizedBox(height: 12),
                    _buildPublishedNewsSection(),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _buildGreeting() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good day, Editor',
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Here is your live news curation queue.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY QUEUE
  // ============================================================

  Widget _buildEmptyQueueState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'Nothing here right now.',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsRow() {
    Widget stat(String label, int? value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '${value ?? 0}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        stat(
          'New',
          _stats['new'],
          Icons.fiber_new_rounded,
          Colors.orange[800]!,
        ),
        stat(
          'In Review',
          _stats['in_review'],
          Icons.pending_actions_rounded,
          Colors.blue[700]!,
        ),
        stat(
          'Approved',
          _stats['approved_today'],
          Icons.check_circle_rounded,
          Colors.green[700]!,
        ),
        stat(
          'Rejected',
          _stats['rejected_today'],
          Icons.cancel_rounded,
          Colors.red[700]!,
        ),
      ],
    );
  }

  // ============================================================
  // FILTER CHIPS
  // ============================================================

  Widget _buildFilterChips(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];

          final isSelected = option == selected;

          return ChoiceChip(
            label: Text(option, style: const TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            selectedColor: Colors.black,
            backgroundColor: Colors.white,
            elevation: isSelected ? 2 : 0,
            shadowColor: Colors.black26,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SUBMISSION CARD
  // ============================================================

  Widget _buildSubmissionCard(NewsSubmission submission) {
    final info = _infoFor(submission);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: info.locked ? null : () => _openReview(submission),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        submission.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (info.locked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${submission.district} • ${submission.state}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        info.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: info.accentColor,
                        ),
                      ),
                    ),
                    if (!info.locked)
                      const Row(
                        children: [
                          Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.black87,
                          ),
                        ],
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

  // ============================================================
  // PUBLISHED NEWS HEADER
  // ============================================================

  Widget _buildPublishedHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'PUBLISHED NEWS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Colors.black45,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_publishedNews.length} LIVE',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF318451),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PUBLISHED NEWS SECTION
  // ============================================================

  Widget _buildPublishedNewsSection() {
    if (_publishedNews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            'No published news yet.',
            style: TextStyle(color: Colors.black45, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: _publishedNews.map(_buildPublishedNewsCard).toList(),
    );
  }

  // ============================================================
  // PUBLISHED NEWS CARD
  // ============================================================

  Widget _buildPublishedNewsCard(NewsArticle article) {
    final isBusy = _busyPublishedArticleId == article.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF318451),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: Colors.black45,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  article.location.isNotEmpty
                      ? article.location
                      : 'Published article',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            article.publishedAt.isNotEmpty
                ? 'Published ${article.publishedAt}'
                : 'Published',
            style: const TextStyle(fontSize: 10, color: Colors.black38),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => _editPublishedArticle(article),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'EDIT',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.black26),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => _deletePublishedArticle(article),
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(
                    isBusy ? 'WAIT...' : 'DELETE',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUEUE CARD INFO
// ============================================================

class _QueueCardInfo {
  final String label;
  final bool locked;
  final Color accentColor;

  const _QueueCardInfo({
    required this.label,
    required this.locked,
    required this.accentColor,
  });
}