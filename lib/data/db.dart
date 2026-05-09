import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

// ─── Tables ───────────────────────────────────────────

class SpendlerTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get category => text()(); // enum string: rent/transport/food/family/social/other
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get happenedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get source => text().withDefault(const Constant('manual'))(); // sms_auto / manual
  TextColumn get status => text().withDefault(const Constant('confirmed'))(); // unconfirmed / confirmed
  BoolColumn get isSplit => boolean().withDefault(const Constant(false))();
  IntColumn get splitCount => integer().nullable()();
  RealColumn get splitMyShare => real().nullable()();
  RealColumn get splitPendingAmount => real().nullable()();
  BoolColumn get splitSettled => boolean().withDefault(const Constant(false))();
  TextColumn get ledgerType => text().withDefault(const Constant('personal'))(); // personal / family
  TextColumn get syncId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class FamilyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // inflow / investment
  RealColumn get amount => real()();
  TextColumn get fromPerson => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get happenedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get investmentType => text().nullable()(); // MF / stocks / FD / other
  TextColumn get syncId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WeeklyReflections extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get weekStartDate => dateTime()();
  RealColumn get totalSpent => real()();
  TextColumn get topCategory => text()();
  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get llmReportGeneratedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AppMetrics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get metricType => text()(); // app_open / retrospection / llm_report / week_confirmed
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get metadata => text().nullable()();
}

class AppNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'transaction', 'checkin', 'digest'
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get sentAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

class FriendContacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 30)();
  TextColumn get note => text().nullable()();
  TextColumn get avatarColour => text()(); // hex colour string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class FriendSplits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer()();
  IntColumn get friendContactId => integer()();
  RealColumn get amount => real()();
  TextColumn get direction => text()(); // 'they_owe_me' | 'i_owe_them'
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  BoolColumn get isWrittenOff => boolean().withDefault(const Constant(false))();
  DateTimeColumn get settledAt => dateTime().nullable()();
  TextColumn get settlementMethod => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get billingCycle => text()(); // weekly / monthly / yearly
  DateTimeColumn get nextBillingDate => dateTime()();
  TextColumn get category => text()(); // reuses TransactionCategory values
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database ─────────────────────────────────────────

@DriftDatabase(tables: [
  SpendlerTransactions,
  FamilyEntries,
  WeeklyReflections,
  AppMetrics,
  AppNotifications,
  FriendContacts,
  FriendSplits,
  Subscriptions,
])
class SpendlerDatabase extends _$SpendlerDatabase {
  SpendlerDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(appNotifications);
          }
          if (from < 3) {
            await m.createTable(friendContacts);
            await m.createTable(friendSplits);
          }
          if (from < 4) {
            await m.createTable(subscriptions);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'spendler.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
