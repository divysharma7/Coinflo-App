class AccountLogoResolver {
  static const Map<String, String> _brandMap = {
    // Banks
    'hdfc': 'assets/logos/hdfc.png',
    'icici': 'assets/logos/icici.png',
    'sbi': 'assets/logos/sbi.png',
    'axis': 'assets/logos/axis.png',
    'kotak': 'assets/logos/kotak.png',
    'yes bank': 'assets/logos/yes_bank.png',
    'pnb': 'assets/logos/pnb.png',
    'bob': 'assets/logos/bob.png',
    'indusind': 'assets/logos/indusind.png',
    'idfc': 'assets/logos/idfc.png',

    // UPI / Wallet apps
    'paytm': 'assets/logos/paytm.png',
    'phonepe': 'assets/logos/phonepe.png',
    'phone pe': 'assets/logos/phonepe.png',
    'gpay': 'assets/logos/gpay.png',
    'google pay': 'assets/logos/gpay.png',
    'amazon pay': 'assets/logos/amazon_pay.png',
    'cred': 'assets/logos/cred.png',
    'slice': 'assets/logos/slice.png',
    'jupiter': 'assets/logos/jupiter.png',
    'fi': 'assets/logos/fi.png',
    'navi': 'assets/logos/navi.png',
  };

  /// Returns asset path or null if no brand match.
  static String? resolve(String accountName) {
    final normalized = accountName.trim().toLowerCase();
    if (_brandMap.containsKey(normalized)) return _brandMap[normalized];
    for (final entry in _brandMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return null;
  }
}
