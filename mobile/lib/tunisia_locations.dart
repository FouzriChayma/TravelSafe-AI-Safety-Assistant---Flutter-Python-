// Tunisia major cities and locations with coordinates
class TunisiaLocation {
  final String name;
  final double latitude;
  final double longitude;

  const TunisiaLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class TunisiaLocations {
  static const List<TunisiaLocation> cities = [
    TunisiaLocation(name: 'Tunis', latitude: 36.8065, longitude: 10.1815),
    TunisiaLocation(name: 'Sfax', latitude: 34.7406, longitude: 10.7603),
    TunisiaLocation(name: 'Sousse', latitude: 35.8254, longitude: 10.6360),
    TunisiaLocation(name: 'Kairouan', latitude: 35.6781, longitude: 10.0963),
    TunisiaLocation(name: 'Bizerte', latitude: 37.2744, longitude: 9.8739),
    TunisiaLocation(name: 'Gabès', latitude: 33.8815, longitude: 10.0982),
    TunisiaLocation(name: 'Ariana', latitude: 36.8601, longitude: 10.1934),
    TunisiaLocation(name: 'Ben Arous', latitude: 36.7531, longitude: 10.2189),
    TunisiaLocation(name: 'Monastir', latitude: 35.7780, longitude: 10.8262),
    TunisiaLocation(name: 'Gafsa', latitude: 34.4250, longitude: 8.7842),
    TunisiaLocation(name: 'Tozeur', latitude: 33.9197, longitude: 8.1335),
    TunisiaLocation(name: 'Djerba', latitude: 33.8078, longitude: 10.8451),
    TunisiaLocation(name: 'Hammamet', latitude: 36.4000, longitude: 10.6167),
    TunisiaLocation(name: 'Nabeul', latitude: 36.4561, longitude: 10.7376),
    TunisiaLocation(name: 'Mahdia', latitude: 35.5047, longitude: 11.0622),
  ];

  static TunisiaLocation? findByName(String name) {
    final searchName = name.toLowerCase().trim();
    return cities.firstWhere(
      (city) => city.name.toLowerCase().contains(searchName),
      orElse: () => const TunisiaLocation(name: '', latitude: 0, longitude: 0),
    );
  }
}

