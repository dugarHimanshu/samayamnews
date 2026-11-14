// lib/data/location_data.dart
//
// Location helpers used by the screens. The data now comes from the API
// (official LGD codes for Telangana and Andhra Pradesh) through
// LocationRepository; these functions keep the old name-based interface.
//
// Mandals/villages load on demand: the first call for a district returns an
// empty list and triggers a fetch — listen to LocationRepository.instance to
// rebuild when the data arrives.

import '../services/location_repository.dart';

class LocationMandal {
  final String name;
  final List<String> villages;

  const LocationMandal({required this.name, this.villages = const []});
}

class LocationCity {
  final String name;
  final List<LocationMandal> mandals;

  const LocationCity({required this.name, this.mandals = const []});
}

class LocationDistrict {
  final String name;
  final int? id;

  const LocationDistrict({required this.name, this.id});

  // LGD has no separate "city" level between district and mandal.
  List<LocationCity> get cities => const [];
  List<String> get cityNames => const [];
  LocationCity? cityByName(String name) => null;

  List<LocationMandal> get mandals => LocationRepository.instance
      .childrenOf(id)
      .map((m) => LocationMandal(
            name: m.nameEn,
            villages: LocationRepository.instance.childrenOf(m.id).map((v) => v.nameEn).toList(),
          ))
      .toList();

  List<String> get mandalNames => LocationRepository.instance.childrenOf(id).map((m) => m.nameEn).toList();

  LocationMandal? mandalByName(String name) {
    for (final m in mandals) {
      if (m.name == name) return m;
    }
    return null;
  }
}

class LocationState {
  final String name;
  final int? id;

  const LocationState({required this.name, this.id});

  List<LocationDistrict> get districts => LocationRepository.instance
      .childrenOf(id)
      .map((d) => LocationDistrict(name: d.nameEn, id: d.id))
      .toList();

  List<String> get districtNames => LocationRepository.instance.childrenOf(id).map((d) => d.nameEn).toList();

  LocationDistrict? districtByName(String name) {
    final d = LocationRepository.instance.district(this.name, name);
    return d == null ? null : LocationDistrict(name: d.nameEn, id: d.id);
  }
}

List<LocationState> get appLocationStates {
  final states = LocationRepository.instance.states;
  if (states.isEmpty) {
    return const [LocationState(name: 'Telangana'), LocationState(name: 'Andhra Pradesh')];
  }
  // Telangana first, matching the previous ordering.
  final sorted = [...states]..sort((a, b) => a.nameEn == 'Telangana' ? -1 : (b.nameEn == 'Telangana' ? 1 : 0));
  return sorted.map((s) => LocationState(name: s.nameEn, id: s.id)).toList();
}

LocationState? getLocationState(String stateName) {
  final s = LocationRepository.instance.state(stateName);
  return s == null ? null : LocationState(name: s.nameEn, id: s.id);
}

LocationDistrict? getLocationDistrict(String stateName, String districtName) =>
    getLocationState(stateName)?.districtByName(districtName);

List<String> getDistrictsForState(String stateName) => getLocationState(stateName)?.districtNames ?? const [];

List<String> getCitiesForDistrict(String stateName, String districtName) => const [];

List<String> getMandalsForDistrict(String stateName, String districtName, {String? city}) =>
    getLocationDistrict(stateName, districtName)?.mandalNames ?? const [];

List<String> getVillagesForLocation({
  required String state,
  required String district,
  String? city,
  required String mandal,
}) {
  final m = LocationRepository.instance.mandal(state, district, mandal);
  return LocationRepository.instance.childrenOf(m?.id).map((v) => v.nameEn).toList();
}
