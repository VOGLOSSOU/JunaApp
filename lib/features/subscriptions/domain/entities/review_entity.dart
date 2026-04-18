class ReviewEntity {
  final String id;
  final double rating;
  final String comment;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return 'Il y a $months mois';
    }
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? "s" : ""}';
    }
    if (diff.inDays >= 1) return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? "s" : ""}';
    if (diff.inHours >= 1) return 'Il y a ${diff.inHours}h';
    return 'À l\'instant';
  }
}
