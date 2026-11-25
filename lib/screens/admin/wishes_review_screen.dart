// screens/admin/wishes_review_screen.dart
//
// Editors / admins: approve or reject birthday & anniversary wishes posters.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_client.dart';
import '../../services/community_service.dart';
import '../wishes/wishes_screen.dart';

class WishesReviewScreen extends StatefulWidget {
  const WishesReviewScreen({super.key});

  @override
  State<WishesReviewScreen> createState() => _WishesReviewScreenState();
}

class _WishesReviewScreenState extends State<WishesReviewScreen> {
  final _svc = CommunityService.instance;
  String _status = 'pending';
  List<Wish> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final w = await _svc.wishQueue(status: _status);
      if (mounted) setState(() {
        _items = w;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _snack(e is ApiException ? e.message : 'Could not load wishes.');
    }
  }

  Future<void> _approve(Wish w) async {
    try {
      await _svc.approveWish(w.id);
      _snack('Published.');
      _load();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Could not approve.');
    }
  }

  Future<void> _reject(Wish w) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject wishes'),
        content: TextField(controller: reason, decoration: const InputDecoration(hintText: 'Reason')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject')),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (ok != true) return;
    try {
      await _svc.rejectWish(w.id, text.length < 3 ? 'Not suitable' : text);
      _load();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Could not reject.');
    }
  }

  Future<void> _delete(Wish w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this poster?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await _svc.deleteWish(w.id).catchError((_) {});
    _load();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(title: Text('Wishes review', style: GoogleFonts.inter(fontWeight: FontWeight.w800))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(children: [
              for (final s in const ['pending', 'approved', 'rejected'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${s[0].toUpperCase()}${s.substring(1)}'),
                    selected: _status == s,
                    onSelected: (_) {
                      setState(() => _status = s);
                      _load();
                    },
                  ),
                ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(child: Text('Nothing here', style: GoogleFonts.inter(color: Colors.black54)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 20),
                        itemBuilder: (_, i) {
                          final w = _items[i];
                          return Column(
                            children: [
                              SizedBox(
                                width: 300,
                                child: WishPoster(
                                  kind: w.kind,
                                  photo: w.photoUrl == null ? null : CachedNetworkImageProvider(w.photoUrl!),
                                  recipientName: w.recipientName,
                                  message: w.message,
                                  fromNames: w.fromNames,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (w.status == 'pending') ...[
                                    OutlinedButton(onPressed: () => _reject(w), child: const Text('Reject')),
                                    const SizedBox(width: 10),
                                    FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700), onPressed: () => _approve(w), child: const Text('Approve')),
                                  ] else
                                    TextButton.icon(onPressed: () => _delete(w), icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
