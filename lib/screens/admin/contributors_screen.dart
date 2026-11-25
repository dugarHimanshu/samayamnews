// screens/admin/contributors_screen.dart
//
// Admin: Reporters / Freelancers list with a Remove button next to each name.
// Removing (after confirmation) stops the person signing in or uploading news;
// stories they already published stay in the app.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_client.dart';
import '../../services/location_repository.dart';

class ContributorsScreen extends StatefulWidget {
  const ContributorsScreen({super.key});

  @override
  State<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends State<ContributorsScreen> {
  final _api = ApiClient.instance;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _filter = 'all';
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/admin/contributors') as Map;
      if (!mounted) return;
      setState(() {
        _items = [for (final u in res['items'] as List) Map<String, dynamic>.from(u as Map)];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e is ApiException ? e.message : 'Could not load reporters.');
    }
  }

  String _name(Map<String, dynamic> u) {
    final n = (u['fullName'] ?? '').toString().trim();
    return n.isNotEmpty ? n : (u['email'] ?? 'Unknown').toString();
  }

  Future<void> _remove(Map<String, dynamic> u) async {
    final role = u['role'] == 'freelancer' ? 'freelancer' : 'reporter';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.person_remove_rounded, color: Color(0xFFC62828), size: 38),
        title: Text('Remove ${_name(u)}?'),
        content: Text(
          'This $role will no longer be able to log in or upload news. '
          'Stories they already published will stay in the app. Stories still waiting for review will be withdrawn.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final id = u['id'].toString();
    setState(() => _busy.add(id));
    try {
      await _api.post('/admin/users/$id/remove');
      setState(() => _items.removeWhere((x) => x['id'] == id));
      _snack('${_name(u)} removed.');
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Could not remove. Please try again.');
      _load();
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final shown = _items.where((u) => _filter == 'all' || u['role'] == _filter).toList();
    int count(String r) => _items.where((u) => u['role'] == r).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(title: Text('Reporters / Freelancers', style: GoogleFonts.inter(fontWeight: FontWeight.w800)), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(children: [
              for (final f in [('all', 'All (${_items.length})'), ('employee', 'Reporters (${count('employee')})'), ('freelancer', 'Freelancers (${count('freelancer')})')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(f.$2), selected: _filter == f.$1, onSelected: (_) => setState(() => _filter = f.$1)),
                ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: shown.isEmpty
                        ? ListView(children: [const SizedBox(height: 120), Center(child: Text('No reporters yet', style: GoogleFonts.inter(color: Colors.black54)))])
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                            itemCount: shown.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final u = shown[i];
                              final id = u['id'].toString();
                              final freelancer = u['role'] == 'freelancer';
                              final district = LocationRepository.instance.byId(u['homeDistrictId'] as int?)?.nameEn;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: freelancer ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD),
                                      child: Icon(freelancer ? Icons.edit_note_rounded : Icons.badge_rounded, color: freelancer ? Colors.orange.shade800 : Colors.blue.shade800),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_name(u), style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                                          Text(
                                            [freelancer ? 'Freelancer' : 'Reporter', if (district != null) district, (u['email'] ?? '').toString()].where((x) => x.isNotEmpty).join(' • '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _busy.contains(id)
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                        : OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC62828), side: const BorderSide(color: Color(0xFFEF9A9A)), visualDensity: VisualDensity.compact),
                                            onPressed: () => _remove(u),
                                            icon: const Icon(Icons.person_remove_outlined, size: 18),
                                            label: const Text('Delete'),
                                          ),
                                  ],
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
