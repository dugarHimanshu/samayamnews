import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'language_selection_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          phoneNumber: '+91 ${_phoneController.text.trim()}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F6),
      body: Stack(
        children: [
          _buildAuroraBackground(),

          SafeArea(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GlassBackButton(),

                      const SizedBox(height: 48),

                      // ==================================================
                      // HEADER
                      // ==================================================
                      Text(
                        'Your phone.',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 41,
                          fontWeight: FontWeight.w600,
                          height: 1.02,
                          color: const Color(0xFF151515),
                        ),
                      ),

                      Text(
                        'Your access.',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 41,
                          fontWeight: FontWeight.w600,
                          height: 1.02,
                          color: const Color(0xFF151515),
                        ),
                      ),

                      const SizedBox(height: 13),

                      Text(
                        'Enter your mobile number and we’ll send you a verification code.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          height: 1.55,
                          color: const Color(0xFF777777),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ==================================================
                      // INPUT GLASS CARD
                      // ==================================================
                      _GlassInputPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MOBILE NUMBER',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.35,
                                color: const Color(0xFF8A8A8A),
                              ),
                            ),

                            const SizedBox(height: 11),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // COUNTRY CODE
                                Container(
                                  height: 61,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFF1F1ED),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(17),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.055,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(2, 5),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '🇮🇳  +91',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF292929),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 9),

                                // PHONE FIELD
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    maxLength: 10,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: '9876543210',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFFB5B5B5),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 18,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(17),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(17),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(17),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFB99552),
                                          width: 1.2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(17),
                                        borderSide: const BorderSide(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(17),
                                        borderSide: const BorderSide(
                                          color: Colors.redAccent,
                                          width: 1.2,
                                        ),
                                      ),
                                      errorStyle: GoogleFonts.inter(
                                        fontSize: 9.5,
                                      ),
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF222222),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter your mobile number';
                                      }

                                      if (!RegExp(
                                        r'^[0-9]{10}$',
                                      ).hasMatch(value.trim())) {
                                        return 'Enter a valid 10-digit number';
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // SEND OTP
                      // ==================================================
                      _LuxuryPrimaryButton(
                        label: 'Send OTP',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: _isLoading,
                        onTap: _isLoading ? null : _sendOtp,
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          'By continuing, you agree to our Terms & Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: const Color(0xFF9A9A9A),
                          ),
                        ),
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

  Widget _buildAuroraBackground() {
    return Stack(
      children: [
        Positioned(
          top: -130,
          right: -130,
          child: _AuroraBlob(size: 360, color: const Color(0x52D8C6FF)),
        ),
        Positioned(
          top: 280,
          left: -170,
          child: _AuroraBlob(size: 330, color: const Color(0x45BEEBFF)),
        ),
        Positioned(
          bottom: -170,
          right: -90,
          child: _AuroraBlob(size: 360, color: const Color(0x42E7D19D)),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE8FFFFFF),
                  Color(0xB9FFFFFF),
                  Color(0xF2F8F8F6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// OTP VERIFICATION SCREEN
// ================================================================

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;

  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();

    _startCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) {
        return false;
      }

      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });

        return true;
      }

      return false;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final String otp = _controllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the complete 6-digit OTP.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF222222),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
    );
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    final bool isComplete = _controllers.every(
      (controller) => controller.text.isNotEmpty,
    );

    if (isComplete && !_isLoading) {
      _verifyOtp();
    }
  }

  void _resendOtp() {
    if (_secondsRemaining > 0) {
      return;
    }

    for (final controller in _controllers) {
      controller.clear();
    }

    setState(() {
      _secondsRemaining = 30;
    });

    _focusNodes[0].requestFocus();

    _startCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A new OTP has been sent.',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF222222),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F6),
      body: Stack(
        children: [
          _buildAuroraBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassBackButton(),

                  const SizedBox(height: 48),

                  Text(
                    'Verify your',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 41,
                      fontWeight: FontWeight.w600,
                      height: 1.02,
                      color: const Color(0xFF151515),
                    ),
                  ),

                  Text(
                    'number.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 41,
                      fontWeight: FontWeight.w600,
                      height: 1.02,
                      color: const Color(0xFF151515),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'We sent a 6-digit verification code to',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF777777),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    child: Text(
                      widget.phoneNumber,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF292929),
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  // ==================================================
                  // OTP GLASS PANEL
                  // ==================================================
                  ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(15, 17, 15, 17),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.055),
                              blurRadius: 28,
                              offset: const Offset(0, 13),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return _OtpField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              onChanged: (value) {
                                _onOtpChanged(value, index);
                              },
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: _secondsRemaining > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            child: Text(
                              'Resend OTP in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8A8A8A),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _resendOtp,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE9D39D),
                                    Color(0xFFB98B45),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x40B58A43),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Resend OTP',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),

                  const Spacer(),

                  // ==================================================
                  // VERIFY BUTTON
                  // ==================================================
                  _LuxuryPrimaryButton(
                    label: 'Verify Number',
                    icon: Icons.verified_rounded,
                    isLoading: _isLoading,
                    onTap: _isLoading ? null : _verifyOtp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuroraBackground() {
    return Stack(
      children: [
        Positioned(
          top: -140,
          right: -140,
          child: _AuroraBlob(size: 370, color: const Color(0x52D8C6FF)),
        ),
        Positioned(
          top: 260,
          left: -180,
          child: _AuroraBlob(size: 350, color: const Color(0x45BEEBFF)),
        ),
        Positioned(
          bottom: -180,
          right: -100,
          child: _AuroraBlob(size: 380, color: const Color(0x42E7D19D)),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE8FFFFFF),
                  Color(0xB9FFFFFF),
                  Color(0xF2F8F8F6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// GLASS BACK BUTTON
// ================================================================

class _GlassBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: Color(0xFF222222),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// GLASS INPUT PANEL
// ================================================================

class _GlassInputPanel extends StatelessWidget {
  final Widget child;

  const _GlassInputPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(27),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.53),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ================================================================
// LUXURY PRIMARY BUTTON
// ================================================================

class _LuxuryPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _LuxuryPrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF292929), Color(0xFF080808)],
            ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0x35C49B57),
                blurRadius: 20,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE9D39D),
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('button'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(icon, size: 18, color: const Color(0xFFE8CB91)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// OTP FIELD
// ================================================================

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 43,
      height: 58,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF202020),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.82),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.95)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFC09A59), width: 1.4),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ================================================================
// AURORA BLOB
// ================================================================

class _AuroraBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _AuroraBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.13), Colors.transparent],
            stops: const [0.0, 0.48, 1.0],
          ),
        ),
      ),
    );
  }
}