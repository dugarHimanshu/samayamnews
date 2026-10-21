//screens/contributor/my_submissions_screen.dart
import 'package:flutter/material.dart';

import '../../models/news_submission.dart';
import '../../services/submission_service.dart';

class MySubmissionsScreen extends StatefulWidget {
  const MySubmissionsScreen({super.key});

  @override
  State<MySubmissionsScreen> createState() => _MySubmissionsScreenState();
}

class _MySubmissionsScreenState extends State<MySubmissionsScreen> {
  final _submissionService = SubmissionService();

  bool _loading = true;
  List<NewsSubmission> _submissions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final submissions = await _submissionService.fetchMySubmissions();
    if (!mounted) return;
    setState(() {
      _submissions = submissions;
      _loading = false;
    });
  }

  // Fetches and shows the editor's rejection reason for this
  // submission — via the public view, so no editor identity is
  // ever exposed here.
  Future<void> _showFeedback(NewsSubmission submission) async {
    final reason = await _submissionService.fetchRejectionFeedback(
      submission.id!,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editor\'s feedback'),
        content: Text(
          reason ?? 'No feedback was provided for this submission.',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'My Submissions',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _submissions.isEmpty
            ? ListView(
                // wrapped in ListView (not just Center) so pull-to-refresh
                // still works even when the list is empty
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(
                      child: Text(
                        'You haven\'t submitted any stories yet.',
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                itemCount: _submissions.length,
                itemBuilder: (context, index) =>
                    _buildCard(_submissions[index]),
              ),
      ),
    );
  }

  Widget _buildCard(NewsSubmission submission) {
    final statusInfo = _statusInfo(submission.status);
    final isRejected = submission.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  submission.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusInfo.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusInfo.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${submission.district} • ${submission.state}',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          if (submission.submittedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDate(submission.submittedAt!),
              style: const TextStyle(fontSize: 10, color: Colors.black38),
            ),
          ],
          if (isRejected) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showFeedback(submission),
              child: const Text(
                'View editor feedback',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'pending':
        return const _StatusInfo('Pending', Colors.grey);
      case 'in_review':
        return const _StatusInfo('In review', Colors.blueGrey);
      case 'published':
        return const _StatusInfo('Published', Colors.green);
      case 'rejected':
        return const _StatusInfo('Rejected', Colors.redAccent);
      default:
        return const _StatusInfo('Unknown', Colors.grey);
    }
  }

  String _formatDate(DateTime date) {
    // Simple day/month/year formatting — swap for the `intl` package
    // later if you want locale-aware formatting.
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}