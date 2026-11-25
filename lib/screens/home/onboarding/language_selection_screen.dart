// screens/home/onboarding/language_selection_screen.dart
//
// Opening setup on ONE colourful screen: language → state → district.
// Districts are compact chips so a whole state fits without long rows.
// (Class name kept so every login flow that opens it still works.)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/location_repository.dart';
import '../../../services/session_prefs.dart';
import '../../main/main_shell.dart';

class _Lang {
  final String id; // value used across the app
  final String native;
  final String english;
  final List<Color> colors;
  const _Lang(this.id, this.native, this.english, this.colors);
}

const _languages = [
  _Lang('telugu', 'తెలుగు', 'Telugu', [Color(0xFFFF9800), Color(0xFFF4511E)]),
  _Lang('english', 'English', 'English', [Color(0xFF42A5F5), Color(0xFF3949AB)]),
  _Lang('hindi', 'हिंदी', 'Hindi', [Color(0xFF66BB6A), Color(0xFF00897B)]),
];

const _stateColors = [
  [Color(0xFFEC407A), Color(0xFFAB47BC)], // first state
  [Color(0xFF26C6DA), Color(0xFF00897B)], // second state
];

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final _loc = LocationRepository.instance;
  String _language = 'telugu';
  Place? _state;
  Place? _district;
  bool _loading = true;
  String? _error;

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
      await _loc.init();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _state ??= _loc.states.isNotEmpty ? _loc.states.first : null;
      });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Could not load districts. Check your internet and try again.';
      });
    }
  }

  String _name(Place p) => p.display(_language);

  void _continue() {
    if (_state == null || _district == null) return;
    SessionPrefs.saveSelections(language: _language, state: _state!.nameEn, district: _district!.nameEn);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainShell(selectedLanguage: _language, selectedState: _state!.nameEn, selectedDistrict: _district!.nameEn),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final te = _language == 'telugu';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3E0), Color(0xFFFCE4EC), Color(0xFFE8EAF6)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Image.asset('assets/public/images/app_logo.png', width: 44, height: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(te ? 'మీ వార్తలు, మీ భాషలో' : 'Your news, your way',
                              style: GoogleFonts.notoSansTelugu(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1A237E))),
                          Text(te ? 'భాష, రాష్ట్రం, జిల్లా ఎంచుకోండి' : 'Choose language, state and district',
                              style: GoogleFonts.notoSansTelugu(fontSize: 12, color: const Color(0xFF5C6BC0), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. Language
                _StepLabel(n: 1, text: te ? 'భాష' : 'Language', color: const Color(0xFFF4511E)),
                Row(
                  children: [
                    for (final l in _languages) ...[
                      if (l != _languages.first) const SizedBox(width: 8),
                      Expanded(
                        child: _GradientChoice(
                          selected: _language == l.id,
                          colors: l.colors,
                          height: 50,
                          onTap: () => setState(() => _language = l.id),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(l.native, style: GoogleFonts.notoSansTelugu(fontSize: 16, fontWeight: FontWeight.w900, color: _language == l.id ? Colors.white : l.colors.last, height: 1.1)),
                            if (l.native != l.english)
                              Text(l.english, style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: _language == l.id ? Colors.white70 : Colors.black45)),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // 2. State
                _StepLabel(n: 2, text: te ? 'రాష్ట్రం' : 'State', color: const Color(0xFFAB47BC)),
                if (!_loading && _error == null)
                  Row(
                    children: [
                      for (final (i, s) in _loc.states.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _GradientChoice(
                            selected: _state?.id == s.id,
                            colors: _stateColors[i % _stateColors.length],
                            height: 46,
                            onTap: () => setState(() {
                              _state = s;
                              _district = null;
                            }),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.map_rounded, size: 18, color: _state?.id == s.id ? Colors.white : _stateColors[i % 2].last),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(_name(s), overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.notoSansTelugu(fontSize: 14.5, fontWeight: FontWeight.w800, color: _state?.id == s.id ? Colors.white : _stateColors[i % 2].last)),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 12),

                // 3. District (compact chips)
                _StepLabel(n: 3, text: te ? 'జిల్లా' : 'District', color: const Color(0xFF00897B)),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.black54)),
                                  TextButton(onPressed: _load, child: const Text('Try again')),
                                ]),
                              )
                            : _districtChips(),
                  ),
                ),
                const SizedBox(height: 10),

                // Continue
                SizedBox(
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: _district == null ? [Colors.grey.shade400, Colors.grey.shade500] : const [Color(0xFFFF6F00), Color(0xFFD81B60), Color(0xFF5E35B1)],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _district == null ? null : _continue,
                        child: Center(
                          child: Text(
                            _district == null ? (te ? 'జిల్లాను ఎంచుకోండి' : 'Pick your district') : (te ? 'వార్తలు చూడండి  →' : 'Show my news  →'),
                            style: GoogleFonts.notoSansTelugu(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: mq.padding.bottom > 0 ? 0 : 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _districtChips() {
    final list = [..._loc.childrenOf(_state?.id)]..sort((a, b) => _name(a).compareTo(_name(b)));
    if (list.isEmpty) return const Center(child: CircularProgressIndicator());
    final stateIndex = _loc.states.indexWhere((s) => s.id == _state?.id);
    final colors = _stateColors[(stateIndex < 0 ? 0 : stateIndex) % _stateColors.length];
    return LayoutBuilder(builder: (context, box) {
      // Shrink chips a little on small screens so the whole state fits.
      final compact = box.maxHeight < 360;
      return SingleChildScrollView(
        child: Wrap(
          spacing: 6,
          runSpacing: compact ? 5 : 7,
          alignment: WrapAlignment.center,
          children: [
            for (final d in list)
              _DistrictChip(
                label: _name(d),
                selected: _district?.id == d.id,
                colors: colors,
                compact: compact,
                onTap: () => setState(() => _district = d),
              ),
          ],
        ),
      );
    });
  }
}

class _StepLabel extends StatelessWidget {
  final int n;
  final String text;
  final Color color;
  const _StepLabel({required this.n, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Row(children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Text('$n', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        const SizedBox(width: 7),
        Text(text, style: GoogleFonts.notoSansTelugu(fontSize: 13.5, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

class _GradientChoice extends StatelessWidget {
  final bool selected;
  final List<Color> colors;
  final double height;
  final VoidCallback onTap;
  final Widget child;

  const _GradientChoice({required this.selected, required this.colors, required this.height, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: selected ? LinearGradient(colors: colors) : null,
        color: selected ? null : Colors.white,
        border: Border.all(color: selected ? Colors.transparent : colors.first.withValues(alpha: 0.55), width: 1.5),
        boxShadow: selected ? [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Center(child: child)),
      ),
    );
  }
}

class _DistrictChip extends StatelessWidget {
  final String label;
  final bool selected;
  final List<Color> colors;
  final bool compact;
  final VoidCallback onTap;

  const _DistrictChip({required this.label, required this.selected, required this.colors, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11, vertical: compact ? 5 : 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected ? LinearGradient(colors: colors) : null,
          color: selected ? null : colors.first.withValues(alpha: 0.10),
          border: Border.all(color: selected ? Colors.transparent : colors.first.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansTelugu(
            fontSize: compact ? 11.5 : 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : colors.last,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
