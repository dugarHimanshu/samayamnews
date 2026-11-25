// screens/wishes/wishes_screen.dart
//
// Birthday Wishes / Marriage Day Wishes (from the Headlines tab).
// Readers send a poster: photo + name of the person being wished + greeting +
// the names of the people sending the wishes (shown at the bottom of the poster).
// Posters appear here once an editor approves them.

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/api_client.dart';
import '../../services/app_strings.dart';
import '../../services/community_service.dart';
import '../../services/submission_service.dart';
import '../home/onboarding/welcome_screen.dart';

List<Color> _wishColors(String kind) =>
    kind == 'birthday' ? const [Color(0xFFFF4081), Color(0xFF7C4DFF)] : const [Color(0xFFFF6F00), Color(0xFFD50000)];

String _wishTitle(String kind) => kind == 'birthday' ? 'Happy Birthday' : 'Happy Wedding Anniversary';
String _wishTitleTe(String kind) => kind == 'birthday' ? 'పుట్టినరోజు శుభాకాంక్షలు' : 'పెళ్లిరోజు శుభాకాంక్షలు';

class WishesScreen extends StatefulWidget {
  final String kind; // birthday | anniversary
  final String language;

  const WishesScreen({super.key, required this.kind, required this.language});

  @override
  State<WishesScreen> createState() => _WishesScreenState();
}

class _WishesScreenState extends State<WishesScreen> {
  List<Wish> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final w = await CommunityService.instance.wishes(kind: widget.kind);
      if (mounted) setState(() {
        _items = w;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (Supabase.instance.client.auth.currentSession == null) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign in to send wishes'),
          content: const Text('Please sign in or create a free account to send a wishes poster.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign in')),
          ],
        ),
      );
      if (go == true && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      return;
    }
    final sent = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => WishFormScreen(kind: widget.kind)));
    if (sent == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _wishColors(widget.kind);
    final title = AppStrings.t(widget.kind == 'birthday' ? 'birthday_wishes' : 'anniversary_wishes', widget.language);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))),
        foregroundColor: Colors.white,
        title: Text(title, style: GoogleFonts.notoSansTelugu(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.first,
        foregroundColor: Colors.white,
        onPressed: _send,
        icon: Icon(widget.kind == 'birthday' ? Icons.cake_rounded : Icons.favorite_rounded),
        label: const Text('Send wishes'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Icon(widget.kind == 'birthday' ? Icons.cake_outlined : Icons.favorite_border_rounded, size: 64, color: colors.first.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Center(child: Text('No wishes yet — send the first one!', style: GoogleFonts.inter(color: Colors.black54))),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (_, i) {
                        final w = _items[i];
                        return WishPoster(
                          kind: w.kind,
                          photo: w.photoUrl == null ? null : CachedNetworkImageProvider(w.photoUrl!),
                          recipientName: w.recipientName,
                          message: w.message,
                          fromNames: w.fromNames,
                        );
                      },
                    ),
            ),
    );
  }
}

/// The poster: header banner, photo, name, greeting, and "Wishes from" strip at the bottom.
class WishPoster extends StatelessWidget {
  final String kind;
  final ImageProvider? photo;
  final String recipientName;
  final String message;
  final String fromNames;

  const WishPoster({super.key, required this.kind, this.photo, required this.recipientName, required this.message, required this.fromNames});

  @override
  Widget build(BuildContext context) {
    final colors = _wishColors(kind);
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 14),
            Text(_wishTitleTe(kind), style: GoogleFonts.notoSansTelugu(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(_wishTitle(kind).toUpperCase(), style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    color: Colors.white24,
                    image: photo == null ? null : DecorationImage(image: photo!, fit: BoxFit.cover),
                  ),
                  child: photo == null ? const Icon(Icons.person_rounded, color: Colors.white70, size: 72) : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                recipientName.isEmpty ? 'Name' : recipientName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansTelugu(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                message.isEmpty ? 'Your greeting message' : message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansTelugu(color: Colors.white, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            // "Wishes from" strip at the bottom of the poster
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                children: [
                  Text('శుభాకాంక్షలతో • WISHES FROM', style: GoogleFonts.notoSansTelugu(fontSize: 10, fontWeight: FontWeight.w800, color: colors.last, letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(
                    fromNames.isEmpty ? 'Names of the people sending wishes' : fromNames,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansTelugu(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF212121)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WishFormScreen extends StatefulWidget {
  final String kind;
  const WishFormScreen({super.key, required this.kind});

  @override
  State<WishFormScreen> createState() => _WishFormScreenState();
}

class _WishFormScreenState extends State<WishFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _message = TextEditingController();
  final _from = TextEditingController();
  XFile? _photo;
  Uint8List? _bytes;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _message.text = widget.kind == 'birthday' ? 'మీకు పుట్టినరోజు శుభాకాంక్షలు! 🎂' : 'మీకు పెళ్లిరోజు శుభాకాంక్షలు! 💐';
    for (final c in [_name, _message, _from]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _message, _from]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (p == null) return;
    final b = await p.readAsBytes();
    if (b.length > 10 * 1024 * 1024) {
      _snack('Photo must be 10 MB or smaller.');
      return;
    }
    setState(() {
      _photo = p;
      _bytes = b;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      String? mediaId;
      if (_bytes != null) mediaId = await SubmissionService().uploadImage(_bytes!, fileName: _photo!.name);
      final w = await CommunityService.instance.sendWish(
        kind: widget.kind,
        photoMediaId: mediaId,
        recipientName: _name.text.trim(),
        message: _message.text.trim(),
        fromNames: _from.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
          title: Text(w.status == 'approved' ? 'Wishes published' : 'Wishes sent'),
          content: Text(w.status == 'approved' ? 'Your poster is now visible to everyone.' : 'Your poster will appear after our team reviews it.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not send your wishes. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    final colors = _wishColors(widget.kind);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))),
        foregroundColor: Colors.white,
        title: Text(widget.kind == 'birthday' ? 'Birthday Wishes' : 'Marriage Day Wishes'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Preview', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.black54)),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 300,
                child: WishPoster(
                  kind: widget.kind,
                  photo: _bytes == null ? null : MemoryImage(_bytes!),
                  recipientName: _name.text,
                  message: _message.text,
                  fromNames: _from.text,
                ),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: Text(_bytes == null ? 'Upload photo' : 'Change photo'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: _dec('Name of the person receiving the wishes', Icons.person_rounded),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Please enter the name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              maxLines: 3,
              maxLength: 500,
              decoration: _dec('Greeting message', Icons.edit_note_rounded),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Please enter a message' : null,
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _from,
              maxLength: 300,
              decoration: _dec('Wishes from (names, shown at the bottom)', Icons.groups_rounded),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Please enter who is sending the wishes' : null,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: colors.first, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _sending ? const CircularProgressIndicator(color: Colors.white) : const Text('Send wishes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
