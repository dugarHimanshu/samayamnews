// screens/contributor/reporter_registration_screen.dart
//
// Simple sign-up form for people who want to send news as a Reporter or Freelancer.
// The admin reviews each application; once approved, the person signs in with the
// email + password chosen here and can submit stories.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_client.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_repository.dart';

const _ink = Color(0xFF111111);
const _muted = Color(0xFF6B7280);
const _line = Color(0xFFE5E7EB);
const _gold = Color(0xFFC9A24B);

class ReporterRegistrationScreen extends StatefulWidget {
  const ReporterRegistrationScreen({super.key});

  @override
  State<ReporterRegistrationScreen> createState() => _ReporterRegistrationScreenState();
}

class _ReporterRegistrationScreenState extends State<ReporterRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();

  final _loc = LocationRepository.instance;
  String _role = 'employee';
  int? _stateId;
  int? _districtId;
  int? _mandalId;
  List<Place> _mandals = const [];
  bool _loadingMandals = false;
  bool _submitting = false;
  bool _showPassword = false;
  ContributorApplication? _submitted;

  bool get _signedIn => AuthService.instance.isLoggedIn;

  @override
  void initState() {
    super.initState();
    _email.text = AuthService.instance.currentUser?.email ?? '';
    _loc.init().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in [_name, _mobile, _email, _password, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDistrict(int? id) async {
    setState(() {
      _districtId = id;
      _mandalId = null;
      _mandals = const [];
      _loadingMandals = id != null;
    });
    if (id == null) return;
    try {
      final list = await _loc.loadChildren(id);
      if (mounted && _districtId == id) setState(() => _mandals = list);
    } catch (_) {
      // Mandal is optional; the form still works without the list.
    } finally {
      if (mounted) setState(() => _loadingMandals = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final app = await ApplicationService.instance.register(
        role: _role,
        fullName: _name.text.trim(),
        mobile: _mobile.text.trim(),
        email: _email.text.trim(),
        password: _signedIn ? null : _password.text,
        address: _address.text.trim(),
        districtId: _districtId!,
        mandalId: _mandalId,
      );
      if (mounted) setState(() => _submitted = app);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not send your application. Please check your connection and try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _ink,
        title: Text('Reporter Registration', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: SafeArea(child: _submitted != null ? _success(_submitted!) : _form()),
    );
  }

  Widget _form() {
    final districts = _stateId == null ? const <Place>[] : _loc.childrenOf(_stateId);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text('Join our newsroom', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 6),
          Text(
            'Send local news from your area. Fill in a few details — our team will review and approve your account.',
            style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: _muted),
          ),
          const SizedBox(height: 22),
          _label('I want to join as'),
          Row(
            children: [
              Expanded(child: _roleCard('employee', Icons.badge_outlined, 'Reporter', 'Newsroom reporter')),
              const SizedBox(width: 10),
              Expanded(child: _roleCard('freelancer', Icons.edit_note_rounded, 'Freelancer', 'Up to 10 stories a day')),
            ],
          ),
          const SizedBox(height: 20),
          _label('Full name'),
          _field(_name, hint: 'Your name', icon: Icons.person_outline, validator: (v) => (v ?? '').trim().length < 2 ? 'Please enter your name' : null),
          _label('Mobile number'),
          _field(
            _mobile,
            hint: '10-digit mobile number',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
              final local = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
              return RegExp(r'^[6-9]\d{9}$').hasMatch(local) ? null : 'Enter a valid 10-digit mobile number';
            },
          ),
          _label('Email ID'),
          _field(
            _email,
            hint: 'you@example.com',
            icon: Icons.mail_outline,
            keyboard: TextInputType.emailAddress,
            enabled: !_signedIn,
            validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
          ),
          if (!_signedIn) ...[
            _label('Create a password'),
            _field(
              _password,
              hint: 'At least 8 characters',
              icon: Icons.lock_outline,
              obscure: !_showPassword,
              suffix: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              validator: (v) => (v ?? '').length < 8 ? 'Password must be at least 8 characters' : null,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text('You will sign in with this email and password after approval.',
                  style: GoogleFonts.inter(fontSize: 11, color: _muted)),
            ),
          ],
          _label('State'),
          _dropdown<int>(
            value: _stateId,
            hint: 'Select state',
            items: [for (final s in _loc.states) DropdownMenuItem(value: s.id, child: Text(s.nameEn))],
            onChanged: (v) {
              setState(() {
                _stateId = v;
                _districtId = null;
                _mandalId = null;
                _mandals = const [];
              });
            },
            validator: (v) => v == null ? 'Please select your state' : null,
          ),
          _label('District'),
          _dropdown<int>(
            value: _districtId,
            hint: _stateId == null ? 'Select state first' : 'Select district',
            items: [for (final d in districts) DropdownMenuItem(value: d.id, child: Text(d.nameEn))],
            onChanged: _stateId == null ? null : _pickDistrict,
            validator: (v) => v == null ? 'Please select your district' : null,
          ),
          _label('Mandal (optional)'),
          _dropdown<int>(
            value: _mandalId,
            hint: _districtId == null
                ? 'Select district first'
                : _loadingMandals
                    ? 'Loading mandals…'
                    : 'Select mandal',
            items: [for (final m in _mandals) DropdownMenuItem(value: m.id, child: Text(m.nameEn))],
            onChanged: _mandals.isEmpty ? null : (v) => setState(() => _mandalId = v),
          ),
          _label('Address (optional)'),
          _field(_address, hint: 'Village / town, street', icon: Icons.home_outlined, maxLines: 2),
          const SizedBox(height: 26),
          SizedBox(
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text('Submit application', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _success(ContributorApplication app) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: _gold.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 46, color: _gold),
            ),
            const SizedBox(height: 22),
            Text('Application submitted', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 10),
            Text(
              'Thank you, ${app.fullName}. Your ${app.roleLabel.toLowerCase()} application is under review. '
              '${_signedIn ? 'Once approved, the "Submit news" option will appear in your account.' : 'Once the admin approves it, sign in with ${app.email} and your password to start sending news.'}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: _muted),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _ink),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(String value, IconData icon, String title, String subtitle) {
    final selected = _role == value;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? _ink : _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? _gold : _ink, size: 24),
            const SizedBox(height: 10),
            Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: selected ? Colors.white : _ink)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: selected ? Colors.white70 : _muted)),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 14, bottom: 6),
        child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
      );

  InputDecoration _decoration(String hint, {IconData? icon, Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
        prefixIcon: icon == null ? null : Icon(icon, size: 20, color: _muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _ink, width: 1.4)),
      );

  Widget _field(
    TextEditingController c, {
    required String hint,
    IconData? icon,
    TextInputType? keyboard,
    bool obscure = false,
    bool enabled = true,
    int maxLines = 1,
    Widget? suffix,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: c,
        keyboardType: keyboard,
        obscureText: obscure,
        enabled: enabled,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 14, color: _ink),
        decoration: _decoration(hint, icon: icon, suffix: suffix),
      );

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? Function(T?)? validator,
  }) =>
      DropdownButtonFormField<T>(
        key: ValueKey('$hint-${items.length}-$value'),
        initialValue: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        isExpanded: true,
        style: GoogleFonts.inter(fontSize: 14, color: _ink),
        decoration: _decoration(hint),
        hint: Text(hint, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF))),
      );
}
