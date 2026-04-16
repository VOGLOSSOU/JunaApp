enum UserRole { user, provider, admin }

class CityEntity {
  final String id;
  final String name;
  final String countryCode;
  final String countryName;

  const CityEntity({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.countryName,
  });

  String get display => '$name, $countryName';
}

class UserPreferences {
  final List<String> dietaryRestrictions;
  final List<String> favoriteCategories;
  final Map<String, bool> notifications;

  const UserPreferences({
    this.dietaryRestrictions = const [],
    this.favoriteCategories = const [],
    this.notifications = const {'email': true, 'push': true, 'sms': false},
  });

  UserPreferences copyWith({
    List<String>? dietaryRestrictions,
    List<String>? favoriteCategories,
    Map<String, bool>? notifications,
  }) {
    return UserPreferences(
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      notifications: notifications ?? this.notifications,
    );
  }
}

class UserProfile {
  final String? avatar;
  final String? address;
  final CityEntity? city;
  final UserPreferences preferences;

  const UserProfile({
    this.avatar,
    this.address,
    this.city,
    this.preferences = const UserPreferences(),
  });

  UserProfile copyWith({
    String? avatar,
    String? address,
    CityEntity? city,
    UserPreferences? preferences,
  }) {
    return UserProfile(
      avatar: avatar ?? this.avatar,
      address: address ?? this.address,
      city: city ?? this.city,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final UserProfile profile;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.isVerified = false,
    this.isActive = true,
    this.profile = const UserProfile(),
  });

  String get fullName => name;
  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  UserEntity copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    UserProfile? profile,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      isVerified: isVerified,
      isActive: isActive,
      profile: profile ?? this.profile,
    );
  }
}
