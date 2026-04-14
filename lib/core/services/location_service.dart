import 'dart:convert';

class Country {
  final String code;
  final String name;
  final List<City> cities;

  const Country({
    required this.code,
    required this.name,
    required this.cities,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'],
      name: json['name'],
      cities: (json['cities'] as List).map((c) => City.fromJson(c)).toList(),
    );
  }
}

class City {
  final String code;
  final String name;
  final String countryCode;
  final List<Landmark> landmarks;

  const City({
    required this.code,
    required this.name,
    required this.countryCode,
    required this.landmarks,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      code: json['code'],
      name: json['name'],
      countryCode: json['country_code'],
      landmarks: (json['landmarks'] as List).map((l) => Landmark.fromJson(l)).toList(),
    );
  }

  String get display => '$name, ${countryCode.toUpperCase()}';
  String get short => name;
}

class Landmark {
  final String code;
  final String name;
  final String cityCode;

  const Landmark({
    required this.code,
    required this.name,
    required this.cityCode,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      code: json['code'],
      name: json['name'],
      cityCode: json['city_code'],
    );
  }

  String get label => name;
}

class LocationService {
  // Simulated API data
  static const String _mockData = '''
  [
    {
      "code": "BJ",
      "name": "Bénin",
      "cities": [
        {
          "code": "cotonou",
          "name": "Cotonou",
          "country_code": "BJ",
          "landmarks": [
            {"code": "etoile_rouge", "name": "Étoile Rouge", "city_code": "cotonou"},
            {"code": "fidjrosse", "name": "Fidjrossè", "city_code": "cotonou"},
            {"code": "jericho", "name": "Jéricho", "city_code": "cotonou"},
            {"code": "sainte_rita", "name": "Sainte Rita", "city_code": "cotonou"}
          ]
        },
        {
          "code": "porto_novo",
          "name": "Porto-Novo",
          "country_code": "BJ",
          "landmarks": [
            {"code": "centre_ville", "name": "Centre Ville", "city_code": "porto_novo"},
            {"code": "plage", "name": "Plage", "city_code": "porto_novo"}
          ]
        },
        {
          "code": "abomey_calavi",
          "name": "Abomey-Calavi",
          "country_code": "BJ",
          "landmarks": [
            {"code": "universite", "name": "Université", "city_code": "abomey_calavi"},
            {"code": "calavi", "name": "Calavi", "city_code": "abomey_calavi"}
          ]
        },
        {
          "code": "parakou",
          "name": "Parakou",
          "country_code": "BJ",
          "landmarks": [
            {"code": "centre", "name": "Centre", "city_code": "parakou"}
          ]
        }
      ]
    },
    {
      "code": "TG",
      "name": "Togo",
      "cities": [
        {
          "code": "lome",
          "name": "Lomé",
          "country_code": "TG",
          "landmarks": [
            {"code": "plateau", "name": "Plateau", "city_code": "lome"},
            {"code": "tokoin", "name": "Tokoin", "city_code": "lome"}
          ]
        }
      ]
    },
    {
      "code": "CI",
      "name": "Côte d'Ivoire",
      "cities": [
        {
          "code": "abidjan",
          "name": "Abidjan",
          "country_code": "CI",
          "landmarks": [
            {"code": "plateau", "name": "Plateau", "city_code": "abidjan"},
            {"code": "marcory", "name": "Marcory", "city_code": "abidjan"}
          ]
        }
      ]
    },
    {
      "code": "SN",
      "name": "Sénégal",
      "cities": [
        {
          "code": "dakar",
          "name": "Dakar",
          "country_code": "SN",
          "landmarks": [
            {"code": "plateau", "name": "Plateau", "city_code": "dakar"},
            {"code": "yoff", "name": "Yoff", "city_code": "dakar"}
          ]
        }
      ]
    }
  ]
  ''';

  // Simulate API call delay
  Future<List<Country>> getCountries() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final List<dynamic> data = jsonDecode(_mockData);
    return data.map((c) => Country.fromJson(c)).toList();
  }

  Future<List<Landmark>> getLandmarksForCity(String cityCode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final countries = await getCountries();
    for (final country in countries) {
      for (final city in country.cities) {
        if (city.code == cityCode) {
          return city.landmarks;
        }
      }
    }
    return [];
  }
}