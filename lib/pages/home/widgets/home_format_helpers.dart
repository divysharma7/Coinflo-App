import 'package:intl/intl.dart';

String formatHomeNumber(double value) {
  if (value >= 100000) {
    return NumberFormat('#,##,###', 'en_IN').format(value.toInt());
  }
  return NumberFormat('#,###').format(value.toInt());
}
