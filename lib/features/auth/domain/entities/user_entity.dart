enum UserRole { user, provider, admin }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final String? city;
  final String? country;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.city,
    this.country,
  });

  String get fullName => name;
  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  UserEntity copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? city,
    String? country,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }
}
