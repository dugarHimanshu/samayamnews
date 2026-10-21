import 'dart:convert';

import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService._();

  static final TranslationService instance = TranslationService._();

  final Map<String, String> _cache = {};

  Future<String> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'en',
  }) async {
    if (text.trim().isEmpty) {
      return text;
    }

    if (targetLanguage == sourceLanguage) {
      return text;
    }

    final cacheKey = '$sourceLanguage|$targetLanguage|$text';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx'
      '&sl=$sourceLanguage'
      '&tl=$targetLanguage'
      '&dt=t'
      '&q=${Uri.encodeQueryComponent(text)}',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Translation request failed: '
          '${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      final translatedText = _extractTranslation(decoded);

      if (translatedText.trim().isEmpty) {
        throw Exception('Translation returned empty text.');
      }

      _cache[cacheKey] = translatedText;

      return translatedText;
    } catch (e) {
      throw Exception('Unable to translate article right now.');
    }
  }

  String _extractTranslation(dynamic data) {
    if (data is! List || data.isEmpty) {
      return '';
    }

    final translations = data[0];

    if (translations is! List) {
      return '';
    }

    final buffer = StringBuffer();

    for (final item in translations) {
      if (item is List && item.isNotEmpty) {
        final value = item[0];

        if (value is String) {
          buffer.write(value);
        }
      }
    }

    return buffer.toString();
  }

  void clearCache() {
    _cache.clear();
  }
}