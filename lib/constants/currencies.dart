class CurrencyModel {
  final String code;
  final String name;
  final String symbol;

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

const List<CurrencyModel> kSupportedCurrencies = [
  CurrencyModel(code: 'USD', name: 'US Dollar', symbol: '\$'),
  CurrencyModel(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyModel(code: 'GBP', name: 'British Pound', symbol: '£'),
  CurrencyModel(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
  CurrencyModel(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
  CurrencyModel(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
  CurrencyModel(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$'),
  CurrencyModel(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
  CurrencyModel(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr'),
  CurrencyModel(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
  CurrencyModel(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
  CurrencyModel(code: 'MXN', name: 'Mexican Peso', symbol: '\$'),
  CurrencyModel(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$'),
  CurrencyModel(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
  CurrencyModel(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
];
