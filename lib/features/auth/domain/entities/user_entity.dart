enum UserRole { user, provider, admin }

class UserEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final String? city;
  final String? country;
  final String? landmark;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.city,
    this.country,
    this.landmark,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  UserEntity copyWith({
    String? city,
    String? country,
    String? landmark,
  }) {
    return UserEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      role: role,
      city: city ?? this.city,
      country: country ?? this.country,
      landmark: landmark ?? this.landmark,
    );
  }
}
