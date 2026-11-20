import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:translator/translator.dart';

import '../../models/news_article.dart';
import '../../widgets/common/app_media_viewer.dart';

class NewsStoryPage extends StatefulWidget {
  final NewsArticle article;
  final String selectedLanguage;

  const NewsStoryPage({
    super.key,
    required this.article,
    required this.selectedLanguage,
  });

  @override
  State<NewsStoryPage> createState() => _NewsStoryPageState();
}

class _NewsStoryPageState extends State<NewsStoryPage> {
  bool _liked = false;
  String _currentLanguage = 'English';
  bool _isTranslating = false;

  String _translatedTitle = '';
  String _translatedDescription = '';
  String _translatedBody = '';

  late String _originalTitle;
  late String _originalDescription;
  late String _originalBody;

  final GoogleTranslator _translator = GoogleTranslator();

  final Map<String, String> _languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Telugu': 'te',
    'Hinglish': 'hi',
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.selectedLanguage;
    _originalTitle = widget.article.title;
    _originalDescription = widget.article.description;
    _originalBody = widget.article.content.isNotEmpty
        ? widget.article.content
        : widget.article.description;

    _translatedTitle = _originalTitle;
    _translatedDescription = _originalDescription;
    _translatedBody = _originalBody;

    if (_currentLanguage != 'English') {
      _translateContent(_currentLanguage);
    }
  }

  // ---- Custom Hinglish transliterator ----
  String _toHinglish(String devanagariText) {
    final Map<String, String> map = {
      'नमस्ते': 'Namaste',
      'धन्यवाद': 'Dhanyavaad',
      'शुक्रिया': 'Shukriya',
      'महात्मा गांधी': 'Mahatma Gandhi',
      'भारत': 'Bharat',
      'हिंदी': 'Hindi',
      'अंग्रेज़ी': 'Angrezi',
      'क्या': 'Kya',
      'हाँ': 'Haan',
      'नहीं': 'Nahi',
      'मुझे': 'Mujhe',
      'तुम': 'Tum',
      'आप': 'Aap',
      'हम': 'Hum',
      'उन्हें': 'Unhein',
      'उसका': 'Uska',
      'मेरा': 'Mera',
      'तेरा': 'Tera',
      'अच्छा': 'Accha',
      'बुरा': 'Bura',
      'छोटा': 'Chhota',
      'बड़ा': 'Bada',
      'नया': 'Naya',
      'पुराना': 'Purana',
      'घर': 'Ghar',
      'पानी': 'Paani',
      'खाना': 'Khana',
      'पीना': 'Peena',
      'सोना': 'Sona',
      'जाना': 'Jaana',
      'आना': 'Aana',
      'देना': 'Dena',
      'लेना': 'Lena',
      'करना': 'Karna',
      'होना': 'Hona',
      'रहना': 'Rehna',
      'चाहिए': 'Chahiye',
      'वह': 'Vah',
      'वे': 'Ve',
      'यह': 'Yeh',
      'ये': 'Ye',
      'क्ष': 'ksh',
      'त्र': 'tr',
      'ज्ञ': 'gya',
      'श्र': 'shr',
      'क्र': 'kr',
      'ग्र': 'gr',
      'प्र': 'pr',
      'ब्र': 'br',
      'द्व': 'dv',
      'द्य': 'dy',
      'द्र': 'dr',
      'न्य': 'ny',
      'त्य': 'ty',
      'स्य': 'sy',
      'ह्य': 'hy',
      'क्य': 'ky',
      'ग्य': 'gy',
      'भ्य': 'bhy',
      'म्य': 'my',
      'व्य': 'vy',
      'श्य': 'shy',
      'ष्ट': 'sht',
      'ष्ठ': 'shth',
      'ष्ण': 'shn',
      'स्व': 'sv',
      'हृ': 'hri',
      'कृ': 'kri',
      'दृ': 'dri',
      'अ': 'a',
      'आ': 'aa',
      'इ': 'i',
      'ई': 'ee',
      'उ': 'u',
      'ऊ': 'oo',
      'ए': 'e',
      'ऐ': 'ai',
      'ओ': 'o',
      'औ': 'au',
      'ऋ': 'ri',
      'ॠ': 'ree',
      'ऌ': 'li',
      'ॡ': 'lee',
      'क': 'k',
      'ख': 'kh',
      'ग': 'g',
      'घ': 'gh',
      'ङ': 'ng',
      'च': 'ch',
      'छ': 'chh',
      'ज': 'j',
      'झ': 'jh',
      'ञ': 'ny',
      'ट': 't',
      'ठ': 'th',
      'ड': 'd',
      'ढ': 'dh',
      'ण': 'n',
      'त': 't',
      'थ': 'th',
      'द': 'd',
      'ध': 'dh',
      'न': 'n',
      'प': 'p',
      'फ': 'ph',
      'ब': 'b',
      'भ': 'bh',
      'म': 'm',
      'य': 'y',
      'र': 'r',
      'ल': 'l',
      'व': 'v',
      'श': 'sh',
      'ष': 'sh',
      'स': 's',
      'ह': 'h',
      'ा': 'a',
      'ि': 'i',
      'ी': 'ee',
      'ु': 'u',
      'ू': 'oo',
      'े': 'e',
      'ै': 'ai',
      'ो': 'o',
      'ौ': 'au',
      'ृ': 'ri',
      'ॄ': 'ree',
      'ॅ': 'e',
      'ॉ': 'o',
      'ॆ': 'e',
      'ॊ': 'o',
      'ं': 'n',
      'ः': 'h',
      '्': '',
      'ॐ': 'om',
      '।': '.',
      '॥': '..',
      '०': '0',
      '१': '1',
      '२': '2',
      '३': '3',
      '४': '4',
      '५': '5',
      '६': '6',
      '७': '7',
      '८': '8',
      '९': '9',
    };

    List<String> keys = map.keys.toList();
    keys.sort((a, b) => b.length.compareTo(a.length));

    String result = devanagariText;
    for (String key in keys) {
      result = result.replaceAll(key, map[key]!);
    }

    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  Future<void> _translateContent(String language) async {
    if (language == 'English') {
      setState(() {
        _translatedTitle = _originalTitle;
        _translatedDescription = _originalDescription;
        _translatedBody = _originalBody;
      });
      return;
    }

    setState(() => _isTranslating = true);

    try {
      String code = _languageCodes[language] ?? 'en';
      bool isHinglish = (language == 'Hinglish');

      final results = await Future.wait([
        _translator.translate(_originalTitle, to: code),
        _translator.translate(_originalDescription, to: code),
        _translator.translate(_originalBody, to: code),
      ]);

      String title = results[0].text;
      String description = results[1].text;
      String body = results[2].text;

      if (isHinglish) {
        title = _toHinglish(title);
        description = _toHinglish(description);
        body = _toHinglish(body);
      }

      if (mounted) {
        setState(() {
          _translatedTitle = title;
          _translatedDescription = description;
          _translatedBody = body;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() => _liked = !_liked);
  }

  void _showLanguageSelector() {
    final languages = _languageCodes.keys.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Read in',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Choose a language',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 19,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...languages.map((language) {
                    final selected = language == _currentLanguage;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.pop(context);

                          if (_currentLanguage == language) {
                            return;
                          }

                          setState(() {
                            _currentLanguage = language;
                          });

                          _translateContent(language);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.black
                                : const Color(0xFFF6F6F4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? Colors.black
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  selected
                                      ? Icons.check_rounded
                                      : Icons.language_rounded,
                                  size: 18,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black45,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  language,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (selected)
                                Text(
                                  'CURRENT',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;

    final displayTitle = _translatedTitle.isNotEmpty
        ? _translatedTitle
        : widget.article.title;
    final displayDescription = _translatedDescription.isNotEmpty
        ? _translatedDescription
        : widget.article.description;
    final displayBody = _translatedBody.isNotEmpty
        ? _translatedBody
        : _originalBody;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F6),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.55,
                pinned: true,
                backgroundColor: Colors.black,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppMediaViewer(
                        url: widget.article.imageUrl,
                        fit: BoxFit.cover,
                        autoPlay: true,
                        looping: true,
                        showControls: true,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.4, 0.8, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),

                      // App Logo — Top Left (Responsive Scale)
                      Positioned(
                        top: topPad + 12,
                        left: 16,
                        child: Image.asset(
                          'assets/public/images/watermark/app_logo.png',
                          width: screenWidth * 0.085,
                          height: screenWidth * 0.085,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),

                      // Top-Right Watermark (Responsive Scale & Increased Width)
                      Positioned(
                        top: topPad + 10,
                        right: 16,
                        child: Transform.translate(
                          offset: const Offset(4, -4),
                          child: Image.asset(
                            'assets/public/images/watermark/watermark_top_right.png',
                            width: screenWidth * 0.14,
                            height: screenWidth * 0.14,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),

                      // Bottom-Left Watermark (Responsive Scale & Increased Width)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Transform.translate(
                            offset: const Offset(-5, 29),
                            child: Image.asset(
                              'assets/public/images/watermark/watermark_bottom_left.png',
                              width: screenWidth * 0.42,
                              height: (screenWidth * 0.42) * 0.45,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 20,
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            widget.article.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                automaticallyImplyLeading: false,
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title using Poppins Font
                      Text(
                        displayTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _initial(widget.article.author),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.article.author,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  widget.article.publishedAt,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message:
                                'Change language (current: $_currentLanguage)',
                            child: GestureDetector(
                              onTap: _isTranslating
                                  ? null
                                  : _showLanguageSelector,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  shape: BoxShape.circle,
                                ),
                                child: _isTranslating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black54,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.translate_rounded,
                                        size: 20,
                                        color: Colors.black54,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      if (_isTranslating)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayDescription,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                height: 1.7,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              displayBody,
                              style: GoogleFonts.inter(
                                fontSize: 15.5,
                                height: 1.8,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 40),

                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 2,
                              color: Colors.black12,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '— FINISH —',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Thank you for reading.',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            top: topPad + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 32,
            right: 24,
            child: GestureDetector(
              onTap: _toggleLike,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _liked ? Colors.redAccent : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    _liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(_liked),
                    size: 28,
                    color: _liked ? Colors.white : Colors.black45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String name) {
    return name.trim().isEmpty ? '•' : name.trim()[0].toUpperCase();
  }
}