// lib/data/telangana_location_data.dart

import 'location_data.dart';

const LocationState telanganaLocationState = LocationState(
  name: 'Telangana',
  districts: [
    // ==========================================================
    // 01. ADILABAD
    // ==========================================================
    LocationDistrict(
      name: 'Adilabad',
      cities: [
        // Add cities here.
        //
        // LocationCity(
        //   name: 'Adilabad',
        //   mandals: [
        //     LocationMandal(
        //       name: 'Adilabad',
        //       villages: [
        //         'Village 1',
        //         'Village 2',
        //       ],
        //     ),
        //   ],
        // ),
      ],
      mandals: [
        // Add district-level mandals here.
      ],
    ),

    // ==========================================================
    // 02. BHADRADRI KOTHAGUDEM
    // ==========================================================
    LocationDistrict(name: 'Bhadradri Kothagudem', cities: [], mandals: []),

    // ==========================================================
    // 03. HANUMAKONDA
    // ==========================================================
    LocationDistrict(name: 'Hanumakonda', cities: [], mandals: []),

    // ==========================================================
    // 04. HYDERABAD
    // ==========================================================
    //
    // Hyderabad is officially a city-district.
    // The official Hyderabad District administration lists
    // 16 revenue mandals and 67 revenue villages.
    //
    // The City layer remains available because the app's
    // user-facing hierarchy distinguishes city from district.
    //
    // ==========================================================
    LocationDistrict(
      name: 'Hyderabad',
      cities: [
        LocationCity(
          name: 'Hyderabad',
          mandals: [
            LocationMandal(
              name: 'Amberpet',
              villages: [
                'Amberpet',
                'Drainage Lingampally',
                'Amberpet Sarfekhas',
                'Malakpet',
              ],
            ),

            LocationMandal(
              name: 'Himayatnagar',
              villages: [
                'Bagh Lingampally',
                'Gaganmahal',
                'Daira',
                'Hasanaliguda',
              ],
            ),

            LocationMandal(
              name: 'Nampally',
              villages: ['Nampally', 'Totaguda'],
            ),

            LocationMandal(
              name: 'Asifnagar',
              villages: [
                'Asif Nagar',
                'Mallepalli',
                'Guddimaklapur',
                'Kulsumpura',
                'Razdarkhanpet',
              ],
            ),

            LocationMandal(
              name: 'Saidabad',
              villages: [
                'Saidhabad',
                'Madannapet',
                'Teegalguda',
                'Moosarambagh',
                'Gaddiannaram',
              ],
            ),

            LocationMandal(
              name: 'Bahadurpura',
              villages: [
                'Bahadurpura',
                'Meersagar',
                'Nandi-Muslaiguda',
                'Bondilguda',
                'Charmahal (Abadi Shar-E-Hyderabad)',
                'Zeregumbad',
              ],
            ),

            LocationMandal(
              name: 'Bandlaguda',
              villages: [
                'Bandlaguda (Kalsa)',
                'Sultan Bagh',
                'Nawabsahebkunta',
                'Amjadudduowla',
                'ALI SAMUNDER',
                'Kandikal',
                'Kanchanbagh',
              ],
            ),

            LocationMandal(
              name: 'Golconda',
              villages: ['Langer House', 'Qila Mohd. Nagar', 'Ibrahiam Bagh'],
            ),

            LocationMandal(
              name: 'Charminar',
              villages: ['Kaiwanja', 'Talabchanchalam', 'Murad Mahal'],
            ),

            LocationMandal(
              name: 'Ameerpet',
              villages: ['Ameerpet', 'Bahlookhanguda', 'Somajiguda'],
            ),

            LocationMandal(
              name: 'Tirumalagiri',
              villages: [
                'Tirumalagiri',
                'Ammuguda',
                'Machabolaram',
                'Bowenpally',
                'Kakaguda',
                'Chandulal Bowli',
                'Sitarampur',
                'Thokatta',
              ],
            ),

            LocationMandal(
              name: 'Maredpally',
              villages: [
                'Maredpally (Sarfekhas)',
                'Marredpally (Paigah)',
                'Lalaguda',
                'Malkajgiri (Cantonment)',
              ],
            ),

            LocationMandal(
              name: 'Shaikpet',
              villages: ['Shaikpet', 'Hakeempet', 'Bakhtawarguda'],
            ),

            LocationMandal(
              name: 'Khairatabad',
              villages: ['Yellareddyguda', 'Khairtabad', 'Yousufguda'],
            ),

            LocationMandal(
              name: 'Secunderabad',
              villages: ['Bholakpur', 'Rasoolpura'],
            ),

            LocationMandal(
              name: 'Musheerabad',
              villages: ['Musheerabad', 'Bakaram', 'Zamistanpur', 'Miyakunta'],
            ),
          ],
        ),
      ],
    ),

    // ==========================================================
    // 05. JAGTIAL
    // ==========================================================
    LocationDistrict(name: 'Jagtial', cities: [], mandals: []),

    // ==========================================================
    // 06. JANGAON
    // ==========================================================
    LocationDistrict(name: 'Jangaon', cities: [], mandals: []),

    // ==========================================================
    // 07. JAYASHANKAR BHUPALPALLY
    // ==========================================================
    LocationDistrict(name: 'Jayashankar Bhupalpally', cities: [], mandals: []),

    // ==========================================================
    // 08. JOGULAMBA GADWAL
    // ==========================================================
    LocationDistrict(name: 'Jogulamba Gadwal', cities: [], mandals: []),

    // ==========================================================
    // 09. KAMAREDDY
    // ==========================================================
    LocationDistrict(name: 'Kamareddy', cities: [], mandals: []),

    // ==========================================================
    // 10. KARIMNAGAR
    // ==========================================================
    LocationDistrict(name: 'Karimnagar', cities: [], mandals: []),

    // ==========================================================
    // 11. KHAMMAM
    // ==========================================================
    LocationDistrict(name: 'Khammam', cities: [], mandals: []),

    // ==========================================================
    // 12. KUMURAM BHEEM
    // ==========================================================
    LocationDistrict(name: 'Kumuram Bheem', cities: [], mandals: []),

    // ==========================================================
    // 13. MAHABUBABAD
    // ==========================================================
    LocationDistrict(name: 'Mahabubabad', cities: [], mandals: []),

    // ==========================================================
    // 14. MAHABUBNAGAR
    // ==========================================================
    LocationDistrict(name: 'Mahabubnagar', cities: [], mandals: []),

    // ==========================================================
    // 15. MANCHERIAL
    // ==========================================================
    LocationDistrict(name: 'Mancherial', cities: [], mandals: []),

    // ==========================================================
    // 16. MEDAK
    // ==========================================================
    LocationDistrict(name: 'Medak', cities: [], mandals: []),

    // ==========================================================
    // 17. MEDCHAL-MALKAJGIRI
    // ==========================================================
    LocationDistrict(name: 'Medchal-Malkajgiri', cities: [], mandals: []),

    // ==========================================================
    // 18. MULUGU
    // ==========================================================
    LocationDistrict(name: 'Mulugu', cities: [], mandals: []),

    // ==========================================================
    // 19. NAGARKURNOOL
    // ==========================================================
    LocationDistrict(name: 'Nagarkurnool', cities: [], mandals: []),

    // ==========================================================
    // 20. NALGONDA
    // ==========================================================
    LocationDistrict(name: 'Nalgonda', cities: [], mandals: []),

    // ==========================================================
    // 21. NARAYANPET
    // ==========================================================
    LocationDistrict(name: 'Narayanpet', cities: [], mandals: []),

    // ==========================================================
    // 22. NIRMAL
    // ==========================================================
    LocationDistrict(name: 'Nirmal', cities: [], mandals: []),

    // ==========================================================
    // 23. NIZAMABAD
    // ==========================================================
    LocationDistrict(name: 'Nizamabad', cities: [], mandals: []),

    // ==========================================================
    // 24. PEDDAPALLI
    // ==========================================================
    LocationDistrict(name: 'Peddapalli', cities: [], mandals: []),

    // ==========================================================
    // 25. RAJANNA SIRCILLA
    // ==========================================================
    LocationDistrict(name: 'Rajanna Sircilla', cities: [], mandals: []),

    // ==========================================================
    // 26. RANGAREDDY
    // ==========================================================
    LocationDistrict(
      name: 'Rangareddy',
      cities: [
        // Example:
        //
        // LocationCity(
        //   name: 'Shamshabad',
        //   mandals: [
        //     LocationMandal(
        //       name: 'Shamshabad',
        //       villages: [
        //         'Village 1',
        //         'Village 2',
        //       ],
        //     ),
        //   ],
        // ),
        //
        // Add the official municipality/city hierarchy here.
      ],
      mandals: [
        // Add official Ranga Reddy mandals here.
      ],
    ),

    // ==========================================================
    // 27. SANGAREDDY
    // ==========================================================
    LocationDistrict(name: 'Sangareddy', cities: [], mandals: []),

    // ==========================================================
    // 28. SIDDIPET
    // ==========================================================
    LocationDistrict(name: 'Siddipet', cities: [], mandals: []),

    // ==========================================================
    // 29. SURYAPET
    // ==========================================================
    LocationDistrict(name: 'Suryapet', cities: [], mandals: []),

    // ==========================================================
    // 30. VIKARABAD
    // ==========================================================
    LocationDistrict(name: 'Vikarabad', cities: [], mandals: []),

    // ==========================================================
    // 31. WANAPARTHY
    // ==========================================================
    LocationDistrict(name: 'Wanaparthy', cities: [], mandals: []),

    // ==========================================================
    // 32. WARANGAL
    // ==========================================================
    LocationDistrict(name: 'Warangal', cities: [], mandals: []),

    // ==========================================================
    // 33. YADADRI BHUVANAGIRI
    // ==========================================================
    LocationDistrict(name: 'Yadadri Bhuvanagiri', cities: [], mandals: []),
  ],
);