// lib/data/location_data.dart

import 'andhra_pradesh_location_data.dart';
import 'telangana_location_data.dart';

class LocationMandal {
  final String name;
  final List<String> villages;

  const LocationMandal({
    required this.name,
    this.villages = const [],
  });
}

class LocationCity {
  final String name;
  final List<LocationMandal> mandals;

  const LocationCity({
    required this.name,
    this.mandals = const [],
  });
}

class LocationDistrict {
  final String name;
  final List<LocationCity> cities;
  final List<LocationMandal> mandals;

  const LocationDistrict({
    required this.name,
    this.cities = const [],
    this.mandals = const [],
  });

  /// Mandals that are directly attached to the district.
  ///
  /// In some areas, a city/municipality is useful as another
  /// user-facing selection layer. In other areas, the user can
  /// go directly from District -> Mandal.
  List<String> get mandalNames {
    final values = <String>{};

    for (final mandal in mandals) {
      values.add(mandal.name);
    }

    for (final city in cities) {
      for (final mandal in city.mandals) {
        values.add(mandal.name);
      }
    }

    final result = values.toList()..sort();
    return result;
  }

  List<String> get cityNames {
    final result = cities.map((city) => city.name).toList()
      ..sort();

    return result;
  }

  LocationCity? cityByName(String name) {
    for (final city in cities) {
      if (city.name == name) {
        return city;
      }
    }

    return null;
  }

  LocationMandal? mandalByName(String name) {
    for (final mandal in mandals) {
      if (mandal.name == name) {
        return mandal;
      }
    }

    for (final city in cities) {
      for (final mandal in city.mandals) {
        if (mandal.name == name) {
          return mandal;
        }
      }
    }

    return null;
  }
}

class LocationState {
  final String name;
  final List<LocationDistrict> districts;

  const LocationState({
    required this.name,
    required this.districts,
  });

  List<String> get districtNames {
    final result =
        districts.map((district) => district.name).toList()
          ..sort();

    return result;
  }

  LocationDistrict? districtByName(String name) {
    for (final district in districts) {
      if (district.name == name) {
        return district;
      }
    }

    return null;
  }
}

// ============================================================
// ALL SUPPORTED APP LOCATIONS
// ============================================================

const List<LocationState> appLocationStates = [
  telanganaLocationState,
  andhraPradeshLocationState,
];

// ============================================================
// STATE HELPERS
// ============================================================

LocationState? getLocationState(String stateName) {
  for (final state in appLocationStates) {
    if (state.name == stateName) {
      return state;
    }
  }

  return null;
}

LocationDistrict? getLocationDistrict(
  String stateName,
  String districtName,
) {
  final state = getLocationState(stateName);

  if (state == null) {
    return null;
  }

  return state.districtByName(districtName);
}

List<String> getDistrictsForState(
  String stateName,
) {
  return getLocationState(stateName)?.districtNames ??
      const [];
}

List<String> getCitiesForDistrict(
  String stateName,
  String districtName,
) {
  final district =
      getLocationDistrict(
    stateName,
    districtName,
  );

  return district?.cityNames ?? const [];
}

List<String> getMandalsForDistrict(
  String stateName,
  String districtName, {
  String? city,
}) {
  final district =
      getLocationDistrict(
    stateName,
    districtName,
  );

  if (district == null) {
    return const [];
  }

  if (city != null && city.isNotEmpty) {
    final selectedCity =
        district.cityByName(city);

    if (selectedCity == null) {
      return const [];
    }

    return selectedCity.mandals
        .map((mandal) => mandal.name)
        .toList()
      ..sort();
  }

  return district.mandalNames;
}

List<String> getVillagesForLocation({
  required String state,
  required String district,
  String? city,
  required String mandal,
}) {
  final districtData =
      getLocationDistrict(
    state,
    district,
  );

  if (districtData == null) {
    return const [];
  }

  LocationMandal? selectedMandal;

  if (city != null && city.isNotEmpty) {
    final selectedCity =
        districtData.cityByName(city);

    if (selectedCity == null) {
      return const [];
    }

    for (final item in selectedCity.mandals) {
      if (item.name == mandal) {
        selectedMandal = item;
        break;
      }
    }
  } else {
    selectedMandal =
        districtData.mandalByName(mandal);
  }

  if (selectedMandal == null) {
    return const [];
  }

  final result =
      List<String>.from(
    selectedMandal.villages,
  )..sort();

  return result;
}