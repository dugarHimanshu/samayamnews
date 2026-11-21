// screens/admin/reporter_applications_screen.dart
//
// Admin list of reporter / freelancer registrations: review details, approve
// (optionally changing Reporter ↔ Freelancer) or reject with a reason.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_client.dart';
import '../../services/application_service.dart';

const _ink = Color(0xFF111111);
const _muted = Color(0xFF6B7280);
const _line = Color(0xFFE5E7EB);

class ReporterApplicationsScreen extends StatefulWidget {
  const ReporterApplicationsScreen({super.key});

  @override
  State<ReporterApplicationsScreen> createState() => _ReporterApplicationsScreenState();
}

class _ReporterApplicationsScreenState extends State<ReporterApplicationsScreen> {
  final _service = ApplicationService.instance;
  String _status = 'pending';
  List<ContributorApplication> _items = [];
  Map<String, int> _counts = {};
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.list(status: _status);
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _counts = res.counts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load applications.';
        _loading = false;
      });
    }
  }

  Future<void> _approve(ContributorApplication a) async {
    String role = a.role;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text('Approve ${a.fullName}?', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('They will be able to sign in and submit news as:', style: GoogleFonts.inter(fontSize: 13, color: _muted)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'employee', label: Text('Reporter')),
                  ButtonSegment(value: 'freelancer', label: Text('Freelancer')),
                ],
                selected: {role},
                onSelectionChanged: (s) => setLocal(() => role = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF15803D)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _run(a, () => _service.approve(a.id, role: role), '${a.fullName} approved as ${role == 'freelancer' ? 'Freelancer' : 'Reporter'}.');
  }

  Future<void> _reject(ContributorApplication a) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Reject application', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
        content: TextField(
          controller: reason,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Reason (the applicant will see this)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
            onPressed: () {
              if (reason.text.trim().length >= 3) Navigator.pop(ctx, true);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (ok != true) return;
    await _run(a, () => _service.reject(a.id, text), 'Application rejected.');
  }

  Future<void> _run(ContributorApplication a, Future<void> Function() action, String done) async {
    setState(() => _busy.add(a.id));
    try {
      await action();
      _snack(done);
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
      await _load();
    } catch (_) {
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy.remove(a.id));
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _ink,
        title: Text('Reporter applications', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                for (final s in const ['pending', 'approved', 'rejected'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${s[0].toUpperCase()}${s.substring(1)} (${_counts[s] ?? 0})'),
                      selected: _status == s,
                      selectedColor: _ink,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _status == s ? Colors.white : _ink,
                      ),
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _status = s);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: GoogleFonts.inter(color: _muted)),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          const SizedBox(height: 120),
          const Icon(Icons.inbox_outlined, size: 48, color: _muted),
          const SizedBox(height: 10),
          Center(child: Text('No $_status applications', style: GoogleFonts.inter(color: _muted))),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _card(_items[i]),
      ),
    );
  }

  Widget _card(ContributorApplication a) {
    final place = [a.mandal, a.district, a.state].whereType<String>().join(', ');
    final busy = _busy.contains(a.id);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _ink,
                child: Text(
                  a.fullName.isEmpty ? '?' : a.fullName[0].toUpperCase(),
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.fullName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
                    Text('Applied ${_ago(a.createdAt)}', style: GoogleFonts.inter(fontSize: 11, color: _muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
                child: Text(a.roleLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _ink)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row(Icons.phone_outlined, a.mobile),
          _row(Icons.mail_outline, a.email),
          if (place.isNotEmpty) _row(Icons.place_outlined, place),
          if ((a.address ?? '').isNotEmpty) _row(Icons.home_outlined, a.address!),
          if (a.status == 'rejected' && (a.rejectionReason ?? '').isNotEmpty)
            _row(Icons.info_outline, 'Reason: ${a.rejectionReason}'),
          if (a.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB91C1C),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: busy ? null : () => _reject(a),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: busy ? null : () => _approve(a),
                    child: busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: _muted),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: _ink))),
            ],
          ),
        ),
      );

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes.clamp(1, 59)} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }
}
