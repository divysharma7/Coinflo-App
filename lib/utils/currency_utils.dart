/// Shared currency symbol resolver used across the app.
String currencySymbol(String code) {
  switch (code.toLowerCase()) {
    case 'inr':
      return '\u20B9';
    case 'usd':
      return '\$';
    case 'eur':
      return '\u20AC';
    case 'gbp':
      return '\u00A3';
    case 'jpy':
      return '\u00A5';
    default:
      return '\u20B9';
  }
}
