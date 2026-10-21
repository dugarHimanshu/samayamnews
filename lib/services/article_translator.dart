import 'package:translator/translator.dart';

class ArticleTranslator {
  static final GoogleTranslator _translator = GoogleTranslator();

  static const Map<String, String> languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Telugu': 'te',
    'Hinglish': 'hi',
  };

  // ---------------------------------------------------------------------------
  // HINGLISH WORD DICTIONARY
  // ---------------------------------------------------------------------------

  static const Map<String, String> _commonWords = {
    // Greetings / common
    'नमस्ते': 'namaste',
    'नमस्कार': 'namaskar',
    'धन्यवाद': 'dhanyavaad',
    'शुक्रिया': 'shukriya',
    'स्वागत': 'swaagat',
    'कृपया': 'kripya',
    'माफ़': 'maaf',
    'माफ': 'maaf',

    // Pronouns
    'मैं': 'main',
    'हम': 'hum',
    'हमारा': 'hamaara',
    'हमारी': 'hamaari',
    'हमारे': 'hamaare',
    'मेरा': 'mera',
    'मेरी': 'meri',
    'मेरे': 'mere',
    'मुझे': 'mujhe',
    'मुझ': 'mujh',
    'मैंने': 'maine',
    'हमने': 'humne',
    'तू': 'tu',
    'तुम': 'tum',
    'तुम्हारा': 'tumhaara',
    'तुम्हारी': 'tumhaari',
    'तुम्हारे': 'tumhaare',
    'तुम्हें': 'tumhein',
    'तुमको': 'tumko',
    'आप': 'aap',
    'आपका': 'aapka',
    'आपकी': 'aapki',
    'आपके': 'aapke',
    'आपको': 'aapko',
    'आपने': 'aapne',
    'यह': 'yeh',
    'ये': 'ye',
    'वह': 'woh',
    'वो': 'wo',
    'वे': 've',
    'इन': 'in',
    'इनका': 'inka',
    'इनकी': 'inki',
    'इनके': 'inke',
    'उन': 'un',
    'उनका': 'unka',
    'उनकी': 'unki',
    'उनके': 'unke',
    'इस': 'is',
    'इसका': 'iska',
    'इसकी': 'iski',
    'इसके': 'iske',
    'उस': 'us',
    'उसका': 'uska',
    'उसकी': 'uski',
    'उसके': 'uske',
    'जो': 'jo',
    'जिस': 'jis',
    'जिसका': 'jiska',
    'जिसकी': 'jiski',
    'जिसके': 'jiske',
    'जिसे': 'jise',
    'कौन': 'kaun',
    'किस': 'kis',
    'किसका': 'kiska',
    'किसकी': 'kiski',
    'किसके': 'kiske',
    'किसे': 'kise',
    'क्या': 'kya',
    'कुछ': 'kuch',
    'कोई': 'koi',
    'किसी': 'kisi',
    'सब': 'sab',
    'सभी': 'sabhi',
    'खुद': 'khud',
    'स्वयं': 'svayam',
    'अपने': 'apne',
    'अपना': 'apna',
    'अपनी': 'apni',

    // Articles / particles / postpositions
    'एक': 'ek',
    'यहाँ': 'yahaan',
    'यहां': 'yahaan',
    'वहाँ': 'wahaan',
    'वहां': 'wahaan',
    'में': 'mein',
    'पर': 'par',
    'पे': 'pe',
    'से': 'se',
    'तक': 'tak',
    'के': 'ke',
    'का': 'ka',
    'की': 'ki',
    'को': 'ko',
    'ने': 'ne',
    'लिए': 'liye',
    'साथ': 'saath',
    'बारे': 'baare',
    'बाद': 'baad',
    'पहले': 'pehle',
    'बीच': 'beech',
    'ऊपर': 'upar',
    'नीचे': 'neeche',
    'पास': 'paas',
    'अंदर': 'andar',
    'बाहर': 'baahar',

    // Conjunctions
    'और': 'aur',
    'या': 'ya',
    'लेकिन': 'lekin',
    'मगर': 'magar',
    'क्योंकि': 'kyunki',
    'क्यूंकि': 'kyunki',
    'इसलिए': 'isliye',
    'अगर': 'agar',
    'यदि': 'yadi',
    'तो': 'to',
    'जब': 'jab',
    'तब': 'tab',
    'जबकि': 'jabki',
    'हालांकि': 'haalaanki',
    'कि': 'ki',
    'ताकि': 'taaki',
    'वरना': 'warna',
    'बल्कि': 'balki',

    // Question words
    'क्यों': 'kyun',
    'कब': 'kab',
    'कहाँ': 'kahaan',
    'कहां': 'kahaan',
    'कैसे': 'kaise',
    'कितना': 'kitna',
    'कितनी': 'kitni',
    'कितने': 'kitne',
    'कौनसा': 'kaunsa',
    'कौनसी': 'kaunsi',
    'कौनसे': 'kaunse',

    // Auxiliary verbs
    'हूँ': 'hoon',
    'हूं': 'hoon',
    'है': 'hai',
    'हैं': 'hain',
    'हो': 'ho',
    'था': 'tha',
    'थी': 'thi',
    'थे': 'the',
    'थीं': 'theen',
    'होगा': 'hoga',
    'होगी': 'hogi',
    'होंगे': 'honge',
    'होगे': 'hoge',
    'होता': 'hota',
    'होती': 'hoti',
    'होते': 'hote',
    'होतीं': 'hoteen',
    'रहा': 'raha',
    'रही': 'rahi',
    'रहे': 'rahe',
    'रहीं': 'raheen',
    'रहना': 'rehna',
    'रहता': 'rehta',
    'रहती': 'rehti',
    'रहते': 'rehte',
    'गया': 'gaya',
    'गई': 'gayi',
    'गए': 'gaye',
    'गयी': 'gayi',
    'आया': 'aaya',
    'आई': 'aayi',
    'आए': 'aaye',
    'आना': 'aana',
    'जाना': 'jaana',
    'जाता': 'jaata',
    'जाती': 'jaati',
    'जाते': 'jaate',
    'जाएगा': 'jaayega',
    'जाएगी': 'jaayegi',
    'जाएंगे': 'jaayenge',
    'जाए': 'jaaye',
    'चाहिए': 'chahiye',
    'सकता': 'sakta',
    'सकती': 'sakti',
    'सकते': 'sakte',
    'सकना': 'sakna',
    'पड़ा': 'pada',
    'पड़ी': 'padi',
    'पड़े': 'pade',

    // Common verbs
    'करना': 'karna',
    'करता': 'karta',
    'करती': 'karti',
    'करते': 'karte',
    'करें': 'karein',
    'करेंगे': 'karenge',
    'किया': 'kiya',
    'किए': 'kiye',
    'कर': 'kar',
    'होना': 'hona',
    'हुआ': 'hua',
    'हुई': 'hui',
    'हुए': 'hue',
    'देना': 'dena',
    'देता': 'deta',
    'देती': 'deti',
    'देते': 'dete',
    'दिया': 'diya',
    'दिए': 'diye',
    'लेना': 'lena',
    'लेता': 'leta',
    'लेती': 'leti',
    'लेते': 'lete',
    'लिया': 'liya',
    'देखना': 'dekhna',
    'देखता': 'dekhta',
    'देखती': 'dekhti',
    'देखते': 'dekhte',
    'देखा': 'dekha',
    'देखी': 'dekhi',
    'बोलना': 'bolna',
    'बोलता': 'bolta',
    'बोलती': 'bolti',
    'बोलते': 'bolte',
    'बोला': 'bola',
    'बोली': 'boli',
    'कहना': 'kehna',
    'कहता': 'kehta',
    'कहती': 'kehti',
    'कहते': 'kehte',
    'कहा': 'kaha',
    'सुना': 'suna',
    'सुनना': 'sunna',
    'लिखना': 'likhna',
    'लिखा': 'likha',
    'पढ़ना': 'padhna',
    'पढ़ता': 'padhta',
    'पढ़ती': 'padhti',
    'पढ़ते': 'padhte',
    'पढ़ा': 'padha',
    'समझना': 'samajhna',
    'समझता': 'samajhta',
    'समझती': 'samajhti',
    'समझते': 'samajhte',
    'समझा': 'samjha',
    'सोचना': 'sochna',
    'सोचा': 'socha',
    'पूछना': 'poochhna',
    'पूछा': 'poocha',
    'बताना': 'bataana',
    'बताया': 'bataaya',
    'मिलना': 'milna',
    'मिला': 'mila',
    'मिली': 'mili',
    'मिले': 'mile',
    'रोकना': 'rokna',
    'रुका': 'ruka',
    'शुरू': 'shuru',
    'खत्म': 'khatm',
    'जीतना': 'jeetna',
    'जीता': 'jeeta',
    'हारना': 'haarna',
    'हारा': 'haara',

    // People
    'आदमी': 'aadmi',
    'महिला': 'mahila',
    'महिलाएं': 'mahilaayein',
    'महिलाएँ': 'mahilaayein',
    'पुरुष': 'purush',
    'लड़का': 'ladka',
    'लड़की': 'ladki',
    'बच्चा': 'bachcha',
    'बच्चे': 'bachche',
    'बच्चों': 'bachchon',
    'परिवार': 'parivaar',
    'लोग': 'log',
    'व्यक्ति': 'vyakti',
    'नागरिक': 'naagrik',
    'युवा': 'yuva',
    'किसान': 'kisaan',
    'मजदूर': 'mazdoor',
    'छात्र': 'chhaatr',
    'शिक्षक': 'shikshak',
    'डॉक्टर': 'doctor',
    'पुलिस': 'police',
    'अधिकारी': 'adhikaari',
    'नेता': 'neta',

    // Government / politics
    'भारत': 'Bharat',
    'भारतीय': 'Bhaaratiya',
    'प्रधानमंत्री': 'Pradhaan Mantri',
    'मुख्यमंत्री': 'Mukhyamantri',
    'सरकार': 'sarkaar',
    'सरकारी': 'sarkaari',
    'मंत्रालय': 'mantraalay',
    'मंत्री': 'mantri',
    'संसद': 'sansad',
    'सांसद': 'saansad',
    'विधानसभा': 'vidhaansabha',
    'चुनाव': 'chunaav',
    'मतदान': 'matdaan',
    'वोट': 'vote',
    'राजनीति': 'raajneeti',
    'राजनीतिक': 'raajneetik',
    'पार्टी': 'party',
    'राष्ट्रपति': 'Raashtrapati',
    'उपराष्ट्रपति': 'Upraashtrapati',
    'केंद्र': 'kendra',
    'राज्य': 'raajya',
    'जिला': 'zila',
    'शहर': 'shahar',
    'गांव': 'gaanv',
    'गाँव': 'gaanv',

    // News
    'समाचार': 'samaachaar',
    'खबर': 'khabar',
    'खबरें': 'khabrein',
    'खबरों': 'khabron',
    'रिपोर्ट': 'report',
    'रिपोर्टर': 'reporter',
    'जानकारी': 'jaankaari',
    'घटना': 'ghatna',
    'घटनाएं': 'ghatnaayein',
    'घटनाएँ': 'ghatnaayein',
    'मामला': 'maamla',
    'मामले': 'maamle',
    'बयान': 'bayan',
    'घोषणा': 'ghoshna',
    'फैसला': 'faisla',
    'निर्णय': 'nirnay',
    'कार्रवाई': 'kaarravaai',
    'जांच': 'jaanch',
    'जाँच': 'jaanch',
    'आरोप': 'aarop',
    'आरोपी': 'aaropi',
    'सबूत': 'saboot',
    'साक्ष्य': 'saakshya',

    // Time
    'आज': 'aaj',
    'कल': 'kal',
    'परसों': 'parson',
    'अभी': 'abhi',
    'अब': 'ab',
    'सुबह': 'subah',
    'दोपहर': 'dopahar',
    'शाम': 'shaam',
    'रात': 'raat',
    'दिन': 'din',
    'हफ्ता': 'hafta',
    'हफ्ते': 'hafte',
    'सप्ताह': 'saptaah',
    'महीना': 'maheena',
    'महीने': 'maheene',
    'साल': 'saal',
    'वर्ष': 'varsh',
    'समय': 'samay',

    // Places
    'देश': 'desh',
    'दुनिया': 'duniya',
    'विश्व': 'vishva',
    'राजधानी': 'raajdhaani',
    'क्षेत्र': 'kshetra',
    'इलाका': 'ilaaka',
    'सड़क': 'sadak',
    'सड़कें': 'sadkein',
    'बाजार': 'bazaar',
    'बाज़ार': 'bazaar',
    'स्कूल': 'school',
    'कॉलेज': 'college',
    'विश्वविद्यालय': 'vishwavidyaalay',
    'अस्पताल': 'aspataal',
    'घर': 'ghar',
    'कार्यालय': 'kaaryaalay',

    // Food / everyday
    'पानी': 'paani',
    'खाना': 'khaana',
    'दूध': 'doodh',
    'चाय': 'chaay',
    'रोटी': 'roti',
    'सब्जी': 'sabzi',
    'फल': 'phal',

    // Adjectives
    'अच्छा': 'achha',
    'अच्छी': 'achhi',
    'अच्छे': 'achhe',
    'बुरा': 'bura',
    'बुरी': 'buri',
    'बुरे': 'bure',
    'बड़ा': 'bada',
    'बड़ी': 'badi',
    'बड़े': 'bade',
    'छोटा': 'chhota',
    'छोटी': 'chhoti',
    'छोटे': 'chhote',
    'नया': 'naya',
    'नई': 'nayi',
    'नए': 'naye',
    'पुराना': 'puraana',
    'पुरानी': 'puraani',
    'पुराने': 'puraane',
    'मुख्य': 'mukhya',
    'महत्वपूर्ण': 'mahatvapurn',
    'जरूरी': 'zaroori',
    'ज़रूरी': 'zaroori',
    'साफ': 'saaf',
    'स्पष्ट': 'spasht',
    'सही': 'sahi',
    'गलत': 'galat',
    'तेज': 'tez',
    'तेज़': 'tez',
    'धीरे': 'dheere',

    // Feelings / states
    'खुश': 'khush',
    'दुखी': 'dukhi',
    'परेशान': 'pareshaan',
    'चिंतित': 'chintit',
    'डरा': 'dara',
    'डर': 'dar',
    'उम्मीद': 'ummeed',
    'विश्वास': 'vishvaas',
    'सवाल': 'sawaal',
    'जवाब': 'javaab',

    // Numbers
    'शून्य': 'shoonya',
    'दो': 'do',
    'तीन': 'teen',
    'चार': 'chaar',
    'पाँच': 'paanch',
    'पांच': 'paanch',
    'छह': 'chhah',
    'छः': 'chhah',
    'सात': 'saat',
    'आठ': 'aath',
    'नौ': 'nau',
    'दस': 'das',
    'ग्यारह': 'gyaarah',
    'बारह': 'baarah',
    'तेरह': 'terah',
    'चौदह': 'chaudah',
    'पंद्रह': 'pandrah',
    'सोलह': 'solah',
    'सत्रह': 'satrah',
    'अठारह': 'athaarah',
    'उन्नीस': 'unnees',
    'बीस': 'bees',
    'इक्कीस': 'ikkees',
    'बाईस': 'baais',
    'तेईस': 'teis',
    'चौबीस': 'chaubees',
    'पच्चीस': 'pachchees',
    'छब्बीस': 'chhabbees',
    'सत्ताईस': 'sattaais',
    'अट्ठाईस': 'atthaais',
    'उनतीस': 'untees',
    'तीस': 'tees',
    'चालीस': 'chaalees',
    'पचास': 'pachaas',
    'साठ': 'saath',
    'सत्तर': 'sattar',
    'अस्सी': 'assi',
    'नब्बे': 'nabbe',
    'सौ': 'sau',
    'हजार': 'hazaar',
    'हज़ार': 'hazaar',
    'लाख': 'laakh',
    'करोड़': 'crore',
    'करोड़': 'crore',

    // Connectors / emphasis
    'भी': 'bhi',
    'ही': 'hi',
    'बहुत': 'bahut',
    'कम': 'kam',
    'ज्यादा': 'zyaada',
    'ज़्यादा': 'zyaada',
    'लगभग': 'lagbhag',
    'सिर्फ': 'sirf',
    'सिर्फ़': 'sirf',
    'केवल': 'keval',
    'फिर': 'phir',
    'फिर से': 'phir se',
    'लगातार': 'lagaataar',
    'अक्सर': 'aksar',
    'हमेशा': 'hamesha',
    'कभी': 'kabhi',
    'कभी-कभी': 'kabhi-kabhi',
    'शायद': 'shaayad',
    'जरूर': 'zaroor',
    'ज़रूर': 'zaroor',
  };

  // ---------------------------------------------------------------------------
  // DEVANAGARI CHARACTER TRANSLITERATION
  // ---------------------------------------------------------------------------

  static const Map<String, String> _independentVowels = {
    'अ': 'a',
    'आ': 'aa',
    'इ': 'i',
    'ई': 'ee',
    'उ': 'u',
    'ऊ': 'oo',
    'ऋ': 'ri',
    'ए': 'e',
    'ऐ': 'ai',
    'ओ': 'o',
    'औ': 'au',
  };

  static const Map<String, String> _consonants = {
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

    // Nukta consonants
    'क़': 'q',
    'ख़': 'kh',
    'ग़': 'gh',
    'ज़': 'z',
    'ड़': 'r',
    'ढ़': 'rh',
    'फ़': 'f',
    'य़': 'y',
  };

  static const Map<String, String> _matras = {
    'ा': 'aa',
    'ि': 'i',
    'ी': 'ee',
    'ु': 'u',
    'ू': 'oo',
    'ृ': 'ri',
    'े': 'e',
    'ै': 'ai',
    'ो': 'o',
    'ौ': 'au',
  };

  static const Map<String, String> _digits = {
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

  // ---------------------------------------------------------------------------
  // CHARACTER HELPERS
  // ---------------------------------------------------------------------------

  static bool _isDevanagari(String char) {
    if (char.isEmpty) return false;

    final code = char.codeUnitAt(0);

    return code >= 0x0900 && code <= 0x097F;
  }

  static bool _isConsonant(String char) {
    return _consonants.containsKey(char);
  }

  static bool _isIndependentVowel(String char) {
    return _independentVowels.containsKey(char);
  }

  static bool _isMatra(String char) {
    return _matras.containsKey(char);
  }

  // ---------------------------------------------------------------------------
  // SMART DEVANAGARI → ROMAN TRANSLITERATION
  // ---------------------------------------------------------------------------

  static String _transliterateWord(String word) {
    if (word.isEmpty) return word;

    // First use high-quality common-word dictionary.
    final direct = _commonWords[word];
    if (direct != null) return direct;

    final chars = word.split('');
    final output = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];

      // Independent vowel
      if (_isIndependentVowel(char)) {
        output.write(_independentVowels[char]);
        continue;
      }

      // Consonant
      if (_isConsonant(char)) {
        final base = _consonants[char]!;

        // Look ahead for matra / halant.
        if (i + 1 < chars.length) {
          final next = chars[i + 1];

          // Halant means no inherent vowel.
          if (next == '्') {
            output.write(base);
            i++;
            continue;
          }

          // Explicit matra.
          if (_isMatra(next)) {
            output.write(base);
            output.write(_matras[next]);
            i++;
            continue;
          }

          // Nukta may occur after a consonant.
          if (next == '़') {
            output.write(base);
            i++;
            continue;
          }
        }

        // Hindi consonants normally carry an inherent "a".
        output.write(base);
        output.write('a');
        continue;
      }

      // Anusvara.
      if (char == 'ं') {
        output.write('n');
        continue;
      }

      // Chandrabindu.
      if (char == 'ँ') {
        output.write('n');
        continue;
      }

      // Visarga.
      if (char == 'ः') {
        output.write('h');
        continue;
      }

      // Avagraha.
      if (char == 'ऽ') {
        output.write('');
        continue;
      }

      // Halant by itself.
      if (char == '्') {
        continue;
      }

      // Devanagari digits.
      if (_digits.containsKey(char)) {
        output.write(_digits[char]);
        continue;
      }

      // Punctuation.
      if (char == '।' || char == '॥') {
        output.write('.');
        continue;
      }

      output.write(char);
    }

    return _cleanRomanWord(output.toString());
  }

  // ---------------------------------------------------------------------------
  // ROMAN OUTPUT CLEANUP
  // ---------------------------------------------------------------------------

  static String _cleanRomanWord(String word) {
    var result = word;

    // Remove accidental double vowels produced by inherent-a handling.
    result = result.replaceAll('aaa', 'aa');
    result = result.replaceAll('eeee', 'ee');
    result = result.replaceAll('oooo', 'oo');

    // Common phonetic corrections.
    result = result.replaceAll('chhh', 'chh');
    result = result.replaceAll('khh', 'kh');
    result = result.replaceAll('ghh', 'gh');
    result = result.replaceAll('thh', 'th');
    result = result.replaceAll('dhh', 'dh');
    result = result.replaceAll('bhh', 'bh');

    return result;
  }

  // ---------------------------------------------------------------------------
  // TOKENIZATION
  // ---------------------------------------------------------------------------

  static String _transliterateText(String text) {
    if (text.trim().isEmpty) return text;

    final buffer = StringBuffer();

    // Keep whitespace and punctuation intact.
    final regex = RegExp(
      r'[\u0900-\u097F]+|[A-Za-z]+|\d+(?:[.,]\d+)*|[^\w\s]+|\s+',
      unicode: true,
    );

    final matches = regex.allMatches(text);

    for (final match in matches) {
      final token = match.group(0)!;

      if (token.trim().isEmpty) {
        buffer.write(token);
        continue;
      }

      if (_containsDevanagari(token)) {
        buffer.write(_transliteratePhrase(token));
      } else {
        buffer.write(token);
      }
    }

    return _cleanupText(buffer.toString());
  }

  static bool _containsDevanagari(String text) {
    for (final char in text.split('')) {
      if (_isDevanagari(char)) return true;
    }

    return false;
  }

  static String _transliteratePhrase(String phrase) {
    // Direct full phrase lookup.
    final direct = _commonWords[phrase];
    if (direct != null) return direct;

    final words = phrase.split(RegExp(r'(?=[।,.!?;:])|(?<=[।,.!?;:])'));

    final result = StringBuffer();

    for (final part in words) {
      if (part.trim().isEmpty) continue;

      final directWord = _commonWords[part];

      if (directWord != null) {
        result.write(directWord);
      } else if (_containsDevanagari(part)) {
        result.write(_transliterateWord(part));
      } else {
        result.write(part);
      }
    }

    return result.toString();
  }

  static String _cleanupText(String text) {
    var result = text;

    // Hindi punctuation.
    result = result.replaceAll('।', '.');
    result = result.replaceAll('॥', '.');

    // Remove unnecessary spaces before punctuation.
    result = result.replaceAllMapped(
      RegExp(r'\s+([,.!?;:%])'),
      (match) => match.group(1)!,
    );

    // Normalize repeated spaces.
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Normalize excessive blank lines.
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result.trim();
  }

  // ---------------------------------------------------------------------------
  // PUBLIC HINGLISH API
  // ---------------------------------------------------------------------------

  /// Converts Hindi/Devanagari text into Romanized Hinglish.
  ///
  /// Examples:
  ///
  /// भारत → Bharat
  /// प्रधानमंत्री → Pradhaan Mantri
  /// आज भारत में चुनाव हैं → Aaj Bharat mein chunaav hain
  /// मुझे यह खबर अच्छी लगी → mujhe yeh khabar achhi lagi
  static String toHinglish(String text) {
    if (text.trim().isEmpty) return text;

    return _transliterateText(text);
  }

  // ---------------------------------------------------------------------------
  // ARTICLE TRANSLATION
  // ---------------------------------------------------------------------------

  /// Translates title, description and body into the requested language.
  static Future<Map<String, String>> translateArticle({
    required String title,
    required String description,
    required String body,
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'English' ||
        !languageCodes.containsKey(targetLanguage)) {
      return {
        'title': title,
        'description': description,
        'body': body,
      };
    }

    final code = languageCodes[targetLanguage] ?? 'en';
    final isHinglish = targetLanguage == 'Hinglish';

    try {
      final results = await Future.wait([
        _translator.translate(title, to: code),
        _translator.translate(description, to: code),
        _translator.translate(body, to: code),
      ]);

      var translatedTitle = results[0].text;
      var translatedDescription = results[1].text;
      var translatedBody = results[2].text;

      if (isHinglish) {
        translatedTitle = toHinglish(translatedTitle);
        translatedDescription = toHinglish(translatedDescription);
        translatedBody = toHinglish(translatedBody);
      }

      return {
        'title': translatedTitle,
        'description': translatedDescription,
        'body': translatedBody,
      };
    } catch (_) {
      // If translation fails, return the original article
      // instead of crashing the news screen.
      return {
        'title': title,
        'description': description,
        'body': body,
      };
    }
  }
}