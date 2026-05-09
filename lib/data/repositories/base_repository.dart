import 'package:finance_buddy_app/data/repositories/family_repository.dart';
import 'package:finance_buddy_app/data/repositories/friend_split_repository.dart';
import 'package:finance_buddy_app/data/repositories/metrics_repository.dart';
import 'package:finance_buddy_app/data/repositories/notification_repository.dart';
import 'package:finance_buddy_app/data/repositories/reflection_repository.dart';
import 'package:finance_buddy_app/data/repositories/subscription_repository.dart';
import 'package:finance_buddy_app/data/repositories/transaction_repository.dart';

abstract class BaseRepository
    implements
        TransactionRepository,
        FamilyRepository,
        ReflectionRepository,
        MetricsRepository,
        NotificationRepository,
        FriendSplitRepository,
        SubscriptionRepository {}
