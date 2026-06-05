/// Maps a currency code to its preferred locale for number formatting.
String localeFor(String code) {
  switch (code.toLowerCase()) {
    case 'inr':
      return 'en_IN';
    case 'usd':
      return 'en_US';
    case 'eur':
      return 'en_IE';
    case 'gbp':
      return 'en_GB';
    case 'jpy':
      return 'ja_JP';
    default:
      return 'en_US';
  }
}

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
