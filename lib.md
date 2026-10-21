lib/

│

├── data/

│   ├── demo\_news.dart

│   └── location\_data.dart

│

├── models/

│   └── news\_article.dart

│

├── screens/

│   ├── home/

│   │     ├── onboarding/

│   │     │       ├── district\_selection\_screen.dart

│   │     │       ├── email\_login\_screen.dart

│   │     │       ├── google\_login\_screen.dart

│   │     │       ├── language\_selection\_screen.dart
│   │     │       ├── mobile\_login\_screen.dart

│   │     │       ├── region\_selection\_screen.dart

│   │     │       └── welcome\_screen.dart

│   │     │

│   │     ├── news\_home\_screen.dart

│   │     └── news\_story\_page.dart

│   │

│   ├── category/

│   │     └── category\_screen.dart

│   │

│   ├── location/

│   │     └── location\_screen.dart

│   │

│   ├── saved/

│   │     └── saved\_screen.dart

│   │

│   ├── search/

│   │     └── search\_screen.dart

│   │

│   └── main/

│        └── main\_shell.dart

│   

├── services/

│   ├── app\_strings.dart

│   ├── auth\_service.dart

│   ├── location\_service.dart

│   ├── place\_translations.dart

│   ├── saved\_news\_store.dart

│   ├── session\_prefs.dart

│   ├── supabase\_config.dart

│   └── translation\_service.dart

│   

├── widgets/

│     └── home/

│          ├── breaking\_news\_section.dart

│          ├── featured\_news\_card.dart

│          ├── glass\_header.dart

│          ├── news\_bottom\_navigation.dart

│          ├── news\_card.dart

│          └── one\_page\_news\_card.dart

│

└── main.dart   



(Till Here is my files structure with proper names and services I am using currently)

also I have uploaded the current pubspec.yaml

pubspec.yaml 👇

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

name: news\_app

description: "A new Flutter project."

publish\_to: 'none'



version: 1.0.0+1



environment:

&#x20; sdk: ^3.12.2



dependencies:

&#x20; flutter:

&#x20;   sdk: flutter



&#x20; cupertino\_icons: ^1.0.8

&#x20; go\_router: ^17.4.0

&#x20; flutter\_riverpod: ^3.4.2

&#x20; google\_fonts: ^8.2.1

&#x20; cached\_network\_image: ^3.4.1

&#x20; shimmer: ^3.0.0

&#x20; http: ^1.6.0

&#x20; share\_plus: ^13.3.0

&#x20; translator: ^1.0.4+1

&#x20; supabase\_flutter: ^2.0.0

&#x20; shared\_preferences: ^2.3.2

&#x20; image\_picker: ^1.1.2

&#x20; geocoding: ^5.0.0

&#x20; geolocator: ^13.0.0

&#x20; flutter\_map: ^8.1.1

&#x20; latlong2: ^0.9.1



dev\_dependencies:

&#x20; flutter\_test:

&#x20;   sdk: flutter

&#x20; flutter\_lints: ^6.0.0



flutter:

&#x20; uses-material-design: true



&#x20; assets:

&#x20;   # - assets/public/images/watermark/app\_logo.png

&#x20;   - assets/public/images/watermark/watermark\_top\_right.png

&#x20;   - assets/public/images/watermark/watermark\_bottom\_left.png

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

