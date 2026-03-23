import 'package:intl/intl.dart';

String formatPrice(double amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  return '${formatter.format(amount.toInt())} FCFA';
}

String formatDate(DateTime date) {
  return DateFormat('d MMM yyyy', 'fr_FR').format(date);
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Bonjour';
  if (hour >= 12 && hour < 18) return 'Bon après-midi';
  return 'Bonsoir';
}
