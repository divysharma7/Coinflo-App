import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/services/sms/sms_processor.dart';
import 'package:flutter/foundation.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;
  final SmsProcessor _processor;

  SmsService(BaseRepository repository) : _processor = SmsProcessor(repository);

  /// Request SMS permissions and start listening.
  Future<bool> initialize() async {
    final granted = await _telephony.requestPhoneAndSmsPermissions ?? false;
    if (!granted) return false;

    _telephony.listenIncomingSms(
      onNewMessage: _onSmsReceived,
      listenInBackground: false,
    );

    return true;
  }

  /// Backfill recent SBI messages from inbox (last 7 days).
  Future<int> backfillRecent() async {
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.ADDRESS).like('%SBI%'),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    var count = 0;

    for (final msg in messages) {
      if (msg.date != null && DateTime.fromMillisecondsSinceEpoch(msg.date!).isBefore(cutoff)) {
        break;
      }
      if (msg.body != null) {
        final created = await _processor.process(msg.body!);
        if (created) count++;
      }
    }

    return count;
  }

  void _onSmsReceived(SmsMessage message) {
    final address = message.address?.toUpperCase() ?? '';
    if (!address.contains('SBI')) return;

    if (message.body != null) {
      unawaited(_processor.process(message.body!).catchError((Object e) {
        debugPrint('SMS processing error: $e');
        return false;
      }));
    }
  }
}
