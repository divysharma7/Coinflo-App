enum AccountType { cash, upi }

class AccountModel {
  final String id;
  final String name;
  final AccountType type;
  final double openingBalance;
  final bool isDeletable;
  final bool isSystemAccount;

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0.0,
    this.isDeletable = true,
    this.isSystemAccount = false,
  });

  static AccountModel get cashAccount => const AccountModel(
        id: 'system_cash',
        name: 'Cash',
        type: AccountType.cash,
        openingBalance: 0.0,
        isDeletable: false,
        isSystemAccount: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'openingBalance': openingBalance,
        'isDeletable': isDeletable,
        'isSystemAccount': isSystemAccount,
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccountType.values.byName(json['type'] as String),
        openingBalance: (json['openingBalance'] as num).toDouble(),
        isDeletable: json['isDeletable'] as bool,
        isSystemAccount: json['isSystemAccount'] as bool,
      );
}
