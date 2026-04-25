import 'package:intl/intl.dart';

const _months = [
  'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
  'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
];

String formatPrice(double amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  return '${formatter.format(amount.toInt())} FCFA';
}

String formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Bonjour';
  if (hour >= 12 && hour < 18) return 'Bon après-midi';
  return 'Bonsoir';
}
