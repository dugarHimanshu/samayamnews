// Simple static translations for the app's fixed UI text — button
// labels, menu items, headings, etc. Add a new key here any time you
// add new UI text that needs to work in Hindi and Telugu too.
//
// This is separate from TranslationService, which live-translates
// news article content instead of using a fixed dictionary.
class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'home': {'english': 'Home', 'hindi': 'होम', 'telugu': 'హోమ్'},
    'categories': {
      'english': 'Categories',
      'hindi': 'श्रेणियाँ',
      'telugu': 'వర్గాలు',
    },
    'search': {'english': 'Search', 'hindi': 'खोजें', 'telugu': 'శోధించండి'},
    'saved': {
      'english': 'Saved',
      'hindi': 'सेव किया गया',
      'telugu': 'సేవ్ చేయబడింది',
    },
    'dark_mode': {
      'english': 'Dark mode',
      'hindi': 'डार्क मोड',
      'telugu': 'డార్క్ మోడ్',
    },
    'language': {'english': 'Language', 'hindi': 'भाषा', 'telugu': 'భాష'},
    'location': {'english': 'Location', 'hindi': 'स्थान', 'telugu': 'స్థానం'},
    'saved_news': {
      'english': 'Saved news',
      'hindi': 'सेव की गई खबरें',
      'telugu': 'సేవ్ చేసిన వార్తలు',
    },
    'settings': {
      'english': 'Settings',
      'hindi': 'सेटिंग्स',
      'telugu': 'సెట్టింగ్‌లు',
    },
    'your_profile': {
      'english': 'Your Profile',
      'hindi': 'आपकी प्रोफ़ाइल',
      'telugu': 'మీ ప్రొఫైల్',
    },
    'log_out': {
      'english': 'Log out',
      'hindi': 'लॉग आउट',
      'telugu': 'లాగ్ అవుట్',
    },
    // Region selection screen
    'personalize_feed': {
      'english': 'PERSONALIZE YOUR FEED',
      'hindi': 'अपनी फ़ीड को पर्सनलाइज़ करें',
      'telugu': 'మీ ఫీడ్‌ను వ్యక్తిగతీకరించండి',
    },
    'where_are_you': {
      'english': 'Where are you',
      'hindi': 'आप कहाँ से',
      'telugu': 'మీరు ఎక్కడ నుండి',
    },
    'reading_from': {
      'english': 'reading from?',
      'hindi': 'पढ़ रहे हैं?',
      'telugu': 'చదువుతున్నారు?',
    },
    'region_subtitle': {
      'english':
          'Tell us where you are. We\u2019ll quietly shape your news experience around the stories that matter closest to you.',
      'hindi':
          'हमें बताएं कि आप कहाँ हैं। हम आपके नज़दीकी और महत्वपूर्ण समाचारों के अनुसार आपका अनुभव तैयार करेंगे।',
      'telugu':
          'మీరు ఎక్కడ ఉన్నారో మాకు చెప్పండి. మీకు దగ్గరగా ఉన్న ముఖ్యమైన వార్తల ఆధారంగా మేము మీ అనుభవాన్ని రూపొందిస్తాము.',
    },
    'your_region': {
      'english': 'YOUR REGION',
      'hindi': 'आपका क्षेत्र',
      'telugu': 'మీ ప్రాంతం',
    },
    'search_state_hint': {
      'english': 'Search your state...',
      'hindi': 'अपना राज्य खोजें...',
      'telugu': 'మీ రాష్ట్రాన్ని శోధించండి...',
    },
    'no_state_found': {
      'english': 'No state found',
      'hindi': 'कोई राज्य नहीं मिला',
      'telugu': 'రాష్ట్రం కనుగొనబడలేదు',
    },
    'try_another_search': {
      'english': 'Try another search.',
      'hindi': 'दूसरी खोज आज़माएँ।',
      'telugu': 'మరో శోధన ప్రయత్నించండి.',
    },
    'continue': {
      'english': 'Continue',
      'hindi': 'जारी रखें',
      'telugu': 'కొనసాగించండి',
    },
    'selected_for_feed': {
      'english': 'Selected for your feed',
      'hindi': 'आपकी फ़ीड के लिए चुना गया',
      'telugu': 'మీ ఫీడ్ కోసం ఎంచుకోబడింది',
    },
    'tap_to_select': {
      'english': 'Tap to select',
      'hindi': 'चुनने के लिए टैप करें',
      'telugu': 'ఎంచుకోవడానికి నొక్కండి',
    },
    'select_state_first': {
      'english': 'Please select your state first.',
      'hindi': 'कृपया पहले अपना राज्य चुनें।',
      'telugu': 'దయచేసి మొదట మీ రాష్ట్రాన్ని ఎంచుకోండి.',
    },
    'country': {
      'english': 'COUNTRY',
      'hindi': 'देश',
      'telugu': 'దేశం',
    },
    'india':{
      'english':'INDIA',
      'hindi':'भारत',
      'telugu':'భారతదేశం',
    },

    // District selection screen
    'final_step': {
      'english': 'FINAL STEP',
      'hindi': 'अंतिम चरण',
      'telugu': 'చివరి దశ',
    },
    'your_local': {
      'english': 'Your local',
      'hindi': 'आपकी स्थानीय',
      'telugu': 'మీ స్థానిక',
    },
    'news_starts_here': {
      'english': 'news starts here.',
      'hindi': 'खबर यहीं से शुरू होती है।',
      'telugu': 'వార్తలు ఇక్కడ నుండి మొదలవుతాయి.',
    },
    'district_subtitle': {
      'english':
          'Choose your district and make your news feed feel closer to home.',
      'hindi':
          'अपना जिला चुनें और अपनी समाचार फ़ीड को घर के करीब महसूस कराएं।',
      'telugu':
          'మీ జిల్లాను ఎంచుకుని మీ వార్తల ఫీడ్‌ను ఇంటికి దగ్గరగా చేసుకోండి.',
    },
    'your_location': {
      'english': 'YOUR LOCATION',
      'hindi': 'आपका स्थान',
      'telugu': 'మీ స్థానం',
    },
    'select_district': {
      'english': 'SELECT DISTRICT',
      'hindi': 'जिला चुनें',
      'telugu': 'జిల్లాను ఎంచుకోండి',
    },
    'search_district_hint': {
      'english': 'Search your district...',
      'hindi': 'अपना जिला खोजें...',
      'telugu': 'మీ జిల్లాను శోధించండి...',
    },
    'no_districts_available': {
      'english': 'No districts available',
      'hindi': 'कोई जिला उपलब्ध नहीं है',
      'telugu': 'జిల్లాలు అందుబాటులో లేవు',
    },
    'no_district_found': {
      'english': 'No district found',
      'hindi': 'कोई जिला नहीं मिला',
      'telugu': 'జిల్లా కనుగొనబడలేదు',
    },
    'select_district_first': {
      'english': 'Please select your district first.',
      'hindi': 'कृपया पहले अपना जिला चुनें।',
      'telugu': 'దయచేసి మొదట మీ జిల్లాను ఎంచుకోండి.',
    },
    'continue_to_news': {
      'english': 'Continue to News',
      'hindi': 'समाचार पर जारी रखें',
      'telugu': 'వార్తలకు కొనసాగించండి',
    },
    'translating_districts': {
      'english': 'Translating district names...',
      'hindi': 'जिलों के नाम अनुवाद हो रहे हैं...',
      'telugu': 'జిల్లాల పేర్లు అనువదిస్తున్నాయి...',
    },
    'local_news': {
      'english': 'Local News',
      'hindi': 'स्थानीय समाचार',
      'telugu': 'స్థానిక వార్తలు',
    },
    'no_local_news': {
      'english': 'No local news right now — check back soon.',
      'hindi': 'फिलहाल कोई स्थानीय समाचार नहीं — जल्द ही देखें।',
      'telugu': 'ప్రస్తుతం స్థానిక వార్తలు లేవు — త్వరలో మళ్లీ చూడండి.',
    },
    'retry': {
      'english': 'Retry',
      'hindi': 'पुनः प्रयास करें',
      'telugu': 'మళ్లీ ప్రయత్నించండి',
    },
  };

  // Looks up [key] in [languageId] ('english' / 'hindi' / 'telugu').
  // Falls back to English if the key or language is missing, so a
  // gap in translations never crashes the app or shows a blank string.
  static String t(String key, String languageId) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[languageId] ?? entry['english'] ?? key;
  }
}