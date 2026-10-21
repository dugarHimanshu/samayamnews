import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/auth_service.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../editor/editor_dashboard_screen.dart';
import 'language_selection_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // false = Sign In
  // true  = Create Account
  bool _isSignUp = false;

  @override
  void dispose() {
    // Clear values before disposing the controllers.
    // This does not replace OS-level secure memory handling,
    // but avoids unnecessarily retaining credentials in the
    // controller objects.
    _emailController.clear();
    _passwordController.clear();

    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN / SIGN UP
  // ============================================================

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ==========================================================
      // CREATE ACCOUNT
      // ==========================================================

      if (_isSignUp) {
        await AuthService.instance.signUpWithEmail(
          email: email,
          password: password,
        );

        if (!mounted) return;

        // Do not expose database/auth internals.
        _showMessage(
          'Your account has been created. '
          'Please check your email to continue.',
        );

        _clearCredentials();

        setState(() {
          _isSignUp = false;
        });

        return;
      }

      // ==========================================================
      // SIGN IN
      // ==========================================================

      await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // The password is no longer needed by this screen.
      _passwordController.clear();

      // ==========================================================
      // LOAD AUTHORIZATION ROLE
      // ==========================================================

      final role = await AuthService.instance.getCurrentUserRole();

      if (!mounted) return;

      // Do not print or expose:
      // - email
      // - password
      // - user ID
      // - access token
      // - refresh token
      // - session
      // - role
      //
      // Role is used only for routing.

      // ==========================================================
      // ADMIN
      // ==========================================================

      if (role == 'admin') {
        _clearCredentials();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );

        return;
      }

      // ==========================================================
      // EDITOR
      // ==========================================================

      if (role == 'editor') {
        _clearCredentials();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EditorDashboardScreen()),
        );

        return;
      }

      // ==========================================================
      // NORMAL READER / CONTRIBUTOR
      // ==========================================================

      if (role == 'freelancer' || role == 'employee') {
        _clearCredentials();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
        );

        return;
      }

      // ==========================================================
      // UNKNOWN / INVALID ROLE
      // ==========================================================
      //
      // Never allow an unrecognized role to continue into the
      // application. Sign out immediately.
      //

      await AuthService.instance.signOut();

      if (!mounted) return;

      _clearCredentials();

      throw Exception(
        'We could not verify your account permissions. '
        'Please contact support.',
      );
    } on AuthException catch (_) {
      // AuthService normally converts AuthException to Exception,
      // but keep this branch for safety if that behavior changes.
      if (!mounted) return;

      _clearCredentials();

      _showGenericAuthError();
    } catch (e) {
      if (!mounted) return;

      _clearCredentials();

      final message = e.toString();

      // Avoid exposing database/query/security implementation
      // details to the user.
      if (_isSensitiveInternalError(message)) {
        _showGenericAuthError();
      } else {
        _showMessage(message.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CLEAR CREDENTIALS
  // ============================================================

  void _clearCredentials() {
    _emailController.clear();
    _passwordController.clear();
  }

  // ============================================================
  // GENERIC AUTH ERROR
  // ============================================================

  void _showGenericAuthError() {
    _showMessage(
      'Unable to sign in with those details. '
      'Please check your information and try again.',
    );
  }

  // ============================================================
  // INTERNAL ERROR FILTER
  // ============================================================

  bool _isSensitiveInternalError(String message) {
    final lower = message.toLowerCase();

    const sensitiveTerms = [
      'postgres',
      'postgrest',
      'supabase',
      'row level security',
      'rls',
      'jwt',
      'access token',
      'refresh token',
      'session',
      'profile query',
      'database',
      'sql',
      'uuid',
      'auth.uid',
      'permission denied',
      'function',
      'trigger',
    ];

    return sensitiveTerms.any(lower.contains);
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
          content: Text(
            message,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF202124),
          duration: const Duration(milliseconds: 3200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ============================================================
          // AURORA BACKGROUND
          // ============================================================
          const RepaintBoundary(child: _AuroraBackground()),

          // ============================================================
          // CONTENT
          // ============================================================
          SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // BACK BUTTON
                      // ==================================================
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          _clearCredentials();
                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(height: 42),

                      // ==================================================
                      // BRAND / SECURITY MARK
                      // ==================================================
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFEFF3F8)],
                          ),
                          border: Border.all(color: Colors.white, width: 1.3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF718096,
                              ).withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          size: 25,
                          color: Color(0xFF4B5563),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // HEADING
                      // ==================================================
                      Text(
                        _isSignUp ? 'Create' : 'Welcome',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          height: 0.98,
                          color: const Color(0xFF17181B),
                        ),
                      ),

                      Text(
                        _isSignUp ? 'account.' : 'back.',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          height: 0.98,
                          color: const Color(0xFF17181B),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        _isSignUp
                            ? 'Sign up to start reading your world.'
                            : 'Sign in to continue reading your world.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          height: 1.5,
                          color: const Color(0xFF686E78),
                        ),
                      ),

                      const SizedBox(height: 34),

                      // ==================================================
                      // LOGIN CARD
                      // ==================================================
                      RepaintBoundary(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF64748B,
                                ).withValues(alpha: 0.07),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ========================================
                              // EMAIL
                              // ========================================
                              const _FieldLabel(label: 'EMAIL ADDRESS'),

                              const SizedBox(height: 9),

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                enabled: !_isLoading,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF202124),
                                ),
                                decoration: _inputDecoration(
                                  hint: 'you@example.com',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email address';
                                  }

                                  final email = value.trim();

                                  if (email.length > 254) {
                                    return 'Please enter a valid email address';
                                  }

                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );

                                  if (!emailRegex.hasMatch(email)) {
                                    return 'Please enter a valid email address';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 22),

                              // ========================================
                              // PASSWORD
                              // ========================================
                              const _FieldLabel(label: 'PASSWORD'),

                              const SizedBox(height: 9),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!_isLoading) {
                                    _login();
                                  }
                                },
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const [AutofillHints.password],
                                enabled: !_isLoading,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF202124),
                                ),
                                decoration:
                                    _inputDecoration(
                                      hint: 'Enter your password',
                                      icon: Icons.lock_outline_rounded,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        splashRadius: 20,
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFF777E89),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }

                                  if (value.length < 6) {
                                    return 'Password must contain at least 6 characters';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              // ========================================
                              // FORGOT PASSWORD
                              // ========================================
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading ? null : () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF34383F),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ========================================
                              // SIGN IN / CREATE ACCOUNT BUTTON
                              // ========================================
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading ? null : _login,
                                    borderRadius: BorderRadius.circular(21),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF242629),
                                            Color(0xFF111214),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(21),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.14,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 100,
                                        ),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        child: _isLoading
                                            ? const SizedBox(
                                                key: ValueKey('loading'),
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : _SignInContent(
                                                isSignUp: _isSignUp,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // DIVIDER
                      // ==================================================
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                                color: const Color(0xFF9A9FA7),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // GOOGLE BUTTON
                      // ==================================================
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : () {},
                          borderRadius: BorderRadius.circular(21),
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(21),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.035),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const _GoogleButtonContent(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ==================================================
                      // ACCOUNT FOOTER
                      // ==================================================
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();

                                  _clearCredentials();

                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                  });
                                },
                          child: Text.rich(
                            TextSpan(
                              text: _isSignUp
                                  ? 'Already have an account? '
                                  : "Don't have an account? ",
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF8A9099),
                              ),
                              children: [
                                TextSpan(
                                  text: _isSignUp ? 'Sign in' : 'Create one',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF30343A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // SECURITY
                      // ==================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: Color(0xFF9BA1AA),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Your information is securely protected',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              color: const Color(0xFF9BA1AA),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 13.5,
        color: const Color(0xFFA7ACB4),
      ),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF777E89)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.82),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white, width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF555A63), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.2),
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ============================================================
// AURORA BACKGROUND
// ============================================================

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: _AuroraOrb(
              size: 330,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFDCE9FF),
                  Color(0xFFE7DEFF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),
          Positioned(
            top: 270,
            left: -170,
            child: _AuroraOrb(
              size: 350,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFDDF8F0),
                  Color(0xFFE4F0FF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -120,
            child: _AuroraOrb(
              size: 330,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFE5EE),
                  Color(0xFFE9E2FF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FIELD LABEL
// ============================================================

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
        color: const Color(0xFF707680),
      ),
    );
  }
}

// ============================================================
// GLASS ICON BUTTON
// ============================================================

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF30343A)),
        ),
      ),
    );
  }
}

// ============================================================
// AURORA ORB
// ============================================================

class _AuroraOrb extends StatelessWidget {
  final double size;
  final Gradient gradient;

  const _AuroraOrb({required this.size, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      ),
    );
  }
}

// ============================================================
// SIGN IN / CREATE ACCOUNT BUTTON CONTENT
// ============================================================

class _SignInContent extends StatelessWidget {
  final bool isSignUp;

  const _SignInContent({required this.isSignUp});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('signin'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSignUp ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
          size: 19,
          color: Colors.white,
        ),
        const SizedBox(width: 10),
        Text(
          isSignUp ? 'Create Account' : 'Sign In',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 9),
        const Icon(
          Icons.arrow_forward_rounded,
          size: 18,
          color: Colors.white70,
        ),
      ],
    );
  }
}

// ============================================================
// GOOGLE BUTTON CONTENT
// ============================================================

class _GoogleButtonContent extends StatelessWidget {
  const _GoogleButtonContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            'G',
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4285F4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Continue with Google',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF30343A),
          ),
        ),
      ],
    );
  }
}