import 'package:intl/intl.dart';

import 'package:finance_buddy_app/utils/currency_utils.dart';

String formatHomeNumber(double value, {String currencyCode = 'inr'}) {
  if (currencyCode.toLowerCase() == 'inr') {
    if (value >= 100000) {
      return NumberFormat('#,##,###', 'en_IN').format(value.toInt());
    }
    return NumberFormat('#,###').format(value.toInt());
  }
  final locale = localeFor(currencyCode);
  return NumberFormat.decimalPattern(locale).format(value.toInt());
}
