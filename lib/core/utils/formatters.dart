import 'package:intl/intl.dart';

const _months = [
  'Jan',
  'Fév',
  'Mar',
  'Avr',
  'Mai',
  'Juin',
  'Juil',
  'Aoû',
  'Sep',
  'Oct',
  'Nov',
  'Déc',
];

const _fullMonths = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

String formatMonthYear(DateTime date) {
  return '${_fullMonths[date.month - 1]} ${date.year}';
}

String formatPrice(double amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  return '${formatter.format(amount.toInt())} FCFA';
}

String formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// Normalise un numéro béninois brut (saisi librement par le prestataire,
/// sans format garanti côté API) vers le format E.164 (+229XXXXXXXXXX).
///
/// Depuis la migration ARCEP de 2021, les numéros béninois sont sur 10
/// chiffres et le "0" en tête fait partie du vrai numéro — ce n'est PAS
/// un préfixe national à retirer (contrairement à d'autres pays). On ne
/// touche donc jamais ce chiffre, on préfixe juste l'indicatif pays.
///
/// Retourne null si le numéro ne ressemble pas à un numéro béninois valide,
/// pour ne jamais générer un lien tel:/wa.me/ cassé à partir d'une donnée
/// mal saisie.
String? toBeninE164(String? raw) {
  if (raw == null) return null;
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 13 && digits.startsWith('229')) {
    digits = digits.substring(3);
  }
  if (digits.length != 10) return null;
  return '+229$digits';
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Bonjour';
  if (hour >= 12 && hour < 18) return 'Bon après-midi';
  return 'Bonsoir';
}
