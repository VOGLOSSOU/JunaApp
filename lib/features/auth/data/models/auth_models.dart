import '../../domain/entities/user_entity.dart';

class CountryModel {
  final String id;
  final String code;
  final String nameFr;
  final String nameEn;
  final bool isActive;

  const CountryModel({
    required this.id,
    required this.code,
    required this.nameFr,
    required this.nameEn,
    required this.isActive,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
        id: json['id'] as String,
        code: json['code'] as String,
        nameFr: (json['translations']?['fr'] ?? json['code']) as String,
        nameEn: (json['translations']?['en'] ?? json['code']) as String,
        isActive: json['isActive'] as bool? ?? true,
      );

  String get displayName => nameFr;
}

class CityModel {
  final String id;
  final String name;
  final String countryId;
  final bool isActive;

  const CityModel({
    required this.id,
    required this.name,
    required this.countryId,
    required this.isActive,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        id: json['id'] as String,
        name: json['name'] as String,
        countryId: json['countryId'] as String,
        isActive: json['isActive'] as bool? ?? true,
      );
}

class LandmarkModel {
  final String id;
  final String name;
  final String cityId;

  const LandmarkModel({
    required this.id,
    required this.name,
    required this.cityId,
  });

  factory LandmarkModel.fromJson(Map<String, dynamic> json) => LandmarkModel(
        id: json['id'] as String,
        name: json['name'] as String,
        cityId: json['cityId'] as String,
      );
}

class AuthTokensModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) =>
      AuthTokensModel(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: json['expiresIn'] as int? ?? 900,
      );
}

class UserProfileModel {
  final String? avatar;
  final String? address;
  final CityEntity? city;
  final UserPreferences preferences;

  const UserProfileModel({
    this.avatar,
    this.address,
    this.city,
    this.preferences = const UserPreferences(),
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final cityJson = json['city'] as Map?;
    final preferencesJson = json['preferences'] as Map?;
    return UserProfileModel(
      avatar: json['avatar'] as String?,
      address: json['address'] as String?,
      city: cityJson != null
          ? CityEntity(
              id: cityJson['id'] as String,
              name: cityJson['name'] as String,
              countryCode: (cityJson['country'] as Map)['code'] as String,
              countryName: ((cityJson['country'] as Map)['translations']
                  as Map)['fr'] as String,
            )
          : null,
      preferences: preferencesJson != null
          ? UserPreferences(
              dietaryRestrictions: List<String>.from(
                  preferencesJson['dietaryRestrictions'] ?? []),
              favoriteCategories: List<String>.from(
                  preferencesJson['favoriteCategories'] ?? []),
              notifications: Map<String, bool>.from(
                  preferencesJson['notifications'] ?? {}),
            )
          : const UserPreferences(),
    );
  }
}

class ApiUserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final bool isVerified;
  final bool isActive;
  final bool isProfileComplete;
  final UserProfileModel profile;

  const ApiUserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.isVerified,
    required this.isActive,
    this.isProfileComplete = true,
    required this.profile,
  });

  factory ApiUserModel.fromJson(Map<String, dynamic> json) => ApiUserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String? ?? 'USER',
        isVerified: json['isVerified'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
        isProfileComplete: json['isProfileComplete'] as bool? ?? true,
        profile: UserProfileModel.fromJson(json['profile'] ?? {}),
      );

  String? get avatarUrl => profile.avatar;

  String get firstName => name.split(' ').first;
  String get lastName => name.split(' ').length > 1 ? name.split(' ').last : '';
}
