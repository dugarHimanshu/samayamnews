// lib/utils/display_formatters.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utilities to display languages and district names neatly, compactly,
/// and attractively throughout the application without appearing overly long.
class DisplayFormatters {
  DisplayFormatters._();

  // ============================================================
  // DISTRICT FORMATTING & ALIASES
  // ============================================================

  /// Map of known lengthy or official district names to their common,
  /// neat, and recognizable short display names.
  static const Map<String, String> _districtShortNames = {
    // Andhra Pradesh
    'Dr. B. R. Ambedkar Konaseema': 'Konaseema',
    'Dr. B.R. Ambedkar Konaseema': 'Konaseema',
    'Sri Potti Sriramulu Nellore': 'Nellore',
    'S.P.S. Nellore': 'Nellore',
    'Alluri Sitharama Raju': 'Alluri Sitharama',
    'YSR District (Kadapa)': 'Kadapa',
    'Y.S.R.': 'Kadapa',
    'Parvathipuram Manyam': 'Manyam',
    'Sri Sathya Sai': 'Sathya Sai',

    // Telangana
    'Jayashankar Bhupalpally': 'Bhupalpally',
    'Komaram Bheem Asifabad': 'Asifabad',
    'Bhadradri Kothagudem': 'Kothagudem',
    'Jogulamba Gadwal': 'Gadwal',
    'Rajanna Sircilla': 'Sircilla',
    'Yadadri Bhuvanagiri': 'Bhuvanagiri',
    'Medchal-Malkajgiri': 'Medchal',
    'Jangoan': 'Jangaon',
  };

  /// Returns a clean, attractive, and concise district name.
  static String shortDistrict(String district) {
    final trimmed = district.trim();
    if (trimmed.isEmpty) return 'Location';
    return _districtShortNames[trimmed] ?? trimmed;
  }

  /// Returns the standard two-letter state code.
  static String stateCode(String state) {
    final lower = state.toLowerCase().trim();
    if (lower.contains('andhra')) return 'AP';
    if (lower.contains('telangana')) return 'TS';
    if (lower.contains('karnataka')) return 'KA';
    if (lower.contains('tamil')) return 'TN';
    if (lower.contains('kerala')) return 'KL';
    if (lower.contains('maharashtra')) return 'MH';
    return state.length > 3 ? state.substring(0, 3).toUpperCase() : state.toUpperCase();
  }

  /// Formats district and state into a neat, compact one-liner.
  /// Example: "Konaseema, AP" or "Nellore, AP".
  static String compactLocation(String district, [String? state]) {
    final shortDist = shortDistrict(district);
    if (state == null || state.trim().isEmpty) {
      return shortDist;
    }
    final code = stateCode(state);
    return '$shortDist, $code';
  }

  // ============================================================
  // LANGUAGE FORMATTING & DATA
  // ============================================================

  static const List<LanguageModel> supportedLanguages = [
    LanguageModel(
      id: 'English',
      nativeName: 'English',
      englishName: 'English',
      code: 'EN',
      flagOrIcon: 'A',
    ),
    LanguageModel(
      id: 'Hindi',
      nativeName: 'हिन्दी',
      englishName: 'Hindi',
      code: 'HI',
      flagOrIcon: 'अ',
    ),
    LanguageModel(
      id: 'Telugu',
      nativeName: 'తెలుగు',
      englishName: 'Telugu',
      code: 'TE',
      flagOrIcon: 'తె',
    ),
  ];

  /// Returns the native script name for a language.
  static String languageNativeName(String lang) {
    final lower = lang.toLowerCase().trim();
    if (lower == 'hindi' || lower == 'hi') return 'हिन्दी';
    if (lower == 'telugu' || lower == 'te') return 'తెలుగు';
    return 'English';
  }

  /// Returns the two-letter language code (EN, HI, TE).
  static String languageCode(String lang) {
    final lower = lang.toLowerCase().trim();
    if (lower == 'hindi' || lower == 'hi') return 'HI';
    if (lower == 'telugu' || lower == 'te') return 'TE';
    return 'EN';
  }

  /// Returns a neat display title (e.g. "हिन्दी (Hindi)").
  static String languageDisplayName(String lang) {
    final lower = lang.toLowerCase().trim();
    if (lower == 'hindi' || lower == 'hi') return 'हिन्दी (Hindi)';
    if (lower == 'telugu' || lower == 'te') return 'తెలుగు (Telugu)';
    return 'English';
  }
}

/// Metadata model for clean language representation
class LanguageModel {
  final String id;
  final String nativeName;
  final String englishName;
  final String code;
  final String flagOrIcon;

  const LanguageModel({
    required this.id,
    required this.nativeName,
    required this.englishName,
    required this.code,
    required this.flagOrIcon,
  });
}

/// A neat, attractive badge displaying the selected language.
class LanguagePill extends StatelessWidget {
  final String language;
  final bool isDark;
  final VoidCallback? onTap;

  const LanguagePill({
    super.key,
    required this.language,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nativeName = DisplayFormatters.languageNativeName(language);
    final code = DisplayFormatters.languageCode(language);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282C38) : const Color(0xFFF1F3F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            nativeName,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: pill,
    );
  }
}

/// A neat, attractive badge displaying district and state.
class LocationPill extends StatelessWidget {
  final String district;
  final String state;
  final bool isDark;
  final VoidCallback? onTap;

  const LocationPill({
    super.key,
    required this.district,
    required this.state,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortDist = DisplayFormatters.shortDistrict(district);
    final stCode = DisplayFormatters.stateCode(state);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282C38) : const Color(0xFFF1F3F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 13,
            color: Color(0xFFE53935),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              shortDist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              stCode,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: pill,
    );
  }
}

/// A compact, attractive bottom sheet for choosing between the 3 languages.
class NeatLanguagePickerSheet extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onSelected;

  const NeatLanguagePickerSheet({
    super.key,
    required this.currentLanguage,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentLanguage,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => NeatLanguagePickerSheet(
        currentLanguage: currentLanguage,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E2028) : Colors.white;
    final cardBg = isDark ? const Color(0xFF282C38) : const Color(0xFFF7F8FA);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      size: 18,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select App Language',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'App content will adapt to your language',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // The 3 supported languages in attractive cards
              ...DisplayFormatters.supportedLanguages.map((langModel) {
                final isSelected = langModel.id.toLowerCase() ==
                    currentLanguage.toLowerCase();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Material(
                    color: isSelected
                        ? (isDark
                            ? const Color(0xFF1565C0).withValues(alpha: 0.22)
                            : const Color(0xFFEBF3FE))
                        : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(langModel.id);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : (isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05)),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon / Flag Avatar
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1565C0)
                                    : (isDark
                                        ? Colors.white12
                                        : Colors.black.withValues(alpha: 0.06)),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                langModel.flagOrIcon,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    langModel.nativeName,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    langModel.englishName,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                langModel.code,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: Color(0xFF1565C0),
                              ),
                          ],
                        ),
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
  }
}
