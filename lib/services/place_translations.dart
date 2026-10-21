// Hand-checked Hindi/Telugu names for India's states. There are only
// ~28 of these and they're well-known official names, so hardcoding
// them here is both more accurate and instant compared to calling a
// translation API every time a state name needs to be shown.
class PlaceTranslations {
  PlaceTranslations._();

  static const Map<String, Map<String, String>> _stateNames = {
    'Andhra Pradesh': {'hindi': 'आंध्र प्रदेश', 'telugu': 'ఆంధ్ర ప్రదేశ్'},
    // 'Arunachal Pradesh': {'hindi': 'अरुणाचल प्रदेश','telugu': 'అరుణాచల్ ప్రదేశ్',},
    // 'Assam': {'hindi': 'असम', 'telugu': 'అస్సాం'},
    // 'Bihar': {'hindi': 'बिहार', 'telugu': 'బీహార్'},
    // 'Chhattisgarh': {'hindi': 'छत्तीसगढ़', 'telugu': 'ఛత్తీస్‌గఢ్'},
    // 'Goa': {'hindi': 'गोवा', 'telugu': 'గోవా'},
    // 'Gujarat': {'hindi': 'गुजरात', 'telugu': 'గుజరాత్'},
    // 'Haryana': {'hindi': 'हरियाणा', 'telugu': 'హర్యానా'},
    // 'Himachal Pradesh': {'hindi': 'हिमाचल प्रदेश','telugu': 'హిమాచల్ ప్రదేశ్',},
    // 'Jharkhand': {'hindi': 'झारखंड', 'telugu': 'ఝార్ఖండ్'},
    // 'Karnataka': {'hindi': 'कर्नाटक', 'telugu': 'కర్ణాటక'},
    // 'Kerala': {'hindi': 'केरल', 'telugu': 'కేరళ'},
    // 'Madhya Pradesh': {'hindi': 'मध्य प्रदेश', 'telugu': 'మధ్య ప్రదేశ్'},
    // 'Maharashtra': {'hindi': 'महाराष्ट्र', 'telugu': 'మహారాష్ట్ర'},
    // 'Manipur': {'hindi': 'मणिपुर', 'telugu': 'మణిపూర్'},
    // 'Meghalaya': {'hindi': 'मेघालय', 'telugu': 'మేఘాలయ'},
    // 'Mizoram': {'hindi': 'मिज़ोरम', 'telugu': 'మిజోరం'},
    // 'Nagaland': {'hindi': 'नागालैंड', 'telugu': 'నాగాలాండ్'},
    // 'Odisha': {'hindi': 'ओडिशा', 'telugu': 'ఒడిశా'},
    // 'Punjab': {'hindi': 'पंजाब', 'telugu': 'పంజాబ్'},
    // 'Rajasthan': {'hindi': 'राजस्थान', 'telugu': 'రాజస్థాన్'},
    // 'Sikkim': {'hindi': 'सिक्किम', 'telugu': 'సిక్కిం'},
    // 'Tamil Nadu': {'hindi': 'तमिलनाडु', 'telugu': 'తమిళనాడు'},
    'Telangana': {'hindi': 'तेलंगाना', 'telugu': 'తెలంగాణ'},
    // 'Tripura': {'hindi': 'त्रिपुरा', 'telugu': 'త్రిపుర'},
    // 'Uttar Pradesh': {'hindi': 'उत्तर प्रदेश', 'telugu': 'ఉత్తర ప్రదేశ్'},
    // 'Uttarakhand': {'hindi': 'उत्तराखंड', 'telugu': 'ఉత్తరాఖండ్'},
    // 'West Bengal': {'hindi': 'पश्चिम बंगाल', 'telugu': 'పశ్చిమ బెంగాల్'},
  };

  // Returns [englishName] translated to [languageId], or the original
  // English name if there's no entry for it (safe fallback — never
  // shows a blank string).
  static String stateName(String englishName, String languageId) {
    if (languageId == 'english') return englishName;
    return _stateNames[englishName]?[languageId] ?? englishName;
  }
}